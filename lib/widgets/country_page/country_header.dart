import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/country_bundle.dart';
import '../../models/live_data.dart';
import '../../theme/accordion_theme.dart';
import '../../theme/section_palette.dart';
import '../../utils/flag_url.dart';
import 'dashed_divider.dart';
import 'external_link.dart';

/// Country-page ticket header: flag, name, native name, ticket stub, and
/// expand/collapse-all link.
class CountryHeader extends StatefulWidget {
  final CountryBundle bundle;
  final String? nativeName;
  final String? nativeNameRomanized;

  /// Feeds the stub's local-time column.
  final int? utcOffsetMinutes;

  /// Feeds the stub's currency column. Not live.
  final ExchangeRate? exchangeRate;

  final String? currencyName;

  /// True when every section below is open.
  final bool allExpanded;
  final VoidCallback onToggleAll;

  /// This country's primary section colors.
  final SectionColors accent;

  /// Masthead's own colors — deepened version of [accent].
  final SectionColors header;

  /// Ticket stub's own background — midtone, distinct from [header]/[accent].
  final SectionColors stub;

  const CountryHeader({
    super.key,
    required this.bundle,
    required this.allExpanded,
    required this.onToggleAll,
    required this.accent,
    required this.header,
    required this.stub,
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
    final isDesktop = MediaQuery.sizeOf(context).width >= 900;
    final header = widget.header;
    final onHeaderSoft = header.textColor.withValues(alpha: 0.55);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          color: header.tint,
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 16),
          child: Stack(
            children: [
              Padding(
                // Room for the flag, positioned absolutely.
                padding: EdgeInsets.only(right: isDesktop ? 94 : 74),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'DESTINATION',
                      style: AccordionTheme.tkEyebrow.copyWith(
                        color: onHeaderSoft,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.bundle.country.nameCommon,
                      style: AccordionTheme.tkName(
                        isDesktop ? 50 : 36,
                      ).copyWith(color: header.textColor),
                    ),
                    if (widget.nativeName != null) ...[
                      const SizedBox(height: 12),
                      Text.rich(
                        TextSpan(
                          style: AccordionTheme.tkNative.copyWith(
                            color: onHeaderSoft,
                          ),
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
              // Stretched top/bottom so Center has room to work with.
              Positioned(
                top: 0,
                right: 0,
                bottom: 0,
                child: Center(
                  child: _Flag(
                    isoCode: widget.bundle.country.isoCode,
                    desktop: isDesktop,
                  ),
                ),
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
          accent: widget.accent,
          stub: widget.stub,
          latitude: widget.bundle.facts.latitude,
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
    final imageWidth = desktop ? 68.0 : 50.0;
    final imageHeight = desktop ? 46.0 : 34.0;
    // White mat around the image (postage-stamp motif).
    const matPadding = 3.0;
    // Perforated-edge tooth size.
    const toothSize = 3.0;
    final matWidth = imageWidth + matPadding * 2;
    final matHeight = imageHeight + matPadding * 2;
    final totalWidth = matWidth + toothSize * 2;
    final totalHeight = matHeight + toothSize * 2;
    final placeholder = ColoredBox(color: Colors.white.withValues(alpha: 0.15));

    return SizedBox(
      width: totalWidth,
      height: totalHeight,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(totalWidth, totalHeight),
            painter: _StampEdgePainter(
              matRect: Rect.fromLTWH(toothSize, toothSize, matWidth, matHeight),
              toothSize: toothSize,
              color: Colors.white,
            ),
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(1.5),
            child: Image.network(
              flagPngUrl(isoCode),
              width: imageWidth,
              height: imageHeight,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, progress) =>
                  progress == null ? child : placeholder,
              errorBuilder: (context, error, stackTrace) {
                debugPrint('Flag fetch failed for $isoCode: $error');
                return placeholder;
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Paints a white postage-stamp perforated edge around [matRect].
class _StampEdgePainter extends CustomPainter {
  final Rect matRect;
  final double toothSize;
  final Color color;

  const _StampEdgePainter({
    required this.matRect,
    required this.toothSize,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()..moveTo(matRect.left, matRect.top);
    _zigzagTo(path, matRect.topLeft, matRect.topRight, const Offset(0, -1));
    _zigzagTo(path, matRect.topRight, matRect.bottomRight, const Offset(1, 0));
    _zigzagTo(
      path,
      matRect.bottomRight,
      matRect.bottomLeft,
      const Offset(0, 1),
    );
    _zigzagTo(path, matRect.bottomLeft, matRect.topLeft, const Offset(-1, 0));
    path.close();

    canvas.drawShadow(path, Colors.black.withValues(alpha: 0.35), 1.2, false);
    canvas.drawPath(path, Paint()..color = color);
  }

  // Alternates baseline/outward points to form triangle teeth.
  void _zigzagTo(Path path, Offset start, Offset end, Offset outward) {
    final delta = end - start;
    final length = delta.distance;
    final steps = (length / toothSize).round().clamp(2, 200);
    final dir = Offset(delta.dx / length, delta.dy / length);
    final stepLength = length / steps;
    for (var i = 1; i <= steps; i++) {
      final base = start + dir * (stepLength * i);
      final point = i.isOdd ? base + outward * toothSize : base;
      path.lineTo(point.dx, point.dy);
    }
  }

  @override
  bool shouldRepaint(covariant _StampEdgePainter oldDelegate) =>
      oldDelegate.matRect != matRect ||
      oldDelegate.toothSize != toothSize ||
      oldDelegate.color != color;
}

/// Ticket stub — local time + currency + expand/collapse-all link.
class _TicketStub extends StatelessWidget {
  final int? utcOffsetMinutes;
  final ExchangeRate? exchangeRate;
  final String? currencyName;
  final bool allExpanded;
  final VoidCallback onToggleAll;
  final SectionColors accent;
  final SectionColors stub;

  /// Feeds the local-time column's trailing hemisphere line.
  final double? latitude;

  const _TicketStub({
    required this.utcOffsetMinutes,
    required this.exchangeRate,
    required this.currencyName,
    required this.allExpanded,
    required this.onToggleAll,
    required this.accent,
    required this.stub,
    required this.latitude,
  });

  @override
  Widget build(BuildContext context) {
    final local = _localDateTime();

    return Container(
      width: double.infinity,
      color: stub.tint,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          DashedDivider(
            color: stub.textColor.withValues(alpha: 0.3),
            strokeWidth: 1.5,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 13, 20, 13),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _field(
                    'LOCAL TIME',
                    local == null ? '—' : _timeLabel(local),
                    local == null
                        ? ''
                        : '${_dateLabel(local)} · ${_utcLabel()}',
                    trailing: _hemisphereLabel() == null
                        ? null
                        : Text(
                            _hemisphereLabel()!,
                            style: TextStyle(
                              fontFamily: AccordionTheme.dmMono,
                              fontWeight: FontWeight.w600,
                              fontSize: 11.5,
                              color: stub.textColor.withValues(alpha: 0.75),
                            ),
                          ),
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
                            color: stub.textColor,
                            fontFamily: AccordionTheme.dmMono,
                          ),
                  ),
                ),
              ],
            ),
          ),
          // Flush white strip, right-aligned to match the chevrons below.
          Material(
            color: AccordionTheme.white,
            child: InkWell(
              onTap: onToggleAll,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      allExpanded ? 'Collapse all info' : 'Expand all info',
                      style: AccordionTheme.tfLink.copyWith(
                        color: accent.accentOnWhite,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      allExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      size: 18,
                      color: accent.accentOnWhite,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(
    String label,
    String value,
    String subtitle, {
    Widget? trailing,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: AccordionTheme.tfLabel.copyWith(
            color: stub.textColor.withValues(alpha: 0.75),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: AccordionTheme.tfVal.copyWith(color: stub.textColor),
        ),
        if (subtitle.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: AccordionTheme.tfSub.copyWith(
              color: stub.textColor.withValues(alpha: 0.75),
            ),
          ),
        ],
        if (trailing != null) ...[const SizedBox(height: 4), trailing],
      ],
    );
  }

  DateTime? _localDateTime() {
    final offset = utcOffsetMinutes;
    if (offset == null) return null;
    return DateTime.now().toUtc().add(Duration(minutes: offset));
  }

  // North/South only; null for missing latitude, distinct label at 0.
  String? _hemisphereLabel() {
    final lat = latitude;
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
      '${_monthAbbrev[local.month - 1]} ${local.day}';

  String _utcLabel() {
    final offset = utcOffsetMinutes;
    if (offset == null) return '';
    final sign = offset >= 0 ? '+' : '-';
    final hours = (offset.abs() / 60).floor();
    final minutes = offset.abs() % 60;
    return minutes == 0
        ? 'UTC$sign$hours'
        : 'UTC$sign$hours:${minutes.toString().padLeft(2, '0')}';
  }

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

  String _rateLabel(ExchangeRate r) {
    // Four-figure rates read better with no decimal; sub-10 want two.
    final rate = r.rateFromUsd;
    final formatted = rate >= 100
        ? rate.round().toString()
        : rate.toStringAsFixed(2);
    return _currencySymbol(r.currencyCode) + formatted;
  }

  String _currencySymbol(String code) => switch (code) {
    'EUR' => '€',
    'GBP' => '£',
    'CRC' => '₡',
    _ => '$code ',
  };

  // Outbound link to a public converter, not an API call.
  String _converterUrl(String currencyCode) =>
      'https://www.xe.com/currencyconverter/convert/?Amount=1&From=USD&To=$currencyCode';
}
