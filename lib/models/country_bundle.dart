/// The pivot's core client data shapes — see around-the-word-data-architecture.md's
/// "Client Data Objects (Flutter/Dart)" section, which these are modeled
/// directly on. [CountryBundle] is the single fetch/cache/offline unit: one
/// JSON bundle per country (in V1, a mock file under assets/data/bundles/;
/// later, a real Supabase-backed fetch — the model shapes don't change
/// either way).
///
/// Deliberately separate from the old lib/models/country.dart (pre-pivot
/// shape, still used by the not-yet-migrated search/language flow) rather
/// than overwriting it — see HANDOFF.md for why the migration is staged.
library;

import 'country_guide.dart';
import 'language_content.dart';
import 'point_of_interest.dart';
import 'travel_info.dart';

enum ContentStatus { none, partial, complete }

/// The four country-page tabs — **not** five. Confirmed 2026-08-10 against
/// the country-page-mockups.html spec: the client design doc's original
/// fifth tab, Travel Info (advisories + visa), folds into Overview instead
/// of staying separate. That doc still describes five as of this comment
/// and needs updating to match.
enum CountryTab { overview, explore, guide, language }

ContentStatus _contentStatusFromJson(String value) =>
    ContentStatus.values.firstWhere((e) => e.name == value);

class Country {
  final String id;
  final String isoCode;
  final String nameCommon;
  final String nameOfficial;
  final ContentStatus contentStatus;

  const Country({
    required this.id,
    required this.isoCode,
    required this.nameCommon,
    required this.nameOfficial,
    required this.contentStatus,
  });

  factory Country.fromJson(Map<String, dynamic> json) {
    return Country(
      id: json['id'] as String,
      isoCode: json['isoCode'] as String,
      nameCommon: json['nameCommon'] as String,
      nameOfficial: json['nameOfficial'] as String,
      contentStatus: _contentStatusFromJson(json['contentStatus'] as String),
    );
  }
}

/// Nearly every field here is nullable — imports fail, small countries have
/// gaps, and the UI needs to render gracefully around missing fields rather
/// than assuming completeness.
class CountryFacts {
  final String? flagSvgUrl;
  final String? capital;
  final int? population;
  final String? currencyCode;
  final String? currencyName;
  final String? callingCode;
  final List<String> officialLanguages;
  final double? latitude;
  final double? longitude;

  /// Fixed offset from UTC, in minutes (e.g. -360 for UTC-6). Added
  /// 2026-08-10 for the Overview tab's "Right now" local-time display —
  /// flagged but not yet added in the data architecture doc's External
  /// Data Sources table ("Timezone / current local time... needed for the
  /// MVP's 'current time' widget"). **Deliberately a fixed offset, not a
  /// DST-aware IANA timezone name** — good enough for "what time is it
  /// there right now" at a glance; a country that observes DST will show
  /// an hour off part of the year. Revisit with a real timezone package
  /// if that turns out to matter more than the simplicity is worth.
  final int? utcOffsetMinutes;

  final DateTime? lastImportedAt;

  const CountryFacts({
    this.flagSvgUrl,
    this.capital,
    this.population,
    this.currencyCode,
    this.currencyName,
    this.callingCode,
    required this.officialLanguages,
    this.latitude,
    this.longitude,
    this.utcOffsetMinutes,
    this.lastImportedAt,
  });

  factory CountryFacts.fromJson(Map<String, dynamic> json) {
    return CountryFacts(
      flagSvgUrl: json['flagSvgUrl'] as String?,
      capital: json['capital'] as String?,
      population: json['population'] as int?,
      currencyCode: json['currencyCode'] as String?,
      currencyName: json['currencyName'] as String?,
      callingCode: json['callingCode'] as String?,
      officialLanguages: (json['officialLanguages'] as List<dynamic>? ?? [])
          .map((e) => e as String)
          .toList(),
      utcOffsetMinutes: json['utcOffsetMinutes'] as int?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      lastImportedAt: json['lastImportedAt'] == null
          ? null
          : DateTime.parse(json['lastImportedAt'] as String),
    );
  }
}

class City {
  final String id;
  final String name;
  final int? population;
  final double? latitude;
  final double? longitude;
  final bool isFeatured;

  const City({
    required this.id,
    required this.name,
    this.population,
    this.latitude,
    this.longitude,
    required this.isFeatured,
  });

  factory City.fromJson(Map<String, dynamic> json) {
    return City(
      id: json['id'] as String,
      name: json['name'] as String,
      population: json['population'] as int?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      isFeatured: json['isFeatured'] as bool,
    );
  }
}

class Leader {
  final String title;
  final String name;
  final DateTime? since;
  final String? sourceUrl;
  final DateTime? lastVerifiedAt;

  const Leader({
    required this.title,
    required this.name,
    this.since,
    this.sourceUrl,
    this.lastVerifiedAt,
  });

  factory Leader.fromJson(Map<String, dynamic> json) {
    return Leader(
      title: json['title'] as String,
      name: json['name'] as String,
      since: json['since'] == null ? null : DateTime.parse(json['since'] as String),
      sourceUrl: json['sourceUrl'] as String?,
      lastVerifiedAt: json['lastVerifiedAt'] == null
          ? null
          : DateTime.parse(json['lastVerifiedAt'] as String),
    );
  }
}

/// One fetch, one cache entry, one offline unit — see the data architecture
/// doc's "The core unit: a country bundle."
class CountryBundle {
  final Country country;
  final CountryFacts facts;
  final List<City> cities;
  final Leader? leader;
  final CountryGuide guide;
  final List<PointOfInterest> pointsOfInterest;
  final List<Tip> tips;
  final List<Phrase> phrases;
  final List<Word> words;
  final List<CategoryNode> categories;
  final List<TravelAdvisory> advisories;
  final List<String> contributorNames;
  final VisaInfo? visa;
  final RegionalNote? regionalNote;
  final DateTime fetchedAt;

  const CountryBundle({
    required this.country,
    required this.facts,
    required this.cities,
    this.leader,
    required this.guide,
    required this.pointsOfInterest,
    required this.tips,
    required this.phrases,
    required this.words,
    required this.categories,
    required this.advisories,
    required this.contributorNames,
    this.visa,
    this.regionalNote,
    required this.fetchedAt,
  });

  /// Which tabs actually have something to show — Overview is trivially
  /// always included once a bundle exists at all. Implements the client
  /// design doc's "empty tabs are omitted, not shown empty" rule.
  ///
  /// **Not currently wired to [CountryHeader]'s pill row** (corrected
  /// 2026-08-10 — see that widget's doc comment): the pill row shows
  /// whichever tabs have actually been *built* so far, independent of
  /// whether their content exists yet. This getter is still correct and
  /// still the right thing to filter the real `TabBarView` on once
  /// CountryPageScreen exists and hosts all four tabs for real.
  List<CountryTab> get availableTabs => [
        CountryTab.overview,
        if (pointsOfInterest.isNotEmpty) CountryTab.explore,
        if (guide.hasGuideTabContent) CountryTab.guide,
        if (phrases.isNotEmpty || words.isNotEmpty) CountryTab.language,
      ];

  factory CountryBundle.fromJson(Map<String, dynamic> json) {
    return CountryBundle(
      country: Country.fromJson(json['country'] as Map<String, dynamic>),
      facts: CountryFacts.fromJson(json['facts'] as Map<String, dynamic>),
      cities: (json['cities'] as List<dynamic>? ?? [])
          .map((e) => City.fromJson(e as Map<String, dynamic>))
          .toList(),
      leader: json['leader'] == null
          ? null
          : Leader.fromJson(json['leader'] as Map<String, dynamic>),
      guide: CountryGuide.fromJson(json['guide'] as Map<String, dynamic>),
      pointsOfInterest: (json['pointsOfInterest'] as List<dynamic>? ?? [])
          .map((e) => PointOfInterest.fromJson(e as Map<String, dynamic>))
          .toList(),
      tips: (json['tips'] as List<dynamic>? ?? [])
          .map((e) => Tip.fromJson(e as Map<String, dynamic>))
          .toList(),
      phrases: (json['phrases'] as List<dynamic>? ?? [])
          .map((e) => Phrase.fromJson(e as Map<String, dynamic>))
          .toList(),
      words: (json['words'] as List<dynamic>? ?? [])
          .map((e) => Word.fromJson(e as Map<String, dynamic>))
          .toList(),
      categories: (json['categories'] as List<dynamic>? ?? [])
          .map((e) => CategoryNode.fromJson(e as Map<String, dynamic>))
          .toList(),
      advisories: (json['advisories'] as List<dynamic>? ?? [])
          .map((e) => TravelAdvisory.fromJson(e as Map<String, dynamic>))
          .toList(),
      contributorNames: (json['contributorNames'] as List<dynamic>? ?? [])
          .map((e) => e as String)
          .toList(),
      visa: json['visa'] == null
          ? null
          : VisaInfo.fromJson(json['visa'] as Map<String, dynamic>),
      regionalNote: json['regionalNote'] == null
          ? null
          : RegionalNote.fromJson(json['regionalNote'] as Map<String, dynamic>),
      fetchedAt: DateTime.parse(json['fetchedAt'] as String),
    );
  }
}
