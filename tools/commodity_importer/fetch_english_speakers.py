"""
**Superseded 2026-10-25 — don't re-run.** Language percentages are now
researched in the collection spreadsheet's Languages tab and pushed with
`node import-curated-data.mjs --only=languages` (migration 030 added
per-row verification status). Re-running this would overwrite verified
figures with Wikipedia ones. Kept as the record of how 027/029 were built.

Generates a migration giving every country an English `country_languages`
row, with `percent_speakers` filled wherever a sourced figure exists.

Sources, in priority order:
  1. english_speakers_researched.json — hand-researched per-country figures,
     each with its own citation. Wins over everything below.
  2. Wikipedia's "List of countries by English-speaking population", pinned
     to one revision (WIKI_REVID) so a re-run reproduces the same numbers.
     Uses the "Total %" column: first-language plus additional-language
     speakers. Each row's own cited source is carried into
     `percent_speakers_source`.

No figure from either -> `percent_speakers` stays null. Never estimated,
never inherited from a parent country (Réunion is not France).

Writes SQL to stdout rather than to Supabase, so the generated migration
is reviewed as a diff before `supabase db push`. Reads the country list
with the public publishable key (read-only).

Entries in the researched file with "percent": null record a country that
was checked and has no qualifying figure, with the reason, so it isn't
re-researched. Only figures counting all speakers qualify (first plus
additional language); home-language, main-language, literacy, or
one-second-language-per-person counts don't (decided 2026-10-25).

Usage:
    export $(cat ../../.env | xargs)
    python fetch_english_speakers.py > ../../supabase/migrations/027_english_speakers.sql
    # later additions: only the researched rows, as a new migration
    python fetch_english_speakers.py --researched-only > ../../supabase/migrations/0NN_english_speakers_researched.sql
"""

import json
import os
import re
import sys
from pathlib import Path

import requests

WIKI_TITLE = "List_of_countries_by_English-speaking_population"
WIKI_REVID = 1379399265  # 2026-10-09
USER_AGENT = "whereabout-commodity-importer/0.1 (English speakers fetch)"
RESEARCHED = Path(__file__).with_name("english_speakers_researched.json")

# Wikipedia name -> our ISO id, where names differ.
NAME_ALIASES = {"turkey": "TR", "macao": "MO", "u.s. virgin islands": "VI"}

# Listed per island; we have one entity. Combined population-weighted.
CARIBBEAN_NETHERLANDS = ("Bonaire", "Sint Eustatius", "Saba")


def fetch_wikitext():
    res = requests.get(
        "https://en.wikipedia.org/w/api.php",
        params={"action": "parse", "oldid": WIKI_REVID, "prop": "wikitext", "format": "json", "formatversion": 2},
        headers={"User-Agent": USER_AGENT},
        timeout=30,
    )
    res.raise_for_status()
    return res.json()["parse"]["wikitext"]


def clean_note(note):
    note = re.sub(r"<ref[^>]*/>", "", note)
    note = re.sub(r"<ref[^>]*>.*?</ref>", "", note, flags=re.S)
    note = re.sub(r"<!--.*?-->", "", note, flags=re.S)
    note = re.sub(r"\[\[(?:[^]|]*\|)?([^]]*)\]\]", r"\1", note)
    note = re.sub(r"\[https?://\S+ ([^]]*)\]", r"\1", note)
    note = re.sub(r"<[^>]+>|\{\{[^}]*\}\}|''+", "", note)
    return re.sub(r"\s+", " ", note.replace("&nbsp;", " ")).strip()


def cited_sources(cell):
    """Publisher/website/title of each <ref> cite, deduped, in order."""
    names = []
    for cite in re.findall(r"\{\{\s*cite[^}]*\}\}", cell, flags=re.I):
        fields = dict(re.findall(r"\|\s*(publisher|website|work|title)\s*=\s*([^|}]+)", cite))
        name = fields.get("publisher") or fields.get("website") or fields.get("work") or fields.get("title")
        if name:
            name = re.sub(r"\[\[(?:[^]|]*\|)?([^]]*)\]\]", r"\1", name).strip()
            if name not in names:
                names.append(name)
    return names


def parse_number(cell):
    m = re.search(r"[\d,]+", cell)
    return int(m.group(0).replace(",", "")) if m else None


def _pct(cell):
    m = re.search(r"([\d.]+)\s*%", cell.replace("&nbsp;", ""))
    return float(m.group(1)) if m else None


def parse_rows(wikitext):
    start = wikitext.index('{| class="wikitable sortable static-row-numbers')
    table = wikitext[start:wikitext.index("\n|}", start)]
    rows = []
    for raw in table.split("\n|-")[1:]:
        m = re.search(r"\{\{[Ff]lag(?:country)?\|([^}|]+)", raw)
        if not m:
            continue
        cells = []
        for line in raw[m.end():].split("\n"):
            cells += [c.strip() for c in line.lstrip("|").split("||")]
        cells = [c for c in cells if c and not c.startswith("}}")]
        # cells: population, total, total %, L1, L1 %, L2, L2 %, notes
        pct = _pct(cells[2]) if len(cells) > 2 else None
        rows.append({
            "name": m.group(1).strip(),
            "speakers": parse_number(cells[1]) if len(cells) > 1 else None,
            "pct": pct,
            "note": clean_note(cells[7]) if len(cells) > 7 else "",
            "cited": cited_sources(cells[7]) if len(cells) > 7 else [],
            "l2_pct": _pct(cells[6]) if len(cells) > 6 else None,
        })
    return rows


def wiki_source(note, cited=()):
    parts = [f"Wikipedia, List of countries by English-speaking population (rev {WIKI_REVID}), total speakers incl. second-language"]
    if note:
        parts.append(f"Row note: {note[:240]}")
    if cited:
        parts.append(f"Cited: {'; '.join(cited[:3])}")
    return ". ".join(parts)


def fetch_countries():
    url, key = os.environ.get("SUPABASE_URL"), os.environ.get("SUPABASE_PUBLISHABLE_KEY")
    if not url or not key:
        sys.exit("Need SUPABASE_URL and SUPABASE_PUBLISHABLE_KEY set (see .env).")
    res = requests.get(
        f"{url}/rest/v1/countries",
        params={"select": "id,name_common,name_official", "limit": 1000},
        headers={"apikey": key, "Authorization": f"Bearer {key}"},
        timeout=30,
    )
    res.raise_for_status()
    return res.json()


def sql_str(value):
    return "null" if value is None else "'" + str(value).replace("'", "''") + "'"


def main():
    researched_only = "--researched-only" in sys.argv[1:]
    countries = fetch_countries()
    by_name = {}
    for c in countries:
        for k in ("name_common", "name_official"):
            by_name[c[k].lower()] = c["id"]

    figures = {}  # id -> (pct, source)
    unmatched = []
    inconsistent = []
    island_rows = []
    for row in parse_rows(fetch_wikitext()):
        if row["name"] in CARIBBEAN_NETHERLANDS:
            island_rows.append(row)
            continue
        cid = by_name.get(row["name"].lower()) or NAME_ALIASES.get(row["name"].lower())
        if not cid:
            unmatched.append(row["name"])
        elif row["pct"] is not None:
            figures[cid] = (row["pct"], wiki_source(row["note"], row["cited"]))
            if row["l2_pct"] is not None and row["l2_pct"] > row["pct"]:
                inconsistent.append(f"{cid} (total {row['pct']}% < L2 {row['l2_pct']}%)")

    if len(island_rows) == len(CARIBBEAN_NETHERLANDS) and all(r["pct"] and r["speakers"] for r in island_rows):
        speakers = sum(r["speakers"] for r in island_rows)
        population = sum(r["speakers"] / (r["pct"] / 100) for r in island_rows)
        figures["BQ"] = (
            round(speakers / population * 100, 2),
            wiki_source("") + ". Population-weighted from the separate Bonaire, Sint Eustatius and Saba rows.",
        )

    researched = json.loads(RESEARCHED.read_text()) if RESEARCHED.exists() else {}
    for cid, entry in researched.items():
        if entry.get("percent") is not None:
            figures[cid] = (entry["percent"], entry["source"])

    if inconsistent:
        print(f"-- WARNING: rows whose total % is below their L2 %: {', '.join(inconsistent)}", file=sys.stderr)
    if unmatched:
        print(f"-- WARNING: Wikipedia rows with no matching country: {', '.join(unmatched)}", file=sys.stderr)

    if researched_only:
        keep = {cid for cid, e in researched.items() if e.get("percent") is not None}
        countries = [c for c in countries if c["id"] in keep]

    gaps = sorted(c["id"] for c in countries if c["id"] not in figures)
    sourced = len(countries) - len(gaps)
    print(f"-- {sourced} of {len(countries)} countries have a sourced figure; {len(gaps)} gaps", file=sys.stderr)

    out = [
        "-- Whereabout: an English country_languages row for every country, with",
        "-- percent_speakers wherever a sourced figure exists. GENERATED by",
        "-- tools/commodity_importer/fetch_english_speakers.py; edit that script or",
        "-- english_speakers_researched.json and regenerate, don't hand-edit this.",
        f"-- {sourced} of {len(countries)} countries sourced. Null rows are",
        "-- known gaps, logged in whereabout-scratch-notes.md's Known data gaps.",
        "",
        "alter table country_languages add column if not exists percent_speakers_source text;",
        "",
        "comment on column country_languages.percent_speakers is",
        "  'Approximate % of the population who speak this language, where a sourced figure exists. Null, not 0, when none exists, never guessed. English rows: sourced via fetch_english_speakers.py; other languages hand-curated.';",
        "comment on column country_languages.percent_speakers_source is",
        "  'Where percent_speakers came from and what it measures. Null exactly when percent_speakers is null or predates this column.';",
        "",
        "-- New rows are non-official: every official English row already exists",
        "-- (seed_country_languages.py). Existing rows keep is_official/is_primary/",
        "-- usage_note; only the figure and its source are updated.",
        "insert into country_languages (country_id, language_id, is_primary, is_official, percent_speakers, percent_speakers_source)",
        "values",
    ]
    values = []
    for c in sorted(countries, key=lambda c: c["id"]):
        pct, source = figures.get(c["id"], (None, None))
        values.append(
            f"  ({sql_str(c['id'])}, (select id from languages where iso_code = 'en'), false, false, "
            f"{'null' if pct is None else pct}, {sql_str(source)})"
        )
    out.append(",\n".join(values))
    out += [
        "on conflict (country_id, language_id) do update",
        "set percent_speakers = excluded.percent_speakers,",
        "    percent_speakers_source = excluded.percent_speakers_source;",
        "",
    ]
    print("\n".join(out))


if __name__ == "__main__":
    main()
