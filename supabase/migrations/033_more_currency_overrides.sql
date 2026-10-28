-- Whereabout: REST Countries' first-listed currency is wrong for these, so
-- the importer stored a currency that isn't the one travelers use. Mirrors
-- CURRENCY_OVERRIDES in import-commodity-data.mjs.
update country_facts
set currency_code = 'ZWG', currency_name = 'Zimbabwe Gold'
where country_id = 'ZW';  -- was BWP; ZWG since April 2024

update country_facts
set currency_code = 'ILS', currency_name = 'Israeli new shekel'
where country_id = 'PS';  -- was EGP; shekel is primary under the Paris Protocol

update country_facts
set currency_code = 'MAD', currency_name = 'Moroccan dirham'
where country_id = 'EH';  -- was DZD; dirham in Moroccan-administered areas
