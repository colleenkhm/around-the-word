-- Corrects a real data-quality bug found 2026-08-25 while diagnosing why
-- Serbia had no visa data: Serbia's own ISO code (RS) was registered in
-- migration 009 as Ukraine's verified state_dept_entry_exit_code override
-- (round-2 discovery, 2026-08-21), but the code's *live* content is
-- unambiguously about Russia, not Ukraine — "Before traveling to Russia,
-- consider the current Travel Advisory. Do not travel to Russia due to:
-- Danger associated with the continuing war between Russia and Ukraine...
-- U.S. Embassy in Moscow...". Ukraine's own visa_requirements.summary was
-- storing this Russia content verbatim (confirmed via a direct DB read).
--
-- Root cause: the 2026-08-21 discovery pass's matching bar was a bare
-- "does the text mention the destination's name anywhere" check — this
-- content genuinely mentions "Ukraine" (in "war between Russia and
-- Ukraine"), so it passed, despite being primarily about Russia. The
-- 2026-08-25 findBestCountryMatch mention-count race (Russia x19 vs.
-- Ukraine, which doesn't place) is what caught this — same class of
-- false positive as the Switzerland/Iran case from the original 2026-08-19
-- audit, just undetected until a stricter check existed.
--
-- Fix: RS becomes Russia's override (Russia was one of the "no data at
-- all" gaps this session was trying to close — this closes it for real,
-- verified by reading the actual returned text, not just the count).
-- Ukraine's incorrect override is cleared (back to null = try its own ISO
-- code UA first) and its wrong summary is nulled rather than left
-- storing content that isn't about Ukraine — visa_requirements' NOT NULL
-- constraints were already dropped in migration 010 specifically to allow
-- a row to sit blank pending re-discovery. Ukraine's real code is
-- unresolved again as of this migration; needs a fresh sweep.
update countries set state_dept_entry_exit_code = 'RS' where id = 'RU';
update countries set state_dept_entry_exit_code = null where id = 'UA';
update visa_requirements set summary = null, last_verified_at = null
  where destination_country_id = 'UA' and nationality_country_id = 'US';
