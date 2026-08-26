-- Fills in real content for the 6 US territories deliberately kept as
-- open rows after migration 020's territory cleanup (see
-- state-dept-data-handoff.md) — not sourced from cadataapi.state.gov
-- (that API has no concept of "entry requirements" for domestic US
-- territory, since none exist), but from usa.gov and fws.gov directly,
-- fetched and read live 2026-08-25, not assumed. Two real nuances found
-- by checking rather than assuming uniform "no visa" treatment across
-- all six:
--
-- - American Samoa is genuinely different from the other four inhabited
--   territories: usa.gov is explicit that it requires a passport or a
--   certified U.S. birth certificate to enter, unlike Guam/CNMI/Puerto
--   Rico/USVI.
-- - United States Minor Outlying Islands isn't covered by usa.gov's
--   passport-requirements page at all — it's a set of largely
--   uninhabited islands/atolls managed as wildlife refuges or restricted
--   military sites, not a real travel destination. Sourced from the
--   U.S. Fish and Wildlife Service's own Midway Atoll page instead
--   (confirmed currently closed to public visitation).
update visa_requirements set
  issuing_authority = 'USA.gov',
  summary = 'No passport or visa is required for U.S. residents traveling between the United States and Guam — as a U.S. territory, travel there is domestic, not international, travel.',
  official_url = 'https://www.usa.gov/visit-territories',
  last_verified_at = now()
where destination_country_id = 'GU' and nationality_country_id = 'US';

update visa_requirements set
  issuing_authority = 'USA.gov',
  summary = 'No passport or visa is required for U.S. residents traveling between the United States and the Northern Mariana Islands — as a U.S. territory, travel there is domestic, not international, travel.',
  official_url = 'https://www.usa.gov/visit-territories',
  last_verified_at = now()
where destination_country_id = 'MP' and nationality_country_id = 'US';

update visa_requirements set
  issuing_authority = 'USA.gov',
  summary = 'No passport or visa is required for U.S. residents traveling between the United States and Puerto Rico — as a U.S. territory, travel there is domestic, not international, travel.',
  official_url = 'https://www.usa.gov/visit-territories',
  last_verified_at = now()
where destination_country_id = 'PR' and nationality_country_id = 'US';

update visa_requirements set
  issuing_authority = 'USA.gov',
  summary = 'No passport or visa is required for U.S. residents traveling between the United States and the U.S. Virgin Islands — as a U.S. territory, travel there is domestic, not international, travel.',
  official_url = 'https://www.usa.gov/visit-territories',
  last_verified_at = now()
where destination_country_id = 'VI' and nationality_country_id = 'US';

update visa_requirements set
  issuing_authority = 'USA.gov',
  summary = 'American Samoa is a U.S. territory, but unlike Guam, the Northern Mariana Islands, Puerto Rico, and the U.S. Virgin Islands, U.S. residents need a passport or a certified U.S. birth certificate to enter — no visa in the international sense, but a stricter ID requirement than the other territories.',
  official_url = 'https://www.usa.gov/visit-territories',
  last_verified_at = now()
where destination_country_id = 'AS' and nationality_country_id = 'US';

update visa_requirements set
  issuing_authority = 'U.S. Fish and Wildlife Service',
  summary = 'No visa applies to U.S. residents here in the ordinary sense — the U.S. Minor Outlying Islands are a set of largely uninhabited Pacific and Caribbean islands (Baker Island, Howland Island, Jarvis Island, Johnston Atoll, Kingman Reef, Midway Atoll, Navassa Island, Palmyra Atoll, Wake Island) managed as wildlife refuges or restricted military sites. Midway Atoll, the most notable, is currently closed to public visitation entirely.',
  official_url = 'https://www.fws.gov/refuge/midway-atoll',
  last_verified_at = now()
where destination_country_id = 'UM' and nationality_country_id = 'US';
