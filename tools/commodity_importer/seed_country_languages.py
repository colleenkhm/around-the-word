"""
Seeds the `languages` and `country_languages` tables directly in the live
Supabase project, from data already sitting in `country_facts.official_languages`
(itself REST Countries data, imported earlier by fetch_country_facts.py).

**Deliberate exception to CLAUDE.md's "language content is hand-curated, API
or not" rule** — confirmed 2026-08-26. `country_languages` was originally
scoped as fully curated (see whereabout-data-architecture.md's "Curated:
language content" section), but the base fact "these languages are spoken
here" is genuinely commodity data, already fetched and sitting unused in
`country_facts`. What stays hand-curated is `usage_note` (regional nuance,
e.g. "Spanish, but Quechua widely spoken in the highlands") — this script
always leaves it null — and `is_primary` for any country where the
official-languages list doesn't reflect real-world primacy; this script sets
`is_primary = true` on every row it inserts since REST Countries gives no
ranking to do better with, so a country with several official languages
gets several `is_primary = true` rows until someone corrects it by hand.

**Writes to Supabase directly**, unlike fetch_country_facts.py / fetch_cities.py
which only emit CSV for the collection spreadsheet — those two predate
Supabase existing; `languages`/`country_languages` are live tables today
with real FKs (`words.language_id`, `phrases.language_id`) already pointing
at hand-entered rows, so round-tripping through a spreadsheet would risk a
human accidentally creating a duplicate language row for one that already
has content. Needs SUPABASE_URL + SUPABASE_SERVICE_ROLE_KEY (see
.env.scripts).

**ISO code mapping**: country_facts.official_languages is keyed by ISO
639-2/3 (three-letter) codes, but the six languages already in the live
`languages` table use ISO 639-1 (two-letter) codes. This script resolves
639-3 -> 639-1 via pycountry so it reuses those existing rows (English,
French, German, Greek, Portuguese, Irish) instead of creating duplicates;
where a language has no 639-1 code (e.g. Fiji Hindi, Mandarin as distinct
from Chinese), the 639-3 code is used as-is.

Re-runnable: both tables are upserted on their real key, so running twice
does not duplicate rows.

Usage:
    export $(cat ../../.env.scripts | xargs)   # or source it
    python seed_country_languages.py --dry-run
    python seed_country_languages.py
"""

import argparse
import os
import sys

import pycountry
import requests


def sb_headers(key):
    return {
        "apikey": key,
        "Authorization": f"Bearer {key}",
        "Content-Type": "application/json",
    }


def resolve_iso_code(code3):
    lang = pycountry.languages.get(alpha_3=code3)
    if lang and getattr(lang, "alpha_2", None):
        return lang.alpha_2
    return code3


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--dry-run", action="store_true", help="print what would change, write nothing")
    args = parser.parse_args()

    url = os.environ.get("SUPABASE_URL")
    key = os.environ.get("SUPABASE_SERVICE_ROLE_KEY")
    if not url or not key:
        print("Need SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY set (see .env.scripts).", file=sys.stderr)
        sys.exit(1)
    headers = sb_headers(key)

    facts = requests.get(
        f"{url}/rest/v1/country_facts",
        headers=headers,
        params={"select": "country_id,official_languages", "limit": 1000},
        timeout=30,
    )
    facts.raise_for_status()
    facts = facts.json()

    existing = requests.get(
        f"{url}/rest/v1/languages",
        headers=headers,
        params={"select": "id,iso_code,name"},
        timeout=30,
    )
    existing.raise_for_status()
    by_iso = {row["iso_code"]: row for row in existing.json()}

    # code3 -> (iso_code, name), collected across every country before any
    # writes, so one language inserted once even if 100 countries speak it.
    to_create = {}
    for row in facts:
        for code3, name in (row["official_languages"] or {}).items():
            iso = resolve_iso_code(code3)
            if iso not in by_iso and iso not in to_create:
                to_create[iso] = name

    print(f"{len(facts)} countries, {len(to_create)} new language rows, "
          f"{len(by_iso)} existing language rows reused where matched.")

    if args.dry_run:
        for iso, name in sorted(to_create.items()):
            print(f"  + languages: {iso} -> {name}")
        # Fake IDs so the country_languages count below reflects reality
        # instead of skipping every language that isn't live yet.
        for iso, name in to_create.items():
            by_iso[iso] = {"id": "DRY-RUN", "iso_code": iso, "name": name}
    elif to_create:
        payload = [{"iso_code": iso, "name": name} for iso, name in to_create.items()]
        resp = requests.post(
            f"{url}/rest/v1/languages",
            headers={**headers, "Prefer": "return=representation,resolution=merge-duplicates"},
            params={"on_conflict": "iso_code"},
            json=payload,
            timeout=30,
        )
        resp.raise_for_status()
        for row in resp.json():
            by_iso[row["iso_code"]] = row

    # country_languages rows, now that by_iso covers every language referenced.
    cl_rows = []
    for row in facts:
        country_id = row["country_id"]
        for code3 in (row["official_languages"] or {}):
            iso = resolve_iso_code(code3)
            lang = by_iso.get(iso)
            if lang is None:
                continue  # dry-run: language wasn't actually created
            cl_rows.append({
                "country_id": country_id,
                "language_id": lang["id"],
                "is_primary": True,
                "usage_note": None,
            })

    print(f"{len(cl_rows)} country_languages rows to upsert.")

    if args.dry_run:
        return

    # Batch to keep request bodies reasonable.
    batch_size = 200
    for i in range(0, len(cl_rows), batch_size):
        batch = cl_rows[i:i + batch_size]
        resp = requests.post(
            f"{url}/rest/v1/country_languages",
            headers={**headers, "Prefer": "resolution=merge-duplicates"},
            params={"on_conflict": "country_id,language_id"},
            json=batch,
            timeout=30,
        )
        resp.raise_for_status()

    print("Done.")


if __name__ == "__main__":
    main()
