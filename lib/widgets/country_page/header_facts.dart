import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_theme/shared_theme.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../models/live_data.dart';
import 'external_link.dart';

/// Masthead local time: time, date, UTC offset, hemisphere.
class LocalTimeFacts extends StatefulWidget {
  /// IANA name — preferred, DST-aware.
  final String? timezone;

  /// Fallback when [timezone] is null.
  final int? utcOffsetMinutes;

  final double? latitude;

  /// Text color — the masthead's on-tint color.
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
    return _HeaderFact(
      label: 'LOCAL TIME',
      value: local == null ? '—' : _timeLabel(local.wallClock),
      ink: widget.ink,
      details: [
        if (local != null)
          Text(
            '${_dateLabel(local.wallClock)} · ${_utcLabel(local.utcOffset)}',
            style: sub,
          ),
        if (hemisphere != null) Text(hemisphere, style: sub),
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

/// Masthead currency: today's USD rate plus a converter link.
class CurrencyFacts extends StatelessWidget {
  final ExchangeRate? rate;
  final String? currencyName;

  /// Text color — the masthead's on-tint color.
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
    return _HeaderFact(
      label: r'$1 USD =',
      value: r == null ? '—' : _rateLabel(r),
      ink: ink,
      details: [
        Text(currencyName ?? 'Daily rate', style: _subStyle(ink)),
        if (r != null) ...[
          const SizedBox(height: 4),
          ExternalLink(
            label: 'Convert',
            url:
                'https://www.xe.com/currencyconverter/convert/?Amount=1&From=USD&To=${r.currencyCode}',
            color: ink,
            fontFamily: AccordionTheme.dmMono,
          ),
        ],
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

TextStyle _subStyle(Color ink) =>
    AccordionTheme.tfSub.copyWith(color: ink.withValues(alpha: 0.75));

/// Label, big value, then detail lines.
class _HeaderFact extends StatelessWidget {
  final String label;
  final String value;
  final Color ink;
  final List<Widget> details;

  const _HeaderFact({
    required this.label,
    required this.value,
    required this.ink,
    required this.details,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AccordionTheme.tfLabel.copyWith(
            color: ink.withValues(alpha: 0.55),
          ),
        ),
        const SizedBox(height: 4),
        Text(value, style: AccordionTheme.tfVal.copyWith(color: ink)),
        const SizedBox(height: 2),
        ...details,
      ],
    );
  }
}
