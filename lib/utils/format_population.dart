/// Thousands-grouped population display: 664046 -> "664,046". A tiny
/// hand-rolled formatter rather than pulling in `intl` for one function —
/// worth revisiting if a second locale-aware formatting need shows up.
String formatPopulation(int population) {
  final digits = population.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
    buffer.write(digits[i]);
  }
  return buffer.toString();
}
