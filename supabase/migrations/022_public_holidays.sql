-- Whereabout: public holidays ("what's closed when") — new Tier A
-- commodity field, added 2026-08-26. See whereabout-data-architecture.md's
-- "Reopened 2026-08-26" subsection and CLAUDE.md's External Data Sources
-- note: distinct from country_guides.festivals (named recurring events
-- worth planning a trip around) — this is the practical, checkable
-- "most businesses shut on this date" fact, sourced from Nager.Date.
--
-- Whole table is rebuildable from the importer, same trust model as
-- country_facts/cities — nothing here is hand-edited.

create table public_holidays (
  id                uuid primary key default gen_random_uuid(),
  country_id        text not null references countries(id) on update cascade,
  date              date not null,
  local_name        text not null,
  name              text not null,       -- English
  is_national       boolean not null,    -- false = regional/subdivision-specific (Nager's `counties`)
  holiday_type      text,                -- Nager's `types`: 'Public' | 'Bank' | 'Optional' | 'School' | ...
  source            text not null default 'nager.date',
  last_imported_at  timestamptz not null default now(),
  unique (country_id, date, name)
);

create index public_holidays_country_id_idx on public_holidays (country_id);

alter table public_holidays enable row level security;
-- No policies = default deny for anon/authenticated, same as
-- exchange_rate_cache. Only the importer (via service_role) writes this;
-- a future read policy can be added once the client actually displays it.

comment on table public_holidays is
  'Commodity, Tier A (see CLAUDE.md External Data Sources). Sourced from Nager.Date, rebuildable from the importer. Distinct from country_guides.festivals, which stays hand-curated.';
