/// Live-fetched data — see the data architecture doc's "Weather (fetched
/// live, never bundled)" and "Currency conversion (fetched live, never
/// bundled)" sections. Deliberately outside [CountryBundle]: caching
/// either of these would mean showing something that's quietly wrong
/// within hours, which breaks the "bundle is good offline for weeks"
/// property everything else depends on.
///
/// No live fetch exists yet (weather/currency API integration is on
/// CLAUDE.md's don't-build-without-being-asked list until a Supabase Edge
/// Function exists to proxy them — key security). Until then, instances
/// of these are constructed directly with mock values wherever they're
/// needed for review, e.g. CountryHeaderPreviewScreen — never read from
/// bundle JSON.
library;

class WeatherOutlook {
  final String countryId;
  final String? cityId;
  final DateTime forecastFor;
  final double? tempHighC;
  final double? tempLowC;
  final String? conditions;
  final DateTime fetchedAt;

  const WeatherOutlook({
    required this.countryId,
    this.cityId,
    required this.forecastFor,
    this.tempHighC,
    this.tempLowC,
    this.conditions,
    required this.fetchedAt,
  });
}

class ExchangeRate {
  final String currencyCode;
  final double rateFromUsd;
  final DateTime fetchedAt;

  const ExchangeRate({
    required this.currencyCode,
    required this.rateFromUsd,
    required this.fetchedAt,
  });
}
