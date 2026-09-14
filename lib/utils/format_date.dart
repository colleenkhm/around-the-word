// Short date formatting, hand-rolled rather than pulling in `intl`.
const _monthAbbrevEn = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

const _monthAbbrevEs = [
  'ene', 'feb', 'mar', 'abr', 'may', 'jun',
  'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
];

/// 2026-07-01T00:00:00Z -> "Jul 1, 2026", or "1 jul 2026" when [spanish]
/// (day-first, lowercase abbreviation, no comma — the conventional Spanish
/// short-date order, not just a swapped month list). No timezone
/// conversion. [spanish] defaults false so every call site outside the
/// country page's bilingual chrome is unaffected.
String formatShortDate(DateTime date, {bool spanish = false}) {
  if (spanish) {
    return '${date.day} ${_monthAbbrevEs[date.month - 1]} ${date.year}';
  }
  return '${_monthAbbrevEn[date.month - 1]} ${date.day}, ${date.year}';
}
