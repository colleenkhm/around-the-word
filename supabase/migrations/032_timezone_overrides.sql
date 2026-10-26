-- Whereabout: these countries' stored centroids sit in open ocean (or off
-- the islands), so GeoNames' timezoneJSON returned no zone and timezone
-- stayed null. Mirrors TIMEZONE_OVERRIDES in import-commodity-data.mjs.
-- Bouvet Island (BV) and Heard & McDonald Islands (HM) are uninhabited
-- with no IANA zone, so they stay null.
update country_facts as f
set timezone = v.tz
from (values
  ('AS', 'Pacific/Pago_Pago'),
  ('BS', 'America/Nassau'),
  ('CC', 'Indian/Cocos'),
  ('CV', 'Atlantic/Cape_Verde'),
  ('FJ', 'Pacific/Fiji'),
  ('KY', 'America/Cayman'),
  ('MF', 'America/Marigot'),
  ('MH', 'Pacific/Majuro'),
  ('PF', 'Pacific/Tahiti'),  -- Papeete; Marquesas/Gambier differ
  ('SJ', 'Arctic/Longyearbyen'),
  ('ST', 'Africa/Sao_Tome'),
  ('TV', 'Pacific/Funafuti'),
  ('VU', 'Pacific/Efate')
) as v(country_id, tz)
where f.country_id = v.country_id;
