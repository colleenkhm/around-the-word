import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/country_bundle.dart';
import '../../models/live_data.dart';
import '../../theme/country_theme.dart';
import '../../utils/flag_url.dart';
import 'dashed_divider.dart';
import 'external_link.dart';

const _tabLabels = {
  CountryTab.overview: 'OVERVIEW',
  CountryTab.explore: 'EXPLORE',
  CountryTab.guide: 'GUIDE',
  CountryTab.language: 'LANGUAGE',
};

/// The country-page header/chrome: flag, name, native name, the
/// content_status pill, the tab-pill row, and a "ticket stub" with local
/// time + a $1 USD conversion.
///
/// **2026-08-15 rewrite**, built against `trip-dashboard-v3.html`. Two
/// pieces of the prior header are gone rather than reskinned, per Colleen
/// (asked directly rather than assumed — see HANDOFF.md):
/// - The country name no longer renders as [SplitFlapText]'s individual
///   flap cells — plain styled text now ([CountryTheme.countryName]),
///   matching the mockup's plainer `.tk-name`.
/// - The passport-style MRZ strip (ISO code, official name, advisory
///   level, verified date in bracket notation) is gone. Its `ADV:`/
///   `VERIFIED:` data has nowhere to land yet — the plan is for it to move
///   into the restyled Travel Info section (advisory bar + a shared source
///   line already live there), not to be dropped for good.
///
/// **[RightNowStrip] is retired, not reskinned** — its local-time and
/// currency columns are absorbed directly into this header's stub
/// (`_TicketStub`, mirroring the mockup's `.tk-stub`), and its season
/// column is dropped from the Overview tab entirely for this pass (per
/// Colleen: fold time+currency into the header, drop season from view).
/// That's why this widget is a [StatefulWidget] now — the local-time
/// column needs the same live-updating [Timer] [RightNowStrip] used to
/// have; see `_CountryHeaderState`.
///
/// **One known data gap, not yet fixed:** native name + its romanization
/// (the mockup's "Ελλάδα · Ellàda") isn't in `country_facts`/[CountryFacts]
/// at all yet — REST Countries returns the native-script name already, but
/// not a romanization, which would need to be curated. Both stay optional
/// constructor params here rather than pulled from the bundle, so this
/// renders correctly once that's decided without another widget change.
class CountryHeader extends StatefulWidget {
  final CountryBundle bundle;

  /// Which tabs to show as pills — driven by what's actually been built
  /// so far, not by [CountryBundle] content presence. See class doc.
  final List<CountryTab> tabs;
  final CountryTab activeTab;
  final ValueChanged<CountryTab> onTabSelected;
  final String? nativeName;
  final String? nativeNameRomanized;

  /// Feeds the stub's "Local time" column — see [CountryFacts.utcOffsetMinutes]'s
  /// doc comment on the fixed-offset/no-DST simplification this inherits
  /// unchanged from [RightNowStrip].
  final int? utcOffsetMinutes;

  /// Feeds the stub's "$1 USD" column. **Not live** — see [ExchangeRate]'s
  /// doc comment; `null` renders an em dash rather than inventing a value.
  final ExchangeRate? exchangeRate;

  /// From `CountryFacts.currencyName` — shown as the currency column's
  /// subtitle in place of a generic label.
  final String? currencyName;

  const CountryHeader({
    super.key,
    required this.bundle,
    required this.tabs,
    required this.activeTab,
    required this.onTabSelected,
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
    // plenty — carried over unchanged from the retired RightNowStrip.
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

    return Container(
      // Square corners, not rounded — matches the mockup's `.tk-head`/
      // `.tk-stub` (`border-radius: 0` in both), a deliberate flat-ticket
      // look rather than the prior rounded-bottom bar.
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(color: CountryTheme.navy),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TopStripe(),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.bundle.country.nameCommon,
                            style: CountryTheme.countryName(isDesktop ? 34 : 24)
                                .copyWith(color: CountryTheme.onNavy),
                          ),
                          if (widget.nativeName != null) ...[
                            const SizedBox(height: 6),
                            Text.rich(
                              TextSpan(
                                style: CountryTheme.ticketNativeName,
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
                    const SizedBox(width: 14),
                    _Flag(isoCode: widget.bundle.country.isoCode, desktop: isDesktop),
                  ],
                ),
                // Both the status pill and the tab-pill row are about
                // signaling unevenness *across tabs* — neither means
                // anything with a single tab built. Gated on tabs.length
                // > 1, same as before this rewrite.
                if (widget.bundle.country.contentStatus == ContentStatus.partial &&
                    widget.tabs.length > 1)
                  _StatusPill(countryName: widget.bundle.country.nameCommon),
                if (widget.tabs.length > 1) ...[
                  const SizedBox(height: 12),
                  _TabPillRow(
                    tabs: widget.tabs,
                    active: widget.activeTab,
                    onSelected: widget.onTabSelected,
                  ),
                ],
              ],
            ),
          ),
          _TicketStub(
            utcOffsetMinutes: widget.utcOffsetMinutes,
            exchangeRate: widget.exchangeRate,
            currencyName: widget.currencyName,
          ),
        ],
      ),
    );
  }
}

/// The `.tk-head::after` two-tone top stripe — gold for the first ~62%,
/// navyMid for the rest. A `Row` of two flex-weighted `ColoredBox`s reads
/// clearer than reaching for a `LinearGradient` with hard color stops for
/// what's really just two flat blocks side by side.
class _TopStripe extends StatelessWidget {
  const _TopStripe();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 4,
      child: Row(
        children: [
          Expanded(flex: 62, child: ColoredBox(color: CountryTheme.gold)),
          Expanded(flex: 38, child: ColoredBox(color: CountryTheme.navyMid)),
        ],
      ),
    );
  }
}

class _Flag extends StatelessWidget {
  final String isoCode;
  final bool desktop;

  const _Flag({required this.isoCode, required this.desktop});

  @override
  Widget build(BuildContext context) {
    final width = desktop ? 62.0 : 46.0;
    final height = desktop ? 42.0 : 32.0;
    final placeholder = ColoredBox(color: CountryTheme.onNavyMuted);

    return Container(
      width: width,
      height: height,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(3),
        // Translucent white, not `CountryTheme.rule` — this always sits
        // on the navy block now (the mockup's `.tk-flag` box-shadow is
        // `rgba(255,255,255,.15)`), never on a light card surface.
        border: Border.all(color: CountryTheme.onNavyMuted),
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

/// The content-depth signal (.pill in the mockup) — shown only when
/// `content_status = 'partial'`. `'complete'` gets no badge at all:
/// silence signals trust, per the client design doc's reasoning against
/// training users to read a "✓ Complete" label's *absence* as a warning.
class _StatusPill extends StatelessWidget {
  final String countryName;

  const _StatusPill({required this.countryName});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: CountryTheme.onNavyMuted.withValues(alpha: 0.12),
        border: Border.all(color: CountryTheme.onNavyMuted),
      ),
      child: Text(
        'Building out $countryName — some sections are further along than others',
        style: CountryTheme.pillLabel.copyWith(color: CountryTheme.onNavySoft),
      ),
    );
  }
}

class _TabPillRow extends StatelessWidget {
  final List<CountryTab> tabs;
  final CountryTab active;
  final ValueChanged<CountryTab> onSelected;

  const _TabPillRow({
    required this.tabs,
    required this.active,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final tab in tabs)
            _TabPill(
              label: _tabLabels[tab]!,
              selected: tab == active,
              onTap: () => onSelected(tab),
            ),
        ],
      ),
    );
  }
}

class _TabPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TabPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Selected fill is gold — dark navy text on top, the same pairing the
    // mockup's `.btn-gold` uses (light text on bright gold fails contrast).
    // Unselected stays translucent-outlined on the navy surface, same
    // family as `_StatusPill`.
    return Material(
      color: selected ? CountryTheme.gold : Colors.transparent,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? Colors.transparent : CountryTheme.onNavyMuted,
            ),
          ),
          child: Text(
            label,
            style: CountryTheme.pillLabel.copyWith(
              color: selected ? CountryTheme.navy : CountryTheme.onNavySoft,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

/// The ticket's light stub — local time + a $1 USD conversion, matching
/// `.tk-stub`. Absorbs what [RightNowStrip] used to render as its first
/// and third columns (see class doc on why the middle "season" column
/// isn't a fourth field here — it's dropped from view this pass, not
/// moved).
///
/// Time/currency formatting logic below is carried over verbatim from
/// [RightNowStrip] — same fixed-offset/no-DST simplification, same
/// significant-figures currency rounding, same xe.com outbound converter
/// link (not a live in-app rate fetch — see [ExchangeRate]'s doc comment).
class _TicketStub extends StatelessWidget {
  final int? utcOffsetMinutes;
  final ExchangeRate? exchangeRate;
  final String? currencyName;

  const _TicketStub({
    required this.utcOffsetMinutes,
    required this.exchangeRate,
    required this.currencyName,
  });

  @override
  Widget build(BuildContext context) {
    final local = _localDateTime();

    return Container(
      width: double.infinity,
      color: CountryTheme.card,
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const DashedDivider(),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
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
                          ),
                  ),
                ),
              ],
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
        Text(label, style: CountryTheme.ticketStubLabel),
        const SizedBox(height: 3),
        Text(value, style: CountryTheme.ticketStubValue),
        if (subtitle.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(subtitle, style: CountryTheme.ticketStubSub),
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
  /// makes. Distinct from the data architecture doc's "Currency
  /// conversion: ExchangeRate-API, live, never bundled" guidance, which is
  /// about this app *fetching* a rate server-side (not built yet) — this
  /// is just an outbound link, so it doesn't need an Edge Function or key.
  String _converterUrl(String currencyCode) =>
      'https://www.xe.com/currencyconverter/convert/?Amount=1&From=USD&To=$currencyCode';
}
