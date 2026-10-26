-- Whereabout: Köppen climate zones per country. V2 — schema only for now.
-- Commodity — importer-owned like the rest of country_facts.
alter table country_facts
  add column if not exists climates jsonb default '[]'::jsonb not null;

comment on column country_facts.climates is
  'Köppen zones, e.g. [{"koppen": "Am", "label": "Tropical monsoon climate", "regions": "San José"}]. V2, no importer yet.';
