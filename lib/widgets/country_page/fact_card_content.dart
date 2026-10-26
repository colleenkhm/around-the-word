import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_theme/shared_theme.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../models/live_data.dart';
import '../../models/travel_info.dart';
import 'external_link.dart';

/// Local Time card content: time, date, UTC offset, hemisphere.
class LocalTimeFacts extends StatefulWidget {
  /// IANA name — preferred, DST-aware.
  final String? timezone;

  /// Fallback when [timezone] is null.
  final int? utcOffsetMinutes;

  final double? latitude;

  /// Text color — the card's on-tint color.
  final Color ink;

  const LocalTimeFacts({
    super.key,
    required this.timezone,
    required this.utcOffsetMinutes,
    required this.latitude,
    required this.ink,
  });

  @override
  State<LocalTimeFacts> createState() => _LocalTimeFactsState();
}

class _LocalTimeFactsState extends State<LocalTimeFacts> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(
      const Duration(seconds: 30),
      (_) => setState(() {}),
    );
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final local = _localTime();
    final hemisphere = _hemisphereLabel();
    final sub = _subStyle(widget.ink);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _BigValue(
          local == null ? '—' : _timeLabel(local.wallClock),
          color: widget.ink,
        ),
        if (local != null) ...[
          const SizedBox(height: 2),
          Text(_dateLabel(local.wallClock), style: sub),
          Text(_utcLabel(local.utcOffset), style: sub),
        ],
        const Spacer(),
        if (hemisphere != null)
          Text(
            hemisphere,
            style: AccordionTheme.srcRow.copyWith(
              fontWeight: FontWeight.w600,
              color: widget.ink,
            ),
          ),
      ],
    );
  }

  ({DateTime wallClock, Duration utcOffset})? _localTime() {
    final tzName = widget.timezone;
    if (tzName != null) {
      try {
        final now = tz.TZDateTime.now(tz.getLocation(tzName));
        return (wallClock: now, utcOffset: now.timeZoneOffset);
      } catch (_) {
        // Unrecognized IANA name — fall through to the fixed offset.
      }
    }
    final offset = widget.utcOffsetMinutes;
    if (offset == null) return null;
    final duration = Duration(minutes: offset);
    return (
      wallClock: DateTime.now().toUtc().add(duration),
      utcOffset: duration,
    );
  }

  // North/South only; distinct label at 0.
  String? _hemisphereLabel() {
    final lat = widget.latitude;
    if (lat == null) return null;
    if (lat == 0) return 'On the Equator';
    return lat > 0 ? 'Northern Hemisphere' : 'Southern Hemisphere';
  }

  String _timeLabel(DateTime local) {
    final h = local.hour.toString().padLeft(2, '0');
    final m = local.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _dateLabel(DateTime local) =>
      '${_weekdayAbbrev[local.weekday - 1]}, ${_monthAbbrev[local.month - 1]} ${local.day}';

  String _utcLabel(Duration offset) {
    final totalMinutes = offset.inMinutes;
    final sign = totalMinutes >= 0 ? '+' : '-';
    final hours = (totalMinutes.abs() / 60).floor();
    final minutes = totalMinutes.abs() % 60;
    return minutes == 0
        ? 'UTC$sign$hours'
        : 'UTC$sign$hours:${minutes.toString().padLeft(2, '0')}';
  }

  static const _weekdayAbbrev = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  static const _monthAbbrev = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
}

/// Currency card content: today's USD rate plus a converter link.
class CurrencyFacts extends StatelessWidget {
  final ExchangeRate? rate;
  final String? currencyName;

  /// Text color — the card's on-tint color.
  final Color ink;

  const CurrencyFacts({
    super.key,
    required this.rate,
    required this.currencyName,
    required this.ink,
  });

  @override
  Widget build(BuildContext context) {
    final r = rate;
    final sub = _subStyle(ink);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(r'$1 USD =', style: sub),
        const SizedBox(height: 2),
        _BigValue(r == null ? '—' : _rateLabel(r), color: ink),
        const SizedBox(height: 2),
        Text(
          currencyName ?? 'Daily rate',
          style: sub,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const Spacer(),
        if (r != null)
          ExternalLink(
            label: 'Convert',
            url:
                'https://www.xe.com/currencyconverter/convert/?Amount=1&From=USD&To=${r.currencyCode}',
            color: ink,
            fontFamily: AccordionTheme.dmMono,
          ),
      ],
    );
  }

  // Four-figure rates read better with no decimal; sub-10 want two.
  String _rateLabel(ExchangeRate r) {
    final value = r.rateFromUsd;
    final formatted = value >= 100
        ? value.round().toString()
        : value.toStringAsFixed(2);
    return switch (r.currencyCode) {
      'EUR' => '€$formatted',
      'GBP' => '£$formatted',
      'CRC' => '₡$formatted',
      _ => '$formatted ${r.currencyCode}',
    };
  }
}

/// Travel Advisory card front: the level plus its label.
class AdvisoryLevelFacts extends StatelessWidget {
  final TravelAdvisory advisory;

  /// Text color — the card's on-tint color.
  final Color ink;

  const AdvisoryLevelFacts({
    super.key,
    required this.advisory,
    required this.ink,
  });

  @override
  Widget build(BuildContext context) {
    final level = advisory.levelNumber;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // White pill keeps the level's risk color legible on any flag tint.
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          decoration: BoxDecoration(
            color: AccordionTheme.white,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: AccordionTheme.ink, width: 1),
          ),
          child: _BigValue(
            level == null ? (advisory.level ?? '—') : 'Level $level',
            color: level == null
                ? AccordionTheme.ink
                : AccordionTheme.advisoryColor(level),
            fontSize: 24,
          ),
        ),
        if (advisory.levelLabel != null) ...[
          const SizedBox(height: 6),
          Text(
            advisory.levelLabel!,
            style: _subStyle(ink).copyWith(height: 1.3),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }
}

/// Travel Advisory card back: the start of the summary, plus "Read more".
class AdvisorySummaryBack extends StatelessWidget {
  final TravelAdvisory advisory;
  final Color accent;
  final VoidCallback onReadMore;

  const AdvisorySummaryBack({
    super.key,
    required this.advisory,
    required this.accent,
    required this.onReadMore,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            advisory.summary ??
                'See the full advisory from the ${advisory.issuingAuthority}.',
            style: AccordionTheme.sBody.copyWith(fontSize: 13, height: 1.4),
            overflow: TextOverflow.fade,
          ),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: onReadMore,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Read more',
                style: AccordionTheme.srcRow.copyWith(
                  fontWeight: FontWeight.w600,
                  color: accent,
                ),
              ),
              const SizedBox(width: 2),
              Icon(Icons.open_in_full, size: 11, color: accent),
            ],
          ),
        ),
      ],
    );
  }
}

TextStyle _subStyle(Color ink) =>
    AccordionTheme.tfSub.copyWith(color: ink.withValues(alpha: 0.75));

class _BigValue extends StatelessWidget {
  final String text;
  final Color color;
  final double fontSize;

  const _BigValue(
    this.text, {
    this.color = AccordionTheme.ink,
    this.fontSize = 30,
  });

  @override
  Widget build(BuildContext context) {
    // Scales down rather than wrapping on a narrow card.
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: AccordionTheme.tfVal.copyWith(fontSize: fontSize, color: color),
      ),
    );
  }
}
