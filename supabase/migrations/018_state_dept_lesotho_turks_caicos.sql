-- Verified by reading the FULL returned text (not just a 400-char
-- preview) for both, since each initially scored a *different* country
-- as the mention-count winner:
--
-- LT -> Lesotho: scored South Africa (9) over Lesotho (6), but the text
-- is unambiguously Lesotho's own entry_exit content ("Embassy of the
-- Kingdom of Lesotho", "U.S. citizens entering Lesotho...") that happens
-- to discuss South Africa heavily because Lesotho is an enclave entirely
-- surrounded by South Africa — genuine geographic entanglement, same
-- shape as Monaco's real content discussing France (migration 015), not
-- a misroute.
--
-- TK -> Turks and Caicos Islands: scored Bahamas (2) over its own name
-- (0!) — root-caused, not just overridden: its real content never
-- writes the "Islands" suffix that's in name_common, so the exact-name
-- match failed entirely while "Bahamas" (mentioned twice, for the
-- nearest emergency U.S. passport office) won by default. Fixed at the
-- source in _shared/state-dept.ts (NAME_ALIASES: "turks and caicos" ->
-- "Turks and Caicos Islands"), so this isn't just a one-off override —
-- the matcher itself now recognizes the country's own real usage.
update countries set state_dept_entry_exit_code = v.code from (values
  ('LS','LT'), ('TC','TK')
) as v(destination, code)
where countries.id = v.destination;
