// Short date formatting, hand-rolled rather than pulling in `intl`.
const _monthAbbrev = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// "Jul 1, 2026", in the viewer's timezone. Date-only values (parsed as
/// local) pass through unchanged.
String formatShortDate(DateTime date) {
  final local = date.toLocal();
  return '${_monthAbbrev[local.month - 1]} ${local.day}, ${local.year}';
}
