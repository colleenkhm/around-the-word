/// Builds a country's flag image URL from its ISO alpha-2 code. PNG, not
/// SVG — `flutter_svg` doesn't render flagcdn's CSS-styled shapes.
String flagPngUrl(String isoCode) =>
    'https://flagcdn.com/w160/${isoCode.toLowerCase()}.png';
