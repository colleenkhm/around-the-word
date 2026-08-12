/// Short, human-readable date formatting shared by anything that shows a
/// `lastVerifiedAt`/`issuedAt`-style timestamp (advisories, visas) —
/// hand-rolled for the same reason as format_population.dart: one function
/// doesn't earn pulling in `intl`.
const _monthAbbrev = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// 2026-07-01T00:00:00Z -> "Jul 1, 2026". Uses the date's own fields as
/// stored, with no timezone conversion — verification dates are calendar
/// dates, not moments in time, so there's no "local" version to convert to.
String formatShortDate(DateTime date) =>
    '${_monthAbbrev[date.month - 1]} ${date.day}, ${date.year}';
