-- Sixth round, same session as 011-016 — a small follow-up targeted pass
-- (TU, RP, PP, CG) after round 5, going after the last few real/common
-- countries still missing. All four verified by reading the actual
-- returned text: Türkiye ("Embassy of the Republic of Turkey"),
-- Philippines ("Embassy of the Republic of the Philippines"), Papua New
-- Guinea (direct, names PNG explicitly), DR Congo ("Embassy of the
-- Democratic Re[public of Congo]" — low mention count but unambiguous
-- content, a short response rather than a weak match).
update countries set state_dept_entry_exit_code = v.code from (values
  ('TR','TU'), ('PH','RP'), ('PG','PP'), ('CD','CG')
) as v(destination, code)
where countries.id = v.destination;
