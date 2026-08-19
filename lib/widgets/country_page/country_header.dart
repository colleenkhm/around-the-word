import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/country_bundle.dart';
import '../../models/live_data.dart';
import '../../theme/accordion_theme.dart';
import '../../theme/section_palette.dart';
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

  /// This country's "primary" section colors (shared with Visa & Entry,
  /// the first section) — 2026-08-18, colors the stub's background/links
  /// instead of the fixed `AccordionTheme.sky`/`skyDark`. See
  /// [SectionPalette]'s class doc.
  final SectionColors accent;

  /// The dark masthead block's own colors — `SectionPalette.header`, a
  /// **deepened** version of [accent]'s color, not the same value.
  /// Deliberately a second, separate field rather than reusing [accent]
  /// for both — the masthead (name/flag) wants a dark, weighty surface
  /// for hierarchy/contrast at the top of the page, while the stub right
  /// below it wants the section's actual (toned-down but still light)
  /// color; collapsing them into one field would force one or the other
  /// to compromise. See [SectionPalette.header]'s doc comment.
  final SectionColors header;

  /// The ticket stub's own background — `SectionPalette.stub`, a
  /// **midtone** distinct from both [header] and [accent] so the stub
  /// doesn't visually merge into the Visa & Entry row directly below it
  /// (which uses [accent]'s exact tint). See [SectionPalette.stub].
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
    // Minute-granularity display, so a timer tick once every 30s is
    // plenty — carried over unchanged from the prior version.
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
    // A translucent version of the header's own text color, not a fixed
    // white — see [SectionPalette.header]'s doc comment on why this
    // block is no longer flat `AccordionTheme.ink`.
    final onHeaderSoft = header.textColor.withValues(alpha: 0.55);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          color: header.tint,
          // Top 18->10->6, 2026-08-19, per Colleen: the first cut still
          // "looks like a lot of space between site nav and destination"
          // — the rest of that gap was SiteHeader's own bottom padding
          // (16->10, see that file), not just this one.
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 16),
          child: Stack(
            children: [
              Padding(
                // Leaves room on the right for the flag, positioned
                // absolutely — matches the mockup's `.tk-flag` overlay
                // rather than sharing a Row (so the flag doesn't push the
                // name to wrap early on a long country name). Widened
                // alongside the flag's own bigger size, same ~24-26px
                // margin as before.
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
                    // 6->12, 2026-08-19, per Colleen: "increase space
                    // between destination and destination name."
                    const SizedBox(height: 12),
                    Text(
                      widget.bundle.country.nameCommon,
                      style: AccordionTheme.tkName(
                        isDesktop ? 50 : 36,
                      ).copyWith(color: header.textColor),
                    ),
                    if (widget.nativeName != null) ...[
                      // Matches the 12px gap above the name (DESTINATION
                      // -> name), 2026-08-19, per Colleen: "make sure the
                      // gap between destination name and the secondary
                      // name below is as big as the gap between
                      // 'destination' and destination name."
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
              // top/bottom: 0 (not just top: 0) + an inner Center — per
              // Colleen, 2026-08-18: "vertically center it within its
              // section" — stretches this Positioned across the full
              // masthead height instead of pinning the flag to the top
              // edge, so Center actually has room to center within.
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
    // Bumped from 52x36/38x26, then again from 60x41/44x30, 2026-08-18,
    // per Colleen: "make the flag a bit bigger" (asked twice).
    final imageWidth = desktop ? 68.0 : 50.0;
    final imageHeight = desktop ? 46.0 : 34.0;
    // A real white mat around the image, matching this app's existing
    // passport/ticket-stamp motif (see HANDOFF.md's rotated-stamp corner
    // mark on Visa/Advisory content).
    const matPadding = 3.0;
    // The perforated edge — per Colleen, 2026-08-19, clarifying what
    // "stamp-like border" meant: "more like one of those borders with
    // the tiny triangles like how stamps get perforated," not the plain
    // rounded mat this had first. See [_StampEdgePainter].
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

/// Paints a filled white shape tracing [matRect]'s perimeter but with a
/// zigzag of small outward-pointing triangles instead of a straight edge
/// on all four sides — a postage-stamp perforation, not a plain border.
/// The flag image itself sits on top, sized to fit *inside* [matRect]'s
/// straight-edged inset, so the zigzag only ever shows as a decorative
/// margin around it, never clipping into the image.
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

  /// Walks [start] to [end] in [toothSize]-length steps, alternating each
  /// step's endpoint between the straight baseline and a point pushed out
  /// by [toothSize] along [outward] — the up/down alternation is what
  /// forms the triangle teeth.
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

/// The ticket's stub — local time + a $1 USD conversion (`.tk-stub`), plus
/// the expand/collapse-all pill. Dashed top border simulated via
/// [DashedDivider] since Flutter has no native dashed-border support.
///
/// **2026-08-18: background is [stub], not [accent]'s tint** — per
/// Colleen, the stub sitting directly above the Visa & Entry row in the
/// identical color made the seam between them disappear. [accent] is
/// still used for the expand/collapse pill's text (readable-on-white,
/// ties it to the page's primary hue) since the pill itself is white now,
/// not colored by whatever background sits behind it.
class _TicketStub extends StatelessWidget {
  final int? utcOffsetMinutes;
  final ExchangeRate? exchangeRate;
  final String? currencyName;
  final bool allExpanded;
  final VoidCallback onToggleAll;
  final SectionColors accent;
  final SectionColors stub;

  /// Feeds the "LOCAL TIME" column's own trailing line — see
  /// [_hemisphereLabel]. From [CountryFacts.latitude]; `null` renders
  /// nothing rather than guessing.
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
            // Top/bottom evened up (14/12 -> 13/13), 2026-08-19, per
            // Colleen: "the padding around the overall local time/
            // currency section info" read top-heavy.
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
                    // Lines up with currency's own trailing "Convert"
                    // link — per Colleen, 2026-08-19: "add the country's
                    // hemisphere underneath the time/in line with the
                    // bottom row of currency."
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
          // A flush, square-cornered white strip — not a centered pill —
          // per Colleen, 2026-08-18: a floating rounded pill read like it
          // belonged to the stub it sat inside, when what it actually
          // controls is every section *below* it. Two cues now point at
          // that instead: no bottom padding/border, so this touches the
          // Visa & Entry row directly (the same "color change is the
          // seam, no divider" language every accordion row already uses
          // — see AccordionSection's doc comment); and the label sits
          // right-aligned with a chevron-style arrow, landing in the same
          // horizontal spot as every section row's own chevron circle
          // below it, so the two read as one repeated column of controls
          // rather than two unrelated pieces.
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

  /// North/South only — "hemisphere" on its own conventionally means this
  /// axis, not the East/West split [longitude] would give. `null` for a
  /// missing [latitude] rather than a guess; a country dead on the
  /// equator gets its own label instead of forcing it into either side.
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
    // Costa Rica-style four-figure rates read better with no decimal;
    // sub-10 rates (EUR-style) want two. A single significant-figures
    // rule rather than hardcoding per currency.
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

  /// A live, interactive USD-to-[currencyCode] calculator on xe.com — a
  /// public webpage the user opens themselves, not an API call this app
  /// makes. See the data architecture doc's "Currency conversion:
  /// ExchangeRate-API, live, never bundled" guidance — that's about this
  /// app *fetching* a rate server-side (not built yet); this is just an
  /// outbound link, so it doesn't need an Edge Function or key.
  String _converterUrl(String currencyCode) =>
      'https://www.xe.com/currencyconverter/convert/?Amount=1&From=USD&To=$currencyCode';
}
