# Weather data (avg monthly high/low, °F)

Real climate data from Open-Meteo's historical archive API (ERA5 reanalysis),
not a scrape or AI synthesis — `fetch_weather.py` pulls 5 years (2019-2023)
of daily highs/lows per country (keyed off `country_facts.latitude`/
`longitude` in the live Supabase project) and averages them by month.

- `weather_draft.csv` — country_code, country_name, latitude, longitude,
  monthly_avg_high_low_f (all 12 months, e.g. "Jan 59/46F; Feb 61/48F; ...")
- `weather_flagged.csv` — should be empty; kept for the fetch script's
  resume logic

**Caveat for large/climate-diverse countries** (US, Australia, Brazil,
Russia-scale countries generally): the lat/long in `country_facts` is a
single representative point (often the geographic center or capital), so
the monthly figures represent that one location, not the whole country.
Same caveat as `best_times/README.md` flags for single-city best-time-to-
visit sources — sanity-check these specifically rather than trusting the
number as a national average.

Re-run: `python3 fetch_weather.py` (resumable — skips countries already in
either CSV, so safe to re-run after a partial failure).

Gitignored — working material, not canonical project data.
