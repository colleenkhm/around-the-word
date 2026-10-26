-- Whereabout: per-row verification state for country_languages.percent_speakers.
-- Surfaced 2026-10-25 by Greece: English showed 50.98% (a 2012 Eurobarometer
-- figure relayed by Wikipedia) while Greek had no figure at all. From here a
-- percentage is only shown once it's checked against its primary source, and
-- the research itself is tracked in the collection spreadsheet's Languages tab
-- (imported by import-curated-data.mjs --only=languages).
--
--   verified       checked against the primary source (census, national stats
--                  office, Eurobarometer, national survey); measures all
--                  speakers (first + additional language)
--   unverified     a figure exists but only via a secondary source (e.g. the
--                  Wikipedia list) — not shown in the app
--   no_source      researched; no qualifying figure exists
--   needs_research not researched yet

alter table country_languages
  add column if not exists percent_status text not null default 'needs_research'
    check (percent_status in ('verified', 'unverified', 'no_source', 'needs_research')),
  add column if not exists percent_year integer,
  add column if not exists percent_source_url text;

comment on column country_languages.percent_status is
  'Verification state of percent_speakers. Only verified figures are shown in the app. See migration 030.';
comment on column country_languages.percent_year is
  'Year the percent_speakers figure was measured (survey/census year), not the year it was entered.';
comment on column country_languages.percent_source_url is
  'Link to the primary source percent_speakers was verified against.';

-- Everything imported from the Wikipedia list (027) is secondary.
update country_languages
set percent_status = 'unverified'
where percent_speakers is not null
  and percent_speakers_source like 'Wikipedia,%';

-- 029: checked directly against the primary documents.
update country_languages cl
set percent_status = 'verified',
    percent_year = v.year,
    percent_source_url = v.url
from (values
  ('GE', 2024, 'https://www.caucasusbarometer.org/en/cb2024ge/KNOWENG/'),
  ('TK', 2016, 'https://www.tokelau.org.nz/site/tokelau/files/TokelauNSO/2016Census/profile-tokelau-2016-census-final-to-print28jun17jj.pdf')
) as v(country_id, year, url)
where cl.country_id = v.country_id
  and cl.language_id = (select id from languages where iso_code = 'en');

-- 026 (Costa Rica, hand-researched): Bribri and Cabécar trace to the 2011
-- census. Spanish's 99% was recorded there as a rounded estimate, not a
-- cited statistic, so it's unverified under the primary-source rule.
update country_languages
set percent_status = 'verified', percent_year = 2011
where country_id = 'CR'
  and language_id in (select id from languages where iso_code in ('bzd', 'cjp'));

update country_languages
set percent_status = 'unverified'
where country_id = 'CR'
  and language_id = (select id from languages where iso_code = 'es');

-- Researched English gaps with no qualifying figure
-- (tools/commodity_importer/english_speakers_researched.json, "percent": null).
update country_languages
set percent_status = 'no_source'
where language_id = (select id from languages where iso_code = 'en')
  and percent_speakers is null
  and country_id in ('CW', 'SX', 'JE', 'RS', 'AL', 'BA', 'MK', 'FO', 'TV', 'NU', 'FK', 'KG',
                     'BY', 'TJ', 'MD', 'TL', 'MN', 'MV', 'TC', 'BI', 'KR', 'SH', 'MC');
