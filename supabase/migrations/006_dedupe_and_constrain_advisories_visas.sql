-- Forin: prevent the duplicate-row bug (found twice: Germany's
-- travel_advisories via import-curated-data.mjs's plain .insert(), and
-- the same pattern in the State Dept refresh function) from recurring,
-- and make future refreshes fast (one bulk upsert instead of N sequential
-- delete+insert round-trips).

-- Dedupe existing rows first — a unique index can't be created while
-- duplicates exist. Keeps the most recently created row of each set.
delete from travel_advisories a using travel_advisories b
  where a.country_id = b.country_id
    and a.issuing_authority = b.issuing_authority
    and a.created_at < b.created_at;

delete from visa_requirements a using visa_requirements b
  where a.destination_country_id = b.destination_country_id
    and a.nationality_country_id = b.nationality_country_id
    and a.created_at < b.created_at;

create unique index travel_advisories_country_authority_key
  on travel_advisories (country_id, issuing_authority);

create unique index visa_requirements_destination_nationality_key
  on visa_requirements (destination_country_id, nationality_country_id);
