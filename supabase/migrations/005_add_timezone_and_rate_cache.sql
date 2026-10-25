-- Whereabout: timezone (commodity) + exchange rate cache (server-side only)

-- Timezone: commodity, same tier as capital/currency/hemisphere. IANA name
-- (e.g. "Europe/Athens") lets the Flutter client compute correct local
-- time on-device (DST-aware, via the `timezone` package) with no live call.
alter table country_facts
  add column timezone text;

comment on column country_facts.timezone is
  'IANA timezone name, e.g. "Europe/Athens". Commodity — importer-owned like capital/currency, respects the same source-guard as other country_facts columns.';

-- Exchange rate cache: NOT part of CountryBundle, NOT read by the Flutter
-- app directly. Exists purely so the convert-currency Edge Function can
-- avoid hitting ExchangeRate-API's free-tier quota on every single request
-- — rates only actually update once a day on the free tier anyway, so
-- caching for a few hours costs nothing in freshness.
create table exchange_rate_cache (
  currency_code   text primary key,
  rate_from_usd   numeric not null,
  fetched_at      timestamptz not null default now()
);

alter table exchange_rate_cache enable row level security;
-- No policies = default deny for anon/authenticated. Only the Edge
-- Function (via service_role) reads/writes this table.