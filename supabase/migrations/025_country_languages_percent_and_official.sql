-- Whereabout: percentage-of-speakers + official/unofficial status for
-- country_languages. Added 2026-09-20 per direct request.
--
-- NUMBERING WARNING: local `main` tops out at 022, but per HANDOFF.md's
-- 2026-08-31 "Holidays" entry, the shared remote DB already has 023
-- (023_content_candidates.sql, from the unmerged tier-b-content-candidates
-- branch) and 024 (024_public_holidays_read_policy.sql) applied — neither
-- file exists in this branch's history. Numbered 025 to skip both known
-- collisions. This session had no network access to run
-- `supabase migration list` and confirm nothing past 024 is also already
-- live — run that first before `db push`, and renumber both this file and
-- 026_costa_rica_language_percentages.sql together if it shows otherwise.
--
-- Why: the Language section should show a percentage bar per language,
-- include unofficial but commonly-spoken languages (not just REST
-- Countries' official-only import), and always surface English with
-- whatever data exists.
--
-- Tier C, same as every other usage_note field (see CLAUDE.md's External
-- Data Sources note and the data architecture doc's "Curated: language
-- content" section) — no commodity source gives per-language speaker
-- percentages or flags non-official-but-widely-spoken languages, so both
-- new columns are hand-researched/hand-entered, never importer-written.
--
-- `is_official` is a new distinction, not a rename of `is_primary`:
-- `is_primary` has always been about ranking among a country's *official*
-- languages (the importer sets it true on every row it inserts, since
-- REST Countries only ever returns official languages). `is_official` is
-- the official-vs-not axis that a purely-official import never needed
-- until unofficial rows existed at all.

alter table country_languages
  add column is_official boolean not null default true,
  add column percent_speakers numeric;

comment on column country_languages.is_official is
  'true = official language of the country; false = commonly spoken but not official (a widely-taught second language, a regional indigenous or creole language). Hand-curated — see CLAUDE.md External Data Sources, Tier C.';
comment on column country_languages.percent_speakers is
  'Approximate % of the population who speak this language, where a reasonably sourced figure exists. Null, not 0, when no sourced figure exists — never guessed. Hand-curated, Tier C.';

-- Every row seed_country_languages.py has ever inserted came from REST
-- Countries' official-languages list, so `is_official = true` (the column
-- default) is already correct for 100% of existing rows — no backfill.
