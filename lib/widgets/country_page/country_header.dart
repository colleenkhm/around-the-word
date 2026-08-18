import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/country_bundle.dart';
import '../../models/live_data.dart';
import '../../theme/accordion_theme.dart';
import '../../utils/flag_url.dart';
import 'dashed_divider.dart';
import 'external_link.dart';

/// The country-page ticket header: flag, name, native name, and a "ticket
/// stub" with local time + a $1 USD conversion, plus an "Expand all info" /
/// "Collapse all info" link controlling every [AccordionSection] below it.
///
/// **2026-08-18 rewrite**, built against `trip-dashboard-v5.html`'s two
/// frames (collapsed vs. expanded) — replaces the 2026-08-15 navy/gold
/// "boarding pass" version (see [AccordionTheme]'s class doc on why this
/// repoints to a parallel token set instead of [CountryTheme]). Structure
/// carries over (`_TicketStub`'s two-column local-time/currency layout,
/// the live-updating [Timer]) since the mockup keeps that part
/// unchanged; what's new is the dark surface recoloring to
/// [AccordionTheme.ink] (from navy), the "DESTINATION" eyebrow label
/// (`.tk-eyebrow`, wasn't rendered before), and the expand/collapse-all
/// link row — the top gold/navyMid stripe is dropped, since the v5
/// mockup doesn't have one.
class CountryHeader extends StatefulWidget {
  final CountryBundle bundle;
  final String? nativeName;
  final String? nativeNameRomanized;

  /// Feeds the stub's "Local time" column — see [CountryFacts.utcOffsetMinutes]'s
  /// doc comment on the fixed-offset/no-DST simplification this inherits
  /// unchanged from the prior version.
  final int? utcOffsetMinutes;

  /// Feeds the stub's "$1 USD" column. **Not live** — see [ExchangeRate]'s
  /// doc comment; `null` renders an em dash rather than inventing a value.
  final ExchangeRate? exchangeRate;

  /// From `CountryFacts.currencyName` — shown as the currency column's
  /// subtitle in place of a generic label.
  final String? currencyName;

  /// True when every [AccordionSection] below is currently open — drives
  /// the link row's label ("Expand all info ↓" vs. "Collapse all info ↑").
  final bool allExpanded;
  final VoidCallback onToggleAll;

  const CountryHeader({
    super.key,
    required this.bundle,
    required this.allExpanded,
    required this.onToggleAll,
    this.nativeName,
    this.nativeNameRomanized,
    this.utcOffsetMinutes,
    this.exchangeRate,
    this.currencyName,
  });

  @override
  State<CountryHeader> createState() => _CountryHeaderState();
}

class _CountryHeaderState extends State<CountryHeader> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    // Minute-granularity display, so a timer tick once every 30s is
    // plenty — carried over unchanged from the prior version.
    _ticker = Timer.periodic(const Duration(seconds: 30), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width >= 900;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          color: AccordionTheme.ink,
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
          child: Stack(
            children: [
              Padding(
                // Leaves room on the right for the flag, positioned
                // absolutely — matches the mockup's `.tk-flag` overlay
                // rather than sharing a Row (so the flag doesn't push the
                // name to wrap early on a long country name).
                padding: EdgeInsets.only(right: isDesktop ? 78 : 62),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('DESTINATION', style: AccordionTheme.tkEyebrow),
                    const SizedBox(height: 6),
                    Text(
                      widget.bundle.country.nameCommon,
                      style: AccordionTheme.tkName(isDesktop ? 48 : 34),
                    ),
                    if (widget.nativeName != null) ...[
                      const SizedBox(height: 4),
                      Text.rich(
                        TextSpan(
                          style: AccordionTheme.tkNative,
                          children: [
                            TextSpan(text: widget.nativeName),
                            if (widget.nativeNameRomanized != null) ...[
                              const TextSpan(text: '   ·   '),
                              TextSpan(text: widget.nativeNameRomanized),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Positioned(
                top: 0,
                right: 0,
                child: _Flag(isoCode: widget.bundle.country.isoCode, desktop: isDesktop),
              ),
            ],
          ),
        ),
        _TicketStub(
          utcOffsetMinutes: widget.utcOffsetMinutes,
          exchangeRate: widget.exchangeRate,
          currencyName: widget.currencyName,
          allExpanded: widget.allExpanded,
          onToggleAll: widget.onToggleAll,
        ),
      ],
    );
  }
}

class _Flag extends StatelessWidget {
  final String isoCode;
  final bool desktop;

  const _Flag({required this.isoCode, required this.desktop});

  @override
  Widget build(BuildContext context) {
    final width = desktop ? 52.0 : 38.0;
    final height = desktop ? 36.0 : 26.0;
    final placeholder = ColoredBox(color: Colors.white.withValues(alpha: 0.15));

    return Container(
      width: width,
      height: height,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Image.network(
        flagPngUrl(isoCode),
        width: width,
        height: height,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) =>
            progress == null ? child : placeholder,
        errorBuilder: (context, error, stackTrace) {
          debugPrint('Flag fetch failed for $isoCode: $error');
          return placeholder;
        },
      ),
    );
  }
}

/// The ticket's stub — local time + a $1 USD conversion (`.tk-stub`), plus
/// the expand/collapse-all link (`.tk-stub`'s bottom row in the mockup).
/// Sky background, dashed top border simulated via [DashedDivider] since
/// Flutter has no native dashed-border support.
class _TicketStub extends StatelessWidget {
  final int? utcOffsetMinutes;
  final ExchangeRate? exchangeRate;
  final String? currencyName;
  final bool allExpanded;
  final VoidCallback onToggleAll;

  const _TicketStub({
    required this.utcOffsetMinutes,
    required this.exchangeRate,
    required this.currencyName,
    required this.allExpanded,
    required this.onToggleAll,
  });

  @override
  Widget build(BuildContext context) {
    final local = _localDateTime();

    return Container(
      width: double.infinity,
      color: AccordionTheme.sky,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          DashedDivider(color: AccordionTheme.skyDark.withValues(alpha: 0.3), strokeWidth: 1.5),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _field(
                    'LOCAL TIME',
                    local == null ? '—' : _timeLabel(local),
                    local == null ? '' : '${_dateLabel(local)} · ${_utcLabel()}',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _field(
                    r'$1 USD',
                    exchangeRate == null ? '—' : _rateLabel(exchangeRate!),
                    currencyName ?? 'Daily rate',
                    trailing: exchangeRate == null
                        ? null
                        : ExternalLink(
                            label: 'Convert',
                            url: _converterUrl(exchangeRate!.currencyCode),
                            color: AccordionTheme.skyDark,
                            fontFamily: AccordionTheme.dmMono,
                          ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: AccordionTheme.skyDark.withValues(alpha: 0.2))),
            ),
            child: InkWell(
              onTap: onToggleAll,
              child: Center(
                child: Text(
                  allExpanded ? 'Collapse all info ↑' : 'Expand all info ↓',
                  style: AccordionTheme.tfLink,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(String label, String value, String subtitle, {Widget? trailing}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: AccordionTheme.tfLabel),
        const SizedBox(height: 3),
        Text(value, style: AccordionTheme.tfVal),
        if (subtitle.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(subtitle, style: AccordionTheme.tfSub),
        ],
        if (trailing != null) ...[
          const SizedBox(height: 4),
          trailing,
        ],
      ],
    );
  }

  DateTime? _localDateTime() {
    final offset = utcOffsetMinutes;
    if (offset == null) return null;
    return DateTime.now().toUtc().add(Duration(minutes: offset));
  }

  String _timeLabel(DateTime local) {
    final h = local.hour.toString().padLeft(2, '0');
    final m = local.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _dateLabel(DateTime local) => '${_monthAbbrev[local.month - 1]} ${local.day}';

  String _utcLabel() {
    final offset = utcOffsetMinutes;
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

  /// A live, interactive USD-to-[currencyCode] calculator on xe.com — a
  /// public webpage the user opens themselves, not an API call this app
  /// makes. See the data architecture doc's "Currency conversion:
  /// ExchangeRate-API, live, never bundled" guidance — that's about this
  /// app *fetching* a rate server-side (not built yet); this is just an
  /// outbound link, so it doesn't need an Edge Function or key.
  String _converterUrl(String currencyCode) =>
      'https://www.xe.com/currencyconverter/convert/?Amount=1&From=USD&To=$currencyCode';
}
