-- Switch countries' pk/fks from surrogate uuid to iso_code (readable
-- in the table editor). iso_code column itself is untouched; `id` and
-- every *country_id column just take on iso_code's values instead.
-- See HANDOFF.md for full rationale.
--
-- Postgres won't allow a correlated subquery in an ALTER COLUMN TYPE
-- USING clause, so each child fk column is remapped via add new
-- column / backfill (while countries.id is still uuid) / drop old /
-- rename, rather than a straight type change.

-- 1. Add + backfill a text sibling column on every child, before
--    countries.id changes at all.
alter table cities add column country_id_new text;
update cities set country_id_new = c.iso_code from countries c where c.id = cities.country_id;

alter table coming_soon_resources add column country_id_new text;
update coming_soon_resources set country_id_new = c.iso_code from countries c where c.id = coming_soon_resources.country_id;

alter table correction_reports add column country_id_new text;
update correction_reports set country_id_new = c.iso_code from countries c where c.id = correction_reports.country_id;

alter table country_contributors add column country_id_new text;
update country_contributors set country_id_new = c.iso_code from countries c where c.id = country_contributors.country_id;

alter table country_facts add column country_id_new text;
update country_facts set country_id_new = c.iso_code from countries c where c.id = country_facts.country_id;

alter table country_guides add column country_id_new text;
update country_guides set country_id_new = c.iso_code from countries c where c.id = country_guides.country_id;

alter table country_languages add column country_id_new text;
update country_languages set country_id_new = c.iso_code from countries c where c.id = country_languages.country_id;

alter table country_leadership add column country_id_new text;
update country_leadership set country_id_new = c.iso_code from countries c where c.id = country_leadership.country_id;

alter table phrases add column country_id_new text;
update phrases set country_id_new = c.iso_code from countries c where c.id = phrases.country_id;

alter table points_of_interest add column country_id_new text;
update points_of_interest set country_id_new = c.iso_code from countries c where c.id = points_of_interest.country_id;

alter table research_submissions add column country_id_new text;
update research_submissions set country_id_new = c.iso_code from countries c where c.id = research_submissions.country_id;

alter table tips add column country_id_new text;
update tips set country_id_new = c.iso_code from countries c where c.id = tips.country_id;

alter table travel_advisories add column country_id_new text;
update travel_advisories set country_id_new = c.iso_code from countries c where c.id = travel_advisories.country_id;

alter table visa_requirements add column destination_country_id_new text;
alter table visa_requirements add column nationality_country_id_new text;
update visa_requirements set destination_country_id_new = c.iso_code from countries c where c.id = visa_requirements.destination_country_id;
update visa_requirements set nationality_country_id_new = c.iso_code from countries c where c.id = visa_requirements.nationality_country_id;

alter table words add column country_id_new text;
update words set country_id_new = c.iso_code from countries c where c.id = words.country_id;

-- 2. Drop fks/pks that depend on the old uuid columns, then drop those
--    columns and swap the new ones into place.
alter table cities drop constraint cities_country_id_fkey;
alter table cities drop column country_id cascade;
alter table cities rename column country_id_new to country_id;
alter table cities alter column country_id set not null;

alter table coming_soon_resources drop constraint coming_soon_resources_country_id_fkey;
alter table coming_soon_resources drop column country_id cascade;
alter table coming_soon_resources rename column country_id_new to country_id;

alter table correction_reports drop constraint correction_reports_country_id_fkey;
alter table correction_reports drop column country_id cascade;
alter table correction_reports rename column country_id_new to country_id;
alter table correction_reports alter column country_id set not null;

alter table country_contributors drop constraint country_contributors_country_id_fkey;
alter table country_contributors drop constraint country_contributors_pkey;
alter table country_contributors drop column country_id cascade;
alter table country_contributors rename column country_id_new to country_id;
alter table country_contributors alter column country_id set not null;
alter table country_contributors add constraint country_contributors_pkey primary key (country_id, contributor_id);

alter table country_facts drop constraint country_facts_country_id_fkey;
alter table country_facts drop constraint country_facts_pkey;
alter table country_facts drop column country_id cascade;
alter table country_facts rename column country_id_new to country_id;
alter table country_facts alter column country_id set not null;
alter table country_facts add constraint country_facts_pkey primary key (country_id);

alter table country_guides drop constraint country_guides_country_id_fkey;
alter table country_guides drop constraint country_guides_pkey;
alter table country_guides drop column country_id cascade;
alter table country_guides rename column country_id_new to country_id;
alter table country_guides alter column country_id set not null;
alter table country_guides add constraint country_guides_pkey primary key (country_id);

alter table country_languages drop constraint country_languages_country_id_fkey;
alter table country_languages drop constraint country_languages_pkey;
alter table country_languages drop column country_id cascade;
alter table country_languages rename column country_id_new to country_id;
alter table country_languages alter column country_id set not null;
alter table country_languages add constraint country_languages_pkey primary key (country_id, language_id);

alter table country_leadership drop constraint country_leadership_country_id_fkey;
alter table country_leadership drop constraint country_leadership_pkey;
alter table country_leadership drop column country_id cascade;
alter table country_leadership rename column country_id_new to country_id;
alter table country_leadership alter column country_id set not null;
alter table country_leadership add constraint country_leadership_pkey primary key (country_id);

alter table phrases drop constraint phrases_country_id_fkey;
alter table phrases drop column country_id cascade;
alter table phrases rename column country_id_new to country_id;
alter table phrases alter column country_id set not null;

alter table points_of_interest drop constraint points_of_interest_country_id_fkey;
alter table points_of_interest drop column country_id cascade;
alter table points_of_interest rename column country_id_new to country_id;
alter table points_of_interest alter column country_id set not null;

alter table research_submissions drop constraint research_submissions_country_id_fkey;
alter table research_submissions drop column country_id cascade;
alter table research_submissions rename column country_id_new to country_id;
alter table research_submissions alter column country_id set not null;

alter table tips drop constraint tips_country_id_fkey;
alter table tips drop column country_id cascade;
alter table tips rename column country_id_new to country_id;
alter table tips alter column country_id set not null;

alter table travel_advisories drop constraint travel_advisories_country_id_fkey;
alter table travel_advisories drop column country_id cascade;
alter table travel_advisories rename column country_id_new to country_id;
alter table travel_advisories alter column country_id set not null;

alter table visa_requirements drop constraint visa_requirements_destination_country_id_fkey;
alter table visa_requirements drop constraint visa_requirements_nationality_country_id_fkey;
alter table visa_requirements drop column destination_country_id cascade;
alter table visa_requirements drop column nationality_country_id cascade;
alter table visa_requirements rename column destination_country_id_new to destination_country_id;
alter table visa_requirements rename column nationality_country_id_new to nationality_country_id;
alter table visa_requirements alter column destination_country_id set not null;
alter table visa_requirements alter column nationality_country_id set not null;

alter table words drop constraint words_country_id_fkey;
alter table words drop column country_id cascade;
alter table words rename column country_id_new to country_id;
alter table words alter column country_id set not null;

-- 3. countries.id becomes the iso_code value (plain column reference,
--    no subquery, so USING works directly here).
alter table countries alter column id drop default;
alter table countries alter column id type text using iso_code;

-- 4. Recreate fks text-to-text, on update cascade so a future iso_code
--    correction propagates instead of orphaning rows.
alter table cities add constraint cities_country_id_fkey foreign key (country_id) references countries(id) on delete cascade on update cascade;
alter table coming_soon_resources add constraint coming_soon_resources_country_id_fkey foreign key (country_id) references countries(id) on delete cascade on update cascade;
alter table correction_reports add constraint correction_reports_country_id_fkey foreign key (country_id) references countries(id) on delete cascade on update cascade;
alter table country_contributors add constraint country_contributors_country_id_fkey foreign key (country_id) references countries(id) on delete cascade on update cascade;
alter table country_facts add constraint country_facts_country_id_fkey foreign key (country_id) references countries(id) on delete cascade on update cascade;
alter table country_guides add constraint country_guides_country_id_fkey foreign key (country_id) references countries(id) on delete cascade on update cascade;
alter table country_languages add constraint country_languages_country_id_fkey foreign key (country_id) references countries(id) on delete cascade on update cascade;
alter table country_leadership add constraint country_leadership_country_id_fkey foreign key (country_id) references countries(id) on delete cascade on update cascade;
alter table phrases add constraint phrases_country_id_fkey foreign key (country_id) references countries(id) on delete cascade on update cascade;
alter table points_of_interest add constraint points_of_interest_country_id_fkey foreign key (country_id) references countries(id) on delete cascade on update cascade;
alter table research_submissions add constraint research_submissions_country_id_fkey foreign key (country_id) references countries(id) on delete cascade on update cascade;
alter table tips add constraint tips_country_id_fkey foreign key (country_id) references countries(id) on delete cascade on update cascade;
alter table travel_advisories add constraint travel_advisories_country_id_fkey foreign key (country_id) references countries(id) on delete cascade on update cascade;
alter table visa_requirements add constraint visa_requirements_destination_country_id_fkey foreign key (destination_country_id) references countries(id) on delete cascade on update cascade;
alter table visa_requirements add constraint visa_requirements_nationality_country_id_fkey foreign key (nationality_country_id) references countries(id) on delete cascade on update cascade;
alter table words add constraint words_country_id_fkey foreign key (country_id) references countries(id) on delete cascade on update cascade;

-- 5. Restore the indexes that existed on the old columns (plain
--    column drop/rename doesn't carry over non-pk/fk indexes).
create index idx_cities_country on cities (country_id);
create index idx_phrases_country on phrases (country_id);
create index idx_poi_country on points_of_interest (country_id);
create index idx_advisories_country on travel_advisories (country_id);
create unique index travel_advisories_country_authority_key on travel_advisories (country_id, issuing_authority);
create index idx_visa_dest on visa_requirements (destination_country_id, nationality_country_id);
create unique index visa_requirements_destination_nationality_key on visa_requirements (destination_country_id, nationality_country_id);
create index idx_words_country on words (country_id);
