/// A generic (not country-specific) link shown on the coming-soon screen
/// for countries without content yet — see language-app-system-design.md
/// section 3 for why these are shared rather than curated per country.
class Resource {
  final String label;
  final String url;

  const Resource({required this.label, required this.url});

  factory Resource.fromJson(Map<String, dynamic> json) {
    return Resource(
      label: json['label'] as String,
      url: json['url'] as String,
    );
  }
}
