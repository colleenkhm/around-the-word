-- Second round of state_dept_entry_exit_code discovery (2026-08-21,
-- same session as migration 008), surfaced while filling in the ~120
-- countries that had no visa_requirements row at all rather than a
-- null-summary one. All 23 verified by reading actual fetched content,
-- not just a name-match log — see HANDOFF.md.
update countries set state_dept_entry_exit_code = v.code from (values
  ('DZ','AG'), ('AT','AU'), ('BS','BF'), ('BZ','BH'), ('BJ','BN'),
  ('BI','BY'), ('CL','CI'), ('DM','DO'), ('SV','ES'), ('GE','GG'),
  ('KI','KR'), ('MS','MH'), ('NE','NG'), ('PW','PS'), ('PY','PA'),
  ('TL','TT'), ('UA','RS'),
  ('VG','VI'), ('LC','ST'), ('OM','MU'), ('KM','CN'), ('LR','LI'), ('MM','BM')
) as v(destination, code)
where countries.id = v.destination;
