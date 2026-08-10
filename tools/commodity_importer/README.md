# Commodity Importer

Content-authoring tools, not part of the Flutter app. Fetches the "free
40%" of country data — the fields the data architecture doc classifies as
**commodity** rather than curated (see that doc's "External Data Sources"
section, or `CLAUDE.md`'s condensed version) — and outputs CSV shaped to
paste straight into the collection spreadsheet.

**Only covers REST Countries (country facts) and GeoNames (cities) for
now.** The State Dept Consular Affairs API (advisories/visas) is left for
later — the doc designs that one around a weekly live cron against
Postgres, not a one-time spreadsheet fill, so it makes more sense once
Supabase actually exists.

**No Supabase involved yet.** These write CSV to stdout, not a database.
Once Supabase stands up, this fetch/normalize logic is what becomes the
Edge Function the data architecture doc describes — the API calls and
field mapping carry over directly, only the output target changes.

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

# Country facts — one row per ISO 3166-1 alpha-2 code.
python fetch_country_facts.py CR PT GR > country_facts.csv

# Cities — top N by population per country. is_major is set on every row;
# is_featured is always left blank (see script docstring — that column is
# Colleen's editorial call, never auto-filled).
python fetch_cities.py CR PT GR --top 8 > cities.csv
```

Both accept as many ISO codes as you want in one run — pass whatever
countries you're actively collecting for. A country that 404s (bad code,
GeoNames rate limit, etc.) is skipped with a message on stderr rather than
aborting the whole batch.

**Always spot-check before pasting into the sheet.** These are a first
pass, not a guarantee — REST Countries occasionally has gaps (a missing
`idd` block, a currency with no `name`), and GeoNames' population figures
lag real-world numbers by however old its underlying dataset is.

## Output columns

`fetch_country_facts.py` → `country_facts` table columns, plus one bonus
column (`native_name`, from REST Countries' `name.nativeName` — useful for
the country-page header's small-type native name, not itself a
`country_facts` column; drop it if the sheet doesn't want it).

`fetch_cities.py` → `cities` table columns exactly.

See around-the-word-data-architecture.md's "Schema" section for what each
column means.
