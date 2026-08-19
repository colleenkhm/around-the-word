/// Live-fetched data — weather, currency. Deliberately outside
/// [CountryBundle], since caching either would go stale within hours. No
/// live fetch exists yet; instances are mock values for now.
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
