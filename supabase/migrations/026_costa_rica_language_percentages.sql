-- Forin: hand-researched Costa Rica language data — the first real values
-- for the percent_speakers/is_official columns added in migration 025.
-- See that file's NUMBERING WARNING before pushing either one.
-- Tier C: hand-curated, not importer output. Every figure below is
-- checked against a real source (noted inline); where no reliable figure
-- could be found, percent_speakers is left null rather than guessed —
-- matches this project's existing "an honest gap beats a confidently
-- wrong number" rule for practical_norms/best_times.why (CLAUDE.md).
--
-- Scoped to Costa Rica only, matching this repo's existing single-country
-- precedent for hand-curated content (the bilingual-content prototype was
-- also Costa Rica-only). Rolling this out to other countries is a
-- separate hand-research pass per country, not implied by this migration
-- — see CLAUDE.md's "don't treat 'let's build X' as content being ready".
--
-- Mekatelyu (Limonese Creole, spoken in Limón province by the Afro-Costa
-- Rican community) is deliberately NOT included here: no verified ISO
-- 639-3 code or population figure was confirmed during this pass. Logged
-- as a known gap in forin-scratch-notes.md rather than guessed at.

-- New language rows REST Countries never surfaces (indigenous languages,
-- not official anywhere, so seed_country_languages.py never creates them).
insert into languages (iso_code, name) values
  ('bzd', 'Bribri'),
  ('cjp', 'Cabécar')
on conflict (iso_code) do nothing;

-- Spanish — official, near-universal first language. Checked 2026-09-20:
-- no single census/survey question gives an exact percentage (Wikipedia's
-- Demographics of Costa Rica: "Nearly all Costa Ricans speak Spanish");
-- 99% is a rounded estimate reflecting that, not a cited statistic. Only
-- percent_speakers is touched on conflict so any hand-set is_primary/
-- usage_note from an earlier run isn't clobbered.
insert into country_languages (country_id, language_id, is_primary, is_official, percent_speakers, usage_note)
values (
  'CR',
  (select id from languages where iso_code = 'es'),
  true,
  true,
  99,
  'Nearly universal first language. ~99% is a rounded estimate — no single census/survey question gives an exact figure.'
)
on conflict (country_id, language_id) do update
set percent_speakers = excluded.percent_speakers;

-- English — unofficial but the most widely spoken foreign language,
-- compulsory in schools. Checked 2026-09-20: EF EPI-adjacent reporting is
-- inconsistent between sources (one summary cited ~10% as a second-
-- language estimate, but the underlying EF EPI page itself gives a
-- proficiency score, not a population percentage, and no other source
-- corroborated the 10% figure) — left null rather than publish a number
-- that couldn't be traced to one real citation.
insert into country_languages (country_id, language_id, is_primary, is_official, percent_speakers, usage_note)
values (
  'CR',
  (select id from languages where iso_code = 'en'),
  false,
  false,
  null,
  'Most widely spoken foreign language; compulsory in schools and common in tourism areas. No reliable population-wide percentage figure found.'
)
on conflict (country_id, language_id) do update
set is_official = excluded.is_official,
    percent_speakers = excluded.percent_speakers,
    usage_note = excluded.usage_note;

-- Bribri — indigenous Chibchan language. Costa Rica's 2011 national
-- census: ~7,000 speakers (54.7% of ~12,785 Bribri people) against that
-- census's ~4,301,712 total population ≈ 0.2%.
insert into country_languages (country_id, language_id, is_primary, is_official, percent_speakers, usage_note)
values (
  'CR',
  (select id from languages where iso_code = 'bzd'),
  false,
  false,
  0.2,
  'Indigenous Chibchan language spoken in the Talamanca region; ~7,000 speakers per Costa Rica''s 2011 census.'
)
on conflict (country_id, language_id) do update
set is_official = excluded.is_official,
    percent_speakers = excluded.percent_speakers,
    usage_note = excluded.usage_note;

-- Cabécar — indigenous Chibchan language, Bribri's sister language.
-- 2011 census: ~11,000 native speakers ≈ 0.3% of the ~4,301,712 total.
insert into country_languages (country_id, language_id, is_primary, is_official, percent_speakers, usage_note)
values (
  'CR',
  (select id from languages where iso_code = 'cjp'),
  false,
  false,
  0.3,
  'Indigenous Chibchan language spoken across several Talamanca-area reservations; ~11,000 native speakers per Costa Rica''s 2011 census.'
)
on conflict (country_id, language_id) do update
set is_official = excluded.is_official,
    percent_speakers = excluded.percent_speakers,
    usage_note = excluded.usage_note;
