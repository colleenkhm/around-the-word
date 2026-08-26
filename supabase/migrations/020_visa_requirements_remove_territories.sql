-- Removes the 35 blank visa_requirements placeholder rows (from
-- migration 010) that were never going to get real State Dept content —
-- not a data gap, an administrative one. Per direction received
-- 2026-08-25, after a full classification of every remaining missing
-- country checked against actual sovereignty/administrative status (not
-- guessed): these 35 are either uninhabited (no real travelers) or
-- legally part of / administered by another country (follow that
-- country's entry rules), the same shape as Vatican City→Italy and
-- Svalbard→Norway. Full reasoning, the parent-country breakdown, and the
-- exact list live in state-dept-data-handoff.md's territory table —
-- read that before touching this again, including before adding any of
-- these back.
--
-- Deliberately does NOT touch `countries`, `cities`, `country_facts`, or
-- anything else — only visa_requirements. These are still real,
-- searchable places in the app; they just don't get a distinct US-visa
-- row from this pipeline. This also breaks migration 010's "every
-- non-US country has exactly one visa_requirements row" invariant for
-- these 35, on purpose — re-adding a blank placeholder row for one of
-- them later (if a real content source shows up, or a "no visa needed —
-- travels as part of <Parent>" note gets hand-written) is a one-line
-- insert, same shape as migration 010's original backfill.
--
-- The 4 uninhabited (no permanent population): Bouvet Island, Heard
-- Island and McDonald Islands, French Southern and Antarctic Lands,
-- South Georgia.
--
-- The 31 inhabited dependencies, by parent:
--   United Kingdom: British Indian Ocean Territory, Falkland Islands,
--     Gibraltar, Guernsey, Isle of Man, Jersey, Pitcairn Islands,
--     Saint Helena/Ascension/Tristan da Cunha
--   Denmark: Faroe Islands, Greenland
--   Netherlands: Caribbean Netherlands, Curaçao, Sint Maarten
--   France: French Guiana, French Polynesia, Guadeloupe, Martinique,
--     Mayotte, Réunion, Saint Barthélemy, Saint Pierre and Miquelon,
--     Wallis and Futuna
--   New Zealand: Cook Islands, Niue, Tokelau
--   Australia: Christmas Island, Cocos (Keeling) Islands, Norfolk Island
--   Finland: Åland Islands
--   Norway: Svalbard and Jan Mayen
--   Italy: Vatican City
--
-- Explicitly kept, NOT deleted here (see state-dept-data-handoff.md):
-- Israel, Palestine, Monaco, San Marino, Western Sahara (real,
-- independent countries with only a live-feed gap — worth manual
-- research later) and the 6 US territories (American Samoa, Guam,
-- Northern Mariana Islands, Puerto Rico, US Virgin Islands, US Minor
-- Outlying Islands — no visa/passport ever needed for US citizens there,
-- kept anyway since the app targets US travelers and these are real
-- destinations for that audience).
delete from visa_requirements
where nationality_country_id = 'US'
  and destination_country_id in (
    'BV','HM','TF','GS',
    'IO','FK','GI','GG','IM','JE','PN','SH',
    'FO','GL',
    'BQ','CW','SX',
    'GF','PF','GP','MQ','YT','RE','BL','PM','WF',
    'CK','NU','TK',
    'CX','CC','NF',
    'AX',
    'SJ',
    'VA'
  );
