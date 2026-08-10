import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/country_guide.dart';
import '../../models/live_data.dart';
import '../../theme/country_theme.dart';

/// The Overview tab's "Right now" section — local time, season, currency
/// conversion, three columns matching the mockup's .live strip.
///
/// **Local time is genuinely live** (a real ticking clock computed from
/// [utcOffsetMinutes], not mock data — see [CountryFacts.utcOffsetMinutes]'s
/// doc comment on the fixed-offset/no-DST simplification). **Currency is
/// not** — `null`-safe specifically because there's no live fetch yet; a
/// caller with nothing to show should pass `null` rather than inventing a
/// value, and the column renders an em dash in that case rather than a
/// misleading blank.
///
/// **Season, not weather** (changed 2026-08-10) — a single country-wide
/// weather reading misrepresents places with real regional climate
/// variation (see [Season]'s doc comment). [season] comes from
/// [CountryGuide.seasonFor] — resolved by the caller, since that needs
/// today's date in the country's own local time, which this widget
/// shouldn't have to know how to compute twice.
class RightNowStrip extends StatefulWidget {
  final int? utcOffsetMinutes;
  final Season? season;
  final ExchangeRate? exchangeRate;

  /// From `CountryFacts.currencyName` (e.g. "Costa Rican Colón") — shown
  /// as the currency column's subtitle in place of a generic "Daily rate"
  /// label, since knowing *what currency* is more useful at a glance than
  /// being told the rate updates daily.
  final String? currencyName;

  const RightNowStrip({
    super.key,
    required this.utcOffsetMinutes,
    this.season,
    this.exchangeRate,
    this.currencyName,
  });

  @override
  State<RightNowStrip> createState() => _RightNowStripState();
}

class _RightNowStripState extends State<RightNowStrip> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    // Minute-granularity display (matches the mockup), so a timer tick
    // once a minute is plenty — no need to rebuild every second for a
    // clock nobody's watching second-by-second.
    _ticker = Timer.periodic(const Duration(seconds: 30), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: CountryTheme.rule),
        borderRadius: BorderRadius.circular(10),
        color: CountryTheme.card,
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(child: _column('LOCAL TIME', _localTime(), _utcLabel())),
            _divider(),
            Expanded(
              child: _column(
                'SEASON',
                widget.season?.label ?? '—',
                widget.season == null ? '' : _monthRange(widget.season!),
              ),
            ),
            _divider(),
            Expanded(
              child: _column(
                '\$1 USD',
                widget.exchangeRate == null ? '—' : _rateLabel(widget.exchangeRate!),
                widget.currencyName ?? 'Daily rate',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _divider() => Container(width: 1, color: CountryTheme.rule);

  Widget _column(String label, String value, String subtitle) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: CountryTheme.liveLabel),
          const SizedBox(height: 4),
          Text(value, style: CountryTheme.liveValue),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 1),
            Text(subtitle, style: CountryTheme.liveSubtitle),
          ],
        ],
      ),
    );
  }

  String _localTime() {
    final offset = widget.utcOffsetMinutes;
    if (offset == null) return '—';
    final local = DateTime.now().toUtc().add(Duration(minutes: offset));
    final h = local.hour.toString().padLeft(2, '0');
    final m = local.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _utcLabel() {
    final offset = widget.utcOffsetMinutes;
    if (offset == null) return '';
    final sign = offset >= 0 ? '+' : '-';
    final hours = (offset.abs() / 60).floor();
    final minutes = offset.abs() % 60;
    return minutes == 0 ? 'UTC$sign$hours' : 'UTC$sign$hours:${minutes.toString().padLeft(2, '0')}';
  }

  static const _monthAbbrev = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  String _monthRange(Season season) =>
      '${_monthAbbrev[season.startMonth - 1]}–${_monthAbbrev[season.endMonth - 1]}';

  String _rateLabel(ExchangeRate r) {
    // Costa Rica-style four-figure rates read better with no decimal;
    // sub-10 rates (EUR-style) want two. A single significant-figures
    // rule rather than hardcoding per currency.
    final rate = r.rateFromUsd;
    final formatted = rate >= 100 ? rate.round().toString() : rate.toStringAsFixed(2);
    return _currencySymbol(r.currencyCode) + formatted;
  }

  String _currencySymbol(String code) => switch (code) {
        'EUR' => '€',
        'GBP' => '£',
        'CRC' => '₡',
        _ => '$code ',
      };
}
