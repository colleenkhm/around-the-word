/// The curated guide content for a country — dress expectations, cuisine,
/// history, festivals, prep notes, best times to visit, and practical norms.
/// Shapes mirror `country_guides` in around-the-word-data-architecture.md's
/// "Client Data Objects" section.
library;

enum CrowdLevel { low, moderate, high, peak }

CrowdLevel _crowdLevelFromJson(String value) =>
    CrowdLevel.values.firstWhere((e) => e.name == value);

enum Severity { fyi, important, critical }

Severity _severityFromJson(String value) =>
    Severity.values.firstWhere((e) => e.name == value);

enum Urgency { optional, recommended, required }

Urgency _urgencyFromJson(String value) =>
    Urgency.values.firstWhere((e) => e.name == value);

class CountryGuide {
  final List<BestTime> bestTimes;
  final List<Season> seasons;
  final List<NormItem> practicalNorms;
  final List<DressExpectation> dressExpectations;
  final List<CuisineNote> cuisine;
  final List<HistoricalEvent> historicalEvents;
  final List<Festival> festivals;
  final List<PrepNote> prepNotes;
  final DateTime? lastReviewedAt;

  const CountryGuide({
    required this.bestTimes,
    required this.seasons,
    required this.practicalNorms,
    required this.dressExpectations,
    required this.cuisine,
    required this.historicalEvents,
    required this.festivals,
    required this.prepNotes,
    this.lastReviewedAt,
  });

  /// The [Season] covering [date] (country-local, not UTC — pass a date
  /// already adjusted by [CountryFacts.utcOffsetMinutes] if that matters
  /// to the caller), or null if [seasons] doesn't cover that month. Doesn't
  /// currently happen for a properly-authored full-year partition, but
  /// [seasons] is free-form content like everything else in this class —
  /// nothing enforces the partition being complete.
  Season? seasonFor(DateTime date) {
    for (final season in seasons) {
      if (season.covers(date.month)) return season;
    }
    return null;
  }

  /// True when every section is empty, including
  /// [bestTimes]/[seasons]/[practicalNorms].
  bool get isEmpty =>
      bestTimes.isEmpty &&
      seasons.isEmpty &&
      practicalNorms.isEmpty &&
      dressExpectations.isEmpty &&
      cuisine.isEmpty &&
      historicalEvents.isEmpty &&
      festivals.isEmpty &&
      prepNotes.isEmpty;

  /// Whether the **Guide tab** specifically has anything to show —
  /// deliberately excludes [bestTimes]/[practicalNorms], which display in
  /// Overview instead (see client design doc: "best_time and the *_norm
  /// types display in Overview, the rest here"). A country with only
  /// best-times/practical-norms content clears [isEmpty] but should still
  /// omit the Guide tab.
  bool get hasGuideTabContent =>
      dressExpectations.isNotEmpty ||
      cuisine.isNotEmpty ||
      historicalEvents.isNotEmpty ||
      festivals.isNotEmpty ||
      prepNotes.isNotEmpty;

  factory CountryGuide.fromJson(Map<String, dynamic> json) {
    return CountryGuide(
      bestTimes: (json['bestTimes'] as List<dynamic>? ?? [])
          .map((e) => BestTime.fromJson(e as Map<String, dynamic>))
          .toList(),
      seasons: (json['seasons'] as List<dynamic>? ?? [])
          .map((e) => Season.fromJson(e as Map<String, dynamic>))
          .toList(),
      practicalNorms: (json['practicalNorms'] as List<dynamic>? ?? [])
          .map((e) => NormItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      dressExpectations: (json['dressExpectations'] as List<dynamic>? ?? [])
          .map((e) => DressExpectation.fromJson(e as Map<String, dynamic>))
          .toList(),
      cuisine: (json['cuisine'] as List<dynamic>? ?? [])
          .map((e) => CuisineNote.fromJson(e as Map<String, dynamic>))
          .toList(),
      historicalEvents: (json['historicalEvents'] as List<dynamic>? ?? [])
          .map((e) => HistoricalEvent.fromJson(e as Map<String, dynamic>))
          .toList(),
      festivals: (json['festivals'] as List<dynamic>? ?? [])
          .map((e) => Festival.fromJson(e as Map<String, dynamic>))
          .toList(),
      prepNotes: (json['prepNotes'] as List<dynamic>? ?? [])
          .map((e) => PrepNote.fromJson(e as Map<String, dynamic>))
          .toList(),
      lastReviewedAt: json['lastReviewedAt'] == null
          ? null
          : DateTime.parse(json['lastReviewedAt'] as String),
    );
  }
}

class Festival {
  final String title;
  final String body;
  final String months;

  const Festival({required this.title, required this.body, required this.months});

  factory Festival.fromJson(Map<String, dynamic> json) {
    return Festival(
      title: json['title'] as String,
      body: json['body'] as String,
      months: json['months'] as String,
    );
  }
}

/// [whyShort] is the display field shown in parentheses next to [months]
/// (e.g. "September (dry season)") — a bare list of months is not
/// acceptable UI output on its own. [why] holds the fuller prose. See the
/// data architecture doc's `why_short`/`why` split.
class BestTime {
  final String months;
  final String whyShort;
  final String why;
  final CrowdLevel crowdLevel;
  final String? weatherNote;

  const BestTime({
    required this.months,
    required this.whyShort,
    required this.why,
    required this.crowdLevel,
    this.weatherNote,
  });

  factory BestTime.fromJson(Map<String, dynamic> json) {
    return BestTime(
      months: json['months'] as String,
      whyShort: json['whyShort'] as String,
      why: json['why'] as String,
      crowdLevel: _crowdLevelFromJson(json['crowdLevel'] as String),
      weatherNote: json['weatherNote'] as String?,
    );
  }
}

/// A full-year season partition — distinct from [BestTime], which only
/// covers the *good-to-visit* windows and can leave months uncovered
/// (Costa Rica's bestTimes cover Dec–Apr and May–Jun, nothing for
/// Jul–Nov). Added 2026-08-10 for the Overview tab's "Right now" section,
/// replacing a single country-wide weather reading — misleading given how
/// much weather varies by region within a country (the same reasoning
/// [BestTime.weatherNote] already runs into, e.g. Guanacaste turning dusty
/// while the rest of Costa Rica stays lush).
///
/// **[startMonth]/[endMonth] as numbers, not [BestTime]'s free-text
/// [BestTime.months] string** — deliberate, and the one place this
/// diverges from that established pattern. Everywhere else, months are
/// free text because they're purely for display; here they need to be
/// mechanically queryable ("what season is it right now"), which free
/// text can't support without a fragile parser.
class Season {
  /// 1–12. May exceed [endMonth] to represent a range that wraps around
  /// the new year (e.g. December–April: startMonth 12, endMonth 4).
  final int startMonth;
  final int endMonth;
  final String label;

  const Season({
    required this.startMonth,
    required this.endMonth,
    required this.label,
  });

  bool covers(int month) => startMonth <= endMonth
      ? month >= startMonth && month <= endMonth
      : month >= startMonth || month <= endMonth;

  factory Season.fromJson(Map<String, dynamic> json) {
    return Season(
      startMonth: json['startMonth'] as int,
      endMonth: json['endMonth'] as int,
      label: json['label'] as String,
    );
  }
}

class NormItem {
  final String type; // "tipping_norm" | "punctuality_norm" | ... — open-ended
  final String title;
  final String body;
  final Severity severity;

  const NormItem({
    required this.type,
    required this.title,
    required this.body,
    required this.severity,
  });

  factory NormItem.fromJson(Map<String, dynamic> json) {
    return NormItem(
      type: json['type'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      severity: _severityFromJson(json['severity'] as String),
    );
  }
}

class DressExpectation {
  final String context;
  final String expectation;
  final String? appliesTo;

  const DressExpectation({
    required this.context,
    required this.expectation,
    this.appliesTo,
  });

  factory DressExpectation.fromJson(Map<String, dynamic> json) {
    return DressExpectation(
      context: json['context'] as String,
      expectation: json['expectation'] as String,
      appliesTo: json['appliesTo'] as String?,
    );
  }
}

class CuisineNote {
  final String dish;
  final String description;
  final String? where;
  final List<String> dietaryFlags;

  const CuisineNote({
    required this.dish,
    required this.description,
    this.where,
    required this.dietaryFlags,
  });

  factory CuisineNote.fromJson(Map<String, dynamic> json) {
    return CuisineNote(
      dish: json['dish'] as String,
      description: json['description'] as String,
      where: json['where'] as String?,
      dietaryFlags: (json['dietaryFlags'] as List<dynamic>? ?? [])
          .map((e) => e as String)
          .toList(),
    );
  }
}

class HistoricalEvent {
  final int year;
  final String title;
  final String whyItMatters;

  const HistoricalEvent({
    required this.year,
    required this.title,
    required this.whyItMatters,
  });

  factory HistoricalEvent.fromJson(Map<String, dynamic> json) {
    return HistoricalEvent(
      year: json['year'] as int,
      title: json['title'] as String,
      whyItMatters: json['whyItMatters'] as String,
    );
  }
}

class PrepNote {
  final String title;
  final String body;
  final Urgency urgency;

  const PrepNote({required this.title, required this.body, required this.urgency});

  factory PrepNote.fromJson(Map<String, dynamic> json) {
    return PrepNote(
      title: json['title'] as String,
      body: json['body'] as String,
      urgency: _urgencyFromJson(json['urgency'] as String),
    );
  }
}
