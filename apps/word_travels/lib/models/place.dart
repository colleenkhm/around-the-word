/// Where the user is using the language: a country, plus any tags they've
/// switched off for this trip. Decides which phrases they see.
class Place {
  final String? country;

  /// Tags muted for this trip. Empty — the default — means nothing is muted,
  /// so every phrase applies.
  ///
  /// This is the inverse of the old "pick the settings you'll be in": a new
  /// trip starts with the whole phrasebook switched on and the user turns
  /// off what won't come up, so skipping the question gives them everything
  /// rather than nothing.
  final Set<String> mutedTags;

  const Place(this.country, [this.mutedTags = const {}]);
}

/// A kind of setting a trip can involve, with a short hint shown under its
/// name and the activities that only come up there.
///
/// Settings and activities are two halves of one flat tag vocabulary: a surf
/// phrase is tagged `'Surfing'` alone, never `'Surfing'` *and* `'Coastal'`,
/// because a setting never independently gates its own activities. The
/// nesting exists for the trip settings UI — muting a setting mutes its
/// activities with it, and each can then be switched back on by itself
/// (muting Coastal but keeping Surfing is a legal, meaningful state).
class EnvironmentOption {
  final String name;
  final String description;
  final List<String> activities;

  const EnvironmentOption(
    this.name,
    this.description, {
    this.activities = const [],
  });
}
