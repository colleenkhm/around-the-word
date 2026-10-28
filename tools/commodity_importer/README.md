# Commodity Importer

Content-authoring tools, not part of the Flutter app. Fetches the "free
40%" of country data — the fields the data architecture doc classifies as
**commodity** rather than curated (see that doc's "External Data Sources"
section, or `CLAUDE.md`'s condensed version) — and outputs CSV shaped to
paste straight into the collection spreadsheet.

**Covers GeoNames (cities) and languages.** Country facts come from
`import-commodity-data.mjs` at the repo root (mledoze/countries + World
Bank). The old REST Countries script (`fetch_country_facts.py`) was
removed 2026-10-27: REST Countries' 2026-10-13 terms ban storing API
data beyond 3 days, which is all that script did. See HANDOFF.md.

**`fetch_cities.py` writes CSV to stdout, not a database** — it predates
Supabase and still feeds the collection spreadsheet.

**`seed_country_languages.py` is the exception: it writes to the live
Supabase project directly**, since `languages`/`country_languages` already
exist there today with real FKs (`words.language_id`, `phrases.language_id`)
pointing at hand-entered rows — round-tripping through the spreadsheet
would risk a human creating a duplicate language row for one that already
has content. See its docstring for the full rationale (also noted in
CLAUDE.md's External Data Sources section and the data architecture doc's
"Curated: language content" section).

## Setup (one-time)

```bash
cd tools/commodity_importer
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

GeoNames also needs a free username: register at
[geonames.org/login](https://www.geonames.org/login), then either
`export GEONAMES_USERNAME=your_username` or pass `--username` each run.

**Gotcha (confirmed 2026-08-10):** a new GeoNames account isn't enabled for
API access by default, even after email verification. If you get a "user
does not exist" error with a username you know is right, log in and visit
[geonames.org/enablefreewebservice](https://www.geonames.org/enablefreewebservice)
— it's a separate step from account creation, and easy to miss since the
account page foregrounds "Premium Web Services" (a paid tier, not this)
over the free one.

## Usage

```bash
source .venv/bin/activate

# Cities — top N by population per country. is_major is set on every row;
# is_featured is always left blank (see script docstring — that column is
# an editorial call, never auto-filled).
python fetch_cities.py CR PT GR --top 8 > cities.csv

# Languages — writes directly to Supabase (needs SUPABASE_URL +
# SUPABASE_SERVICE_ROLE_KEY, see .env.scripts), covers every country in
# country_facts in one run, re-runnable without duplicating rows.
python seed_country_languages.py --dry-run   # preview first
python seed_country_languages.py
```

`fetch_cities.py` accepts as many ISO codes as you want in one run — pass whatever
countries you're actively collecting for. A country that 404s (bad code,
GeoNames rate limit, etc.) is skipped with a message on stderr rather than
aborting the whole batch.

**Always spot-check before pasting into the sheet.** This is a first
pass, not a guarantee — GeoNames' population figures lag real-world
numbers by however old its underlying dataset is.

## Output columns

`fetch_cities.py` → `cities` table columns exactly.

See whereabout-data-architecture.md (docs/whereabout-data-architecture.md from repo root)'s "Schema" section for what each
column means.
