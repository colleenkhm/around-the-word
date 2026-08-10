/// Builds a country's flag image URL from its ISO 3166-1 alpha-2 code.
///
/// **PNG, not SVG, despite `country_facts.flag_svg_url` in the schema.**
/// Confirmed 2026-08-10: both `flags.restcountries.com` and `flagcdn.com`
/// serve the same underlying flag-icons dataset, and both use CSS
/// `<style>` blocks for fill colors rather than presentation attributes
/// directly on each shape — `flutter_svg` (`vector_graphics_compiler`)
/// doesn't support that pattern and silently fails to render the colored
/// shapes. Writing a style-block-to-attributes SVG preprocessor felt like
/// the wrong amount of effort for a flag that only ever displays at
/// ~46–62px — PNG at 2–3x that width (`w160`) is plenty crisp and
/// sidesteps the problem entirely. Worth revisiting if a later screen
/// wants a large, genuinely-scaled flag where the raster/vector
/// difference would actually show.
///
/// Also, like the SVG endpoint, `flagcdn.com`'s PNGs are public and
/// keyless — still a pure function of the ISO code, no fetch-and-store
/// needed. See `lib/utils/flag_url.dart`'s SVG-era history in git for the
/// original reasoning on why this is derived client-side at all rather
/// than read from `country_facts.flag_svg_url`.
String flagPngUrl(String isoCode) =>
    'https://flagcdn.com/w160/${isoCode.toLowerCase()}.png';
