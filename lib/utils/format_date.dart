// Short date formatting, hand-rolled rather than pulling in `intl`.
const _monthAbbrev = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// 2026-07-01T00:00:00Z -> "Jul 1, 2026". No timezone conversion.
String formatShortDate(DateTime date) =>
    '${_monthAbbrev[date.month - 1]} ${date.day}, ${date.year}';
