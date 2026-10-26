-- Whereabout: REST Countries lists a defunct or non-ISO currency first for
-- these, so the importer stored a code ExchangeRate-API can't price.
-- Mirrors CURRENCY_OVERRIDES in fetch_country_facts.py.
update country_facts
set currency_code = 'CUP', currency_name = 'Cuban peso'
where country_id = 'CU';  -- CUC retired January 2021

update country_facts
set currency_code = 'NZD', currency_name = 'New Zealand dollar'
where country_id = 'CK';  -- CKD isn't an ISO code; pegged 1:1 to NZD
