-- Allow an empty placeholder visa_requirements row (destination +
-- nationality only) for manual fill-in — official_url, last_verified_at,
-- and issuing_authority all genuinely have nothing to say yet for a row
-- nobody has researched. The refresh function still upserts over these
-- normally once real data is found for a country.
alter table visa_requirements alter column official_url drop not null;
alter table visa_requirements alter column last_verified_at drop not null;
alter table visa_requirements alter column issuing_authority drop not null;

-- One placeholder row per country still missing entry-exit data, for
-- hand-filling. destination_country_id/nationality_country_id only —
-- everything else stays null until real content is added.
insert into visa_requirements (destination_country_id, nationality_country_id)
select c.id, 'US'
from countries c
where c.id != 'US'
  and not exists (
    select 1 from visa_requirements vr
    where vr.destination_country_id = c.id and vr.nationality_country_id = 'US'
  );
