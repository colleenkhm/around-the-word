-- Whereabout: Costa Rica's English usage_note (026) said no population-wide
-- figure existed. 027 sourced one (8.15%, INEC Encuesta Nacional de Hogares
-- 2017, via Wikipedia), so drop that now-false sentence. The rest of the
-- hand-written note is unchanged.
update country_languages
set usage_note = 'Most widely spoken foreign language; compulsory in schools and common in tourism areas.'
where country_id = 'CR'
  and language_id = (select id from languages where iso_code = 'en');
