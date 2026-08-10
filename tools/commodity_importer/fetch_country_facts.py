"""
Fetches commodity country facts from REST Countries and outputs a CSV
matching the `country_facts` table columns (see around-the-word-data-
architecture.md's "Schema" section) — paste the rows straight into the
Country Facts sheet of the collection spreadsheet.

**Uses the v5 API, which requires a free API key** — the data architecture
doc originally documented v3.1 as no-key; v3.1 was deprecated (confirmed
2026-08-09, see this tool's README) and v5's demo key (`rc_live_demo`)
only ever echoes one fixed sample record regardless of what you ask for,
so a real key is required to get actual per-country data. Sign up at
https://restcountries.com/sign-up (free tier covers this easily) and pass
the key with --api-key or the REST_COUNTRIES_API_KEY environment variable.

This is a content-authoring tool, not part of the Flutter app or a real
importer yet — there's no Supabase to write into. Once Supabase exists,
this same fetch/normalize logic is what becomes the Edge Function described
in the data architecture doc's "Automated refresh" design; nothing here
needs rewriting then, just a different output target.

Entire table is meant to be rebuildable from a script (per the doc) — if a
value here is wrong, that's an importer bug, not something to hand-correct
in the sheet.

Usage:
    export REST_COUNTRIES_API_KEY=your_key
    python fetch_country_facts.py CR PT GR > country_facts.csv
"""

import argparse
import csv
import os
import sys
import time
from datetime import datetime, timezone

import requests

API_URL = "https://api.restcountries.com/countries/v5/codes.alpha_2"

FIELDS = [
    "country_code",
    "capital",
    "population",
    "currency_code",
    "currency_name",
    "calling_code",
    "official_languages",
    "latitude",
    "longitude",
    "region",
    "subregion",
    "flag_svg_url",
    "native_name",  # bonus, not a country_facts column — see doc's note on
                     # what the country-page header needs; drop if unwanted
    "source",
    "last_imported_at",
]


def fetch_one(iso2, api_key):
    resp = requests.get(
        f"{API_URL}/{iso2}",
        headers={"Authorization": f"Bearer {api_key}"},
        timeout=15,
    )
    resp.raise_for_status()
    objects = resp.json()["data"]["objects"]
    if not objects:
        raise RuntimeError("no match")
    return objects[0]


def normalize(iso2, data, fetched_at):
    currencies = data.get("currencies") or []
    currency = currencies[0] if currencies else {}

    calling_codes = data.get("calling_codes") or []
    calling_code = "+" + calling_codes[0] if calling_codes else None

    languages = data.get("languages") or []
    coords = data.get("coordinates") or {}

    natives = (data.get("names") or {}).get("native") or {}
    native_name = next(iter(natives.values()), {}).get("common") if natives else None

    capitals = data.get("capitals") or []

    return {
        "country_code": iso2,
        "capital": capitals[0]["name"] if capitals else None,
        "population": data.get("population"),
        "currency_code": currency.get("code"),
        "currency_name": currency.get("name"),
        "calling_code": calling_code,
        "official_languages": "; ".join(lang.get("name", "") for lang in languages),
        "latitude": coords.get("lat"),
        "longitude": coords.get("lng"),
        "region": data.get("region"),
        "subregion": data.get("subregion"),
        "flag_svg_url": (data.get("flag") or {}).get("url_svg"),
        "native_name": native_name,
        "source": "restcountries",
        "last_imported_at": fetched_at,
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("iso_codes", nargs="+", help="ISO 3166-1 alpha-2 codes, e.g. CR PT GR")
    parser.add_argument("--api-key", default=os.environ.get("REST_COUNTRIES_API_KEY"))
    args = parser.parse_args()

    if not args.api_key:
        print(
            "No REST Countries API key. Pass --api-key or set\n"
            "REST_COUNTRIES_API_KEY (free signup: https://restcountries.com/sign-up)",
            file=sys.stderr,
        )
        sys.exit(1)

    fetched_at = datetime.now(timezone.utc).isoformat(timespec="seconds")

    writer = csv.DictWriter(sys.stdout, fieldnames=FIELDS)
    writer.writeheader()

    for i, iso2 in enumerate(args.iso_codes):
        iso2 = iso2.upper()
        try:
            data = fetch_one(iso2, args.api_key)
        except (requests.HTTPError, RuntimeError) as e:
            print(f"skipping {iso2}: {e}", file=sys.stderr)
            continue
        writer.writerow(normalize(iso2, data, fetched_at))
        if i < len(args.iso_codes) - 1:
            time.sleep(0.2)  # polite pacing, not required by the API


if __name__ == "__main__":
    main()
