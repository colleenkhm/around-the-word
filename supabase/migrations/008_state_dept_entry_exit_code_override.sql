-- cadataapi.state.gov's entry_exit_requirements endpoint is keyed closer
-- to FIPS 10-4 than ISO 3166-1 for a specific subset of countries (found
-- 2026-08-21 — see HANDOFF.md). This holds the verified working code for
-- that one endpoint when it differs from iso_code; null means iso_code
-- already works. Scoped to countries, not a separate table, since it's a
-- single narrow column, same pattern as country_facts.source tracking
-- provenance rather than getting its own table.
alter table countries add column state_dept_entry_exit_code text;
comment on column countries.state_dept_entry_exit_code is
  'Verified working country code for cadataapi.state.gov''s entry_exit_requirements endpoint, when it differs from iso_code. Null = iso_code already works. That endpoint is keyed closer to FIPS 10-4 than ISO 3166-1 for a known subset of countries — see HANDOFF.md 2026-08-21.';

-- Verified 2026-08-21 by empirically probing all ~249 codes and matching
-- each response's actual subject country by name, not by remembering a
-- FIPS table. Not exhaustive — only the countries actually found broken
-- and actually resolved that day; anything absent here either already
-- works via iso_code or is still genuinely unresolved (no code among the
-- 249 tried returned that country's real content).
update countries set state_dept_entry_exit_code = v.code from (values
  ('NG','NI'), ('GM','GA'), ('BM','BD'), ('TD','CD'), ('MN','MG'),
  ('BY','BO'), ('DE','GM'), ('MG','MA'), ('BO','BL'), ('AU','AS'),
  ('PA','PM'), ('KN','SC'), ('BH','BA'), ('BD','BG'), ('LI','LS'),
  ('MA','MO'), ('MU','MP'), ('GA','GB'), ('SG','SN'), ('SN','CV'),
  ('TO','TN'), ('TT','TD'), ('KP','KN')
) as v(destination, code)
where countries.id = v.destination;
