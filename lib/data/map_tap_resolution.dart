import '../models/country.dart';
import '../models/world_map_country.dart';

/// Pulled out as plain functions (no BuildContext/Navigator/SnackBar) so the
/// selection logic can be unit-tested directly, without pixel-tapping a
/// specific country's shape on a rendered map in a widget test.

sealed class ContinentTapResult {
  const ContinentTapResult();
}

class ContinentTapUnrecognized extends ContinentTapResult {
  const ContinentTapUnrecognized();
}

class ContinentTapUnavailable extends ContinentTapResult {
  final String continent;
  const ContinentTapUnavailable(this.continent);
}

class ContinentTapAvailable extends ContinentTapResult {
  final String continent;
  const ContinentTapAvailable(this.continent);
}

/// Resolves a tapped map region id to a continent, and whether that
/// continent has any active content.
ContinentTapResult resolveContinentTap({
  required String tappedId,
  required List<WorldMapCountry> worldCountries,
  required bool Function(String continent) isContinentActive,
}) {
  WorldMapCountry? match;
  for (final c in worldCountries) {
    if (c.id == tappedId) {
      match = c;
      break;
    }
  }
  if (match == null) return const ContinentTapUnrecognized();

  if (!isContinentActive(match.continent)) {
    return ContinentTapUnavailable(match.continent);
  }
  return ContinentTapAvailable(match.continent);
}

sealed class CountryTapResult {
  const CountryTapResult();
}

class CountryTapUnrecognized extends CountryTapResult {
  const CountryTapUnrecognized();
}

/// The tapped region is a real place, just not one we have content for
/// (either not in countries.json at all, or present but inactive).
class CountryTapUnavailable extends CountryTapResult {
  final String name;
  const CountryTapUnavailable(this.name);
}

class CountryTapAvailable extends CountryTapResult {
  final Country country;
  const CountryTapAvailable(this.country);
}

/// Resolves a tapped map region id to one of our curated, content-backed
/// [Country] entries — cross-referencing the full-geography [worldCountries]
/// (for the display name, even when we don't have that country) against the
/// curated [countries] list (the actual source of truth for what's active).
CountryTapResult resolveCountryTap({
  required String tappedId,
  required List<WorldMapCountry> worldCountries,
  required List<Country> countries,
}) {
  WorldMapCountry? worldMatch;
  for (final c in worldCountries) {
    if (c.id == tappedId) {
      worldMatch = c;
      break;
    }
  }
  if (worldMatch == null) return const CountryTapUnrecognized();

  Country? curatedMatch;
  for (final c in countries) {
    if (c.countryCode.toLowerCase() == tappedId) {
      curatedMatch = c;
      break;
    }
  }

  if (curatedMatch == null || !curatedMatch.active) {
    return CountryTapUnavailable(worldMatch.name);
  }
  return CountryTapAvailable(curatedMatch);
}
