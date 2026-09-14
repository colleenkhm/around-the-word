/// Travel Info content: advisories, visa/entry requirements, regional
/// notes. Always carries a verification date and source link.
library;

class TravelAdvisory {
  final String issuingAuthority; // required — never render a level without it
  final String? level;
  final String? levelLabel;
  final String? summary;

  /// [summary] in the country's primary language, for the flashcard_layout
  /// branch's flip-card treatment. Null on any bundle without a translation
  /// (every Supabase country today) — sections fall back to English-only,
  /// no flip affordance. See HANDOFF.md's flashcard_layout entry.
  final String? summaryEs;

  /// [levelLabel] in the country's primary language — see [summaryEs].
  final String? levelLabelEs;
  final String officialUrl; // required
  final DateTime? issuedAt;
  final DateTime lastVerifiedAt; // required

  const TravelAdvisory({
    required this.issuingAuthority,
    this.level,
    this.levelLabel,
    this.levelLabelEs,
    this.summary,
    this.summaryEs,
    required this.officialUrl,
    this.issuedAt,
    required this.lastVerifiedAt,
  });

  factory TravelAdvisory.fromJson(Map<String, dynamic> json) {
    return TravelAdvisory(
      issuingAuthority: json['issuingAuthority'] as String,
      level: json['level'] as String?,
      levelLabel: json['levelLabel'] as String?,
      levelLabelEs: json['levelLabelEs'] as String?,
      summary: json['summary'] as String?,
      summaryEs: json['summaryEs'] as String?,
      officialUrl: json['officialUrl'] as String,
      issuedAt: json['issuedAt'] == null
          ? null
          : DateTime.parse(json['issuedAt'] as String),
      lastVerifiedAt: DateTime.parse(json['lastVerifiedAt'] as String),
    );
  }
}

class VisaInfo {
  final String issuingAuthority; // required — same discipline as TravelAdvisory
  final String summary;

  /// [summary] in the country's primary language — see
  /// [TravelAdvisory.summaryEs].
  final String? summaryEs;
  final String officialUrl; // required, never null — informational source
  final String? applicationUrl;
  final DateTime lastVerifiedAt; // required, never null
  final String nationalityIsoCode;
  final String? prohibitedOnEntry;
  final String? prohibitedOnExit;

  const VisaInfo({
    required this.issuingAuthority,
    required this.summary,
    this.summaryEs,
    required this.officialUrl,
    this.applicationUrl,
    required this.lastVerifiedAt,
    required this.nationalityIsoCode,
    this.prohibitedOnEntry,
    this.prohibitedOnExit,
  });

  factory VisaInfo.fromJson(Map<String, dynamic> json) {
    return VisaInfo(
      issuingAuthority: json['issuingAuthority'] as String,
      summary: json['summary'] as String,
      summaryEs: json['summaryEs'] as String?,
      officialUrl: json['officialUrl'] as String,
      applicationUrl: json['applicationUrl'] as String?,
      lastVerifiedAt: DateTime.parse(json['lastVerifiedAt'] as String),
      nationalityIsoCode: json['nationalityIsoCode'] as String,
      prohibitedOnEntry: json['prohibitedOnEntry'] as String?,
      prohibitedOnExit: json['prohibitedOnExit'] as String?,
    );
  }
}

class RegionalNote {
  final String groupSlug;
  final String noteType;
  final String summary;
  final String officialUrl;
  final DateTime lastVerifiedAt;

  const RegionalNote({
    required this.groupSlug,
    required this.noteType,
    required this.summary,
    required this.officialUrl,
    required this.lastVerifiedAt,
  });

  factory RegionalNote.fromJson(Map<String, dynamic> json) {
    return RegionalNote(
      groupSlug: json['groupSlug'] as String,
      noteType: json['noteType'] as String,
      summary: json['summary'] as String,
      officialUrl: json['officialUrl'] as String,
      lastVerifiedAt: DateTime.parse(json['lastVerifiedAt'] as String),
    );
  }
}
