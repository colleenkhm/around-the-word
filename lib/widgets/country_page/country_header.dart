import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/country_bundle.dart';
import '../../models/live_data.dart';
import '../../theme/country_theme.dart';
import '../../utils/flag_url.dart';
import 'dashed_divider.dart';
import 'external_link.dart';

/// The country-page header/chrome: flag, name, native name, and a "ticket
/// stub" with local time + a $1 USD conversion.
///
/// **The content_status pill and tab-pill row are gone for now**
/// (2026-08-17, per Colleen — "we're not displaying them... go ahead and
/// fully remove them at the moment"), not just hidden: both only ever
/// rendered once `tabs.length > 1`, and V1 only has the Overview tab built,
/// so they'd never actually shown. `tabs`/`activeTab`/`onTabSelected` stay
/// on the constructor — the screen still wires them — since the pills
/// themselves are the easy part to rebuild once Explore/Guide/Language
/// exist and `tabs.length > 1` becomes real; this just stops carrying
/// dead-weight widgets in the meantime.
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
///
/// **Does not own site-wide nav chrome** (globe/About) — that briefly
/// lived here as a row inside this navy block, then got split out to
/// `SiteHeader` 2026-08-17. Per Colleen: this widget is *page* chrome (this
/// specific country's flag/name/ticket), `SiteHeader` is *site* chrome
/// (same globe/About on every country) — conflating the two into one
/// navy-colored block was the actual complaint, not the block's padding.
/// A screen using both puts `SiteHeader` directly above this one.
///
/// **Back to one flat navy block** (2026-08-17, per Colleen, reverting the
/// two-tone-ticket pass from earlier the same day — the paper-on-top/navy-
/// stub split "looked weird"). Content and `_TicketStub` are both navy
/// again.
///
/// **The [DashedDivider] lives right under `_TopStripe` now, not at the
/// top of `_TicketStub`** (2026-08-17, moved per Colleen: "a divider under
/// the page header [`SiteHeader`], and the page header does not need
/// nearly that much space between it and the divider but the country/flag
/// section definitely needs more space between it and the page header").
/// So the vertical rhythm reads, top to bottom: `SiteHeader` → tight gap →
/// divider → more room → name/flag row → `_TicketStub` (no divider before
/// it anymore — see that widget's doc).
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _TopStripe(),
        Container(
          width: double.infinity,
          color: CountryTheme.navy,
          // Sides 20->16, bottom 16->8 (2026-08-17, per Colleen, to close
          // up the gap before `_TicketStub`). Top no longer clears the
          // status bar/notch itself (that moved to `SiteHeader`, which now
          // sits above this and owns that inset) — top is now just the
          // tight gap before the divider (6), see class doc.
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // paper (cream), not onNavySoft (translucent white) — per
              // Colleen, 2026-08-17: match the page's cream rather than a
              // plain white, keeping this warm like the rest of the
              // palette instead of introducing a stark white line.
              const DashedDivider(color: CountryTheme.paper, strokeWidth: 1.0),
              // More room here than above the divider — per Colleen, the
              // country/flag section "definitely needs more space between
              // it and the page header" than the tight gap on the other
              // side of the divider.
              const SizedBox(height: 18),
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
            ],
          ),
        ),
        _TicketStub(
          utcOffsetMinutes: widget.utcOffsetMinutes,
          exchangeRate: widget.exchangeRate,
          currencyName: widget.currencyName,
        ),
      ],
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
        // Translucent white — back on the navy surface again (2026-08-17,
        // reverting the paper-content pass — see [CountryHeader]'s class
        // doc), the mockup's `.tk-flag` box-shadow (`rgba(255,255,255,.15)`)
        // this was originally matched to.
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

/// The ticket's stub — local time + a $1 USD conversion, matching
/// `.tk-stub`. Absorbs what [RightNowStrip] used to render as its first
/// and third columns (see class doc on why the middle "season" column
/// isn't a fourth field here — it's dropped from view this pass, not
/// moved).
///
/// **Navy, not [CountryTheme.card]** (2026-08-17, per Colleen: "make the
/// local time and currency sections have the same background as well" —
/// once `SiteHeader` went back to navy after a gold detour, the light card
/// stub was the one piece of this block still visually split off from it).
/// Every text/divider/link color below got a matching on-navy pass —
/// `ticketStubValue` in particular was [navy]-on-[card] by design (reads
/// like ink), so it needs [onNavy] here or it's invisible.
///
/// **No divider at the top of this stub anymore** — it moved up to sit
/// under `SiteHeader` instead (2026-08-17, per Colleen — see
/// [CountryHeader]'s class doc for the reasoning and the current layout).
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
      color: CountryTheme.navy,
      // Horizontal 20->16 (2026-08-17), matching the header content
      // Padding above so the stub's fields line up with the name/flag row
      // rather than sitting a few px further out. Top is just a plain
      // small gap now (no divider to leave room for anymore — it moved,
      // see class doc).
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
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
                            color: CountryTheme.onNavy,
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
        Text(label, style: CountryTheme.ticketStubLabel.copyWith(color: CountryTheme.onNavySoft)),
        const SizedBox(height: 3),
        Text(value, style: CountryTheme.ticketStubValue.copyWith(color: CountryTheme.onNavy)),
        if (subtitle.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(subtitle, style: CountryTheme.ticketStubSub.copyWith(color: CountryTheme.onNavySoft)),
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
