-- Language name fixes surfaced while verifying EU figures (Eurobarometer 540).
-- REST Countries' names for these were outdated or a bare code.

-- Moldova and Romania both use this row; "Moldavian" is no longer the official name in either.
update languages set name = 'Romanian' where iso_code = 'ro';

update languages set name = 'Irish' where iso_code = 'ga';

-- Austria's official language is German, not Austro-Bavarian (a dialect group).
update country_languages
set language_id = (select id from languages where iso_code = 'de')
where country_id = (select id from countries where iso_code = 'AT')
  and language_id = (select id from languages where iso_code = 'bar')
  and not exists (
    select 1 from country_languages
    where country_id = (select id from countries where iso_code = 'AT')
      and language_id = (select id from languages where iso_code = 'de')
  );
