/// Where the user is using the language: a country, plus the kinds of setting
/// they'll be in there (urban, coastal, ...). Decides which phrases they see.
class Place {
  final String? country;
  final Set<String> environments;

  const Place(this.country, [this.environments = const {}]);
}

/// A selectable kind of setting, with a short hint shown under its name.
class EnvironmentOption {
  final String name;
  final String description;

  const EnvironmentOption(this.name, this.description);
}
