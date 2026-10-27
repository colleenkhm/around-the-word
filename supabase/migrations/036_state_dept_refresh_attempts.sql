-- Whereabout: per-country cooldown for refresh-country-state-dept.
-- Records every attempt, success or not, so a country the State Dept
-- has no data for can't trigger a fetch on every page view. Server-only
-- (no anon policy) — display freshness stays last_verified_at.
create table if not exists state_dept_refresh_attempts (
  country_id    text primary key references countries(id) on delete cascade,
  attempted_at  timestamptz not null default now()
);

alter table state_dept_refresh_attempts enable row level security;
