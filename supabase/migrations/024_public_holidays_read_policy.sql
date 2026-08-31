-- Whereabout: public read access for public_holidays, added 2026-08-31.
-- Migration 022 shipped this table RLS-enabled with no policies at all
-- ("a future read policy can be added once the client actually displays
-- it") — the client now has a Holidays section, so add that policy.
-- Still importer-only for writes (service_role bypasses RLS regardless).

create policy "public_holidays_read" on public_holidays
  for select
  to anon, authenticated
  using (true);
