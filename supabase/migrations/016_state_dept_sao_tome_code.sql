-- Omitted from migration 015 by mistake — TP was verified in the same
-- targeted round ("You must present a passport and proof of yellow fever
-- vaccination to enter Sao Tome and Principe... Sao Tome and Principe
-- does not currently maintain an embassy in the United States", runner-up
-- Angola x2 only, real win) but didn't make it into that migration's
-- values list. Caught immediately after by the post-migration missing-
-- count check still showing ST.
update countries set state_dept_entry_exit_code = 'TP' where id = 'ST';
