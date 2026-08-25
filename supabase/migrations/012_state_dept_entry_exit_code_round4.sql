-- Fourth round of state_dept_entry_exit_code discovery (2026-08-24, same
-- session as migration 011). Where 011 found the *category* of bug (a
-- working code that isn't any country's ISO code, so invisible to a probe
-- limited to the 249 ISO codes), this is the systematic sweep: the full
-- two-letter alpha space (676 combinations) minus the 249 already tried,
-- checked against all 115 then-missing countries using the stricter
-- 2026-08-21 bar (destination name in the first 250 characters, or an
-- exact "Embassy of <country>" phrase — not a bare name-anywhere match,
-- which is what produced false positives like Switzerland/Iran last
-- round). All 30 matches (this file's 29 plus Japan in 011) read by eye
-- against the actual returned text, not just the matcher's verdict — see
-- HANDOFF.md. discover-visa-codes-fullspace.mjs used for the sweep,
-- deleted after use per existing convention.
update countries set state_dept_entry_exit_code = v.code from (values
  ('AD','AN'), ('AQ','AY'), ('BW','BC'), ('BA','BK'), ('SB','BP'),
  ('BG','BU'), ('BN','BX'), ('KH','CB'), ('LK','CE'), ('KY','CJ'),
  ('CR','CS'), ('CF','CT'), ('DK','DA'), ('DO','DR'), ('GQ','EK'),
  ('EE','EN'), ('GD','GJ'), ('GN','GV'), ('HN','HO'), ('IS','IC'),
  ('IQ','IZ'), ('KW','KU'), ('XK','KV'), ('LB','LE'), ('LT','LH'),
  ('SK','LO'), ('MW','MI'), ('ME','MJ'), ('VU','NH')
) as v(destination, code)
where countries.id = v.destination;
