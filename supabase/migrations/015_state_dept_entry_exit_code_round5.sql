-- Fifth round of state_dept_entry_exit_code discovery (2026-08-25, same
-- session as migrations 011-014). Found two different ways this round:
--
-- 1. Three from discover-state-dept-codes' alphabetical sweep mode
--    (AV, AC, EZ) and one from its diagnose mode as a side effect of
--    investigating Switzerland (CH turned out to be China's real code,
--    not Switzerland's — see migration 014's neighboring entry).
-- 2. The rest from a *targeted* pass using well-established FIPS 10-4
--    codes as a search-order hypothesis (UK, SP, SW, VM, PO, TI, TX, YM,
--    ZI, TO, RI, NU, UP, MN, SU, OD, MC, ZA, WZ, RM, UV, WA, NS) instead
--    of continuing the blind alphabetical sweep, which was converging
--    slowly (~75 codes checked for 4 real matches). Same verification
--    bar either way — every one of these was confirmed by reading the
--    actual returned text, not trusted from the code alone. Recovers
--    Ukraine for real, correctly this time (see migration 013 — its
--    previous code, RS, was actually Russia's).
--
-- Two of these (SU/Sudan and OD/South Sudan) were only resolved
-- correctly after fixing a real bug in findBestCountryMatch found live
-- during this same check: "Sudan" is a whole word inside "South Sudan",
-- so an early version of the matcher let South Sudan's own mentions
-- inflate bare "Sudan"'s count and nearly assigned OD to Sudan instead
-- of South Sudan. Fixed in _shared/state-dept.ts (countAllMentions,
-- longest-name-first with masking) before writing this migration — see
-- HANDOFF.md for the full story.
update countries set state_dept_entry_exit_code = v.code from (values
  ('AI','AV'), ('AG','AC'), ('CZ','EZ'), ('CN','CH'),
  ('GB','UK'), ('ES','SP'), ('SE','SW'), ('VN','VM'), ('PT','PO'),
  ('TJ','TI'), ('TM','TX'), ('YE','YM'), ('ZW','ZI'), ('TG','TO'),
  ('RS','RI'), ('NI','NU'), ('UA','UP'), ('MC','MN'), ('SD','SU'),
  ('SS','OD'), ('MO','MC'), ('ZM','ZA'), ('SZ','WZ'), ('MH','RM'),
  ('BF','UV'), ('NA','WA'), ('SR','NS')
) as v(destination, code)
where countries.id = v.destination;
