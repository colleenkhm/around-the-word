-- Whereabout: weather is city-level (V2), so strip weather_note from every
-- country_guides.best_times entry. Order within the array is preserved.
update country_guides
set best_times = (
  select coalesce(jsonb_agg(entry - 'weather_note' order by ord), '[]'::jsonb)
  from jsonb_array_elements(best_times) with ordinality as t(entry, ord)
)
where best_times @? '$[*].weather_note';
