-- Whereabout: Tier B staging table, added 2026-08-26 on the
-- tier-b-content-candidates branch. See whereabout-data-architecture.md's
-- "Reopened 2026-08-26" subsection for the full reasoning.
--
-- Holds fetched-but-unpublished drafts from Wikivoyage/Wiktionary/Wikidata
-- for points_of_interest, phrases, words, historical_events, and
-- festivals. Nothing here is ever read by the app — it's a review queue,
-- same relationship to the real tables that research_submissions has to
-- published content (feeds the writing process, never served directly).
--
-- One table with a `candidate_type` discriminator rather than five
-- near-duplicate staging tables — same pattern already used twice in this
-- schema (practical_norms' *_norm types, points_of_interest's poi_type).
--
-- Promotion is manual (decided 2026-08-26): a person reviews a pending
-- row, and if it's worth using, copies the reviewed/rewritten payload into
-- the real table themselves via Supabase's table editor — same motion as
-- ordinary curation today. No script reads status='approved' and inserts
-- automatically. `status` here just means "reviewed, decision made," not
-- "published."
--
-- Licensing note (carried from the architecture doc): 'approved' must mean
-- "I rewrote the prose fields in my own words," not "looks fine as
-- fetched" — Wikivoyage/Wiktionary are CC BY-SA, and publishing their text
-- verbatim would carry share-alike obligations into an otherwise
-- proprietary product. Applies to prose fields only (a POI's description,
-- a phrase's usage_note) — structured facts (coordinates, a literal
-- translation) aren't copyrightable and don't need rewriting, just
-- verification.

create table content_candidates (
  id              uuid primary key default gen_random_uuid(),
  country_id      text not null references countries(id) on update cascade,
  candidate_type  text not null check (candidate_type in ('poi', 'phrase', 'word', 'historical_event', 'festival')),
  source          text not null check (source in ('wikivoyage', 'wiktionary', 'wikidata')),
  source_url      text,             -- link back to the source page/entity for review
  payload         jsonb not null,   -- shape mirrors the target table's own columns for candidate_type
  status          text not null default 'pending' check (status in ('pending', 'approved', 'rejected')),
  reviewed_at     timestamptz,
  notes           text,             -- reviewer's own note, e.g. why rejected, or what still needs checking
  fetched_at      timestamptz not null default now()
);

create index content_candidates_country_id_idx on content_candidates (country_id);
create index content_candidates_status_idx on content_candidates (status);
create index content_candidates_type_idx on content_candidates (candidate_type);

alter table content_candidates enable row level security;
-- No policies = default deny for anon/authenticated. Only the fetchers
-- (service_role) write this, and it's reviewed directly in the Supabase
-- table editor — no app-facing read path, same as research_submissions.

comment on table content_candidates is
  'Tier B staging queue (see CLAUDE.md External Data Sources, tier B). Never read by the app. Promotion to the real table is manual — see this migration''s header for the licensing reason approved must mean rewritten, not just fetched.';
