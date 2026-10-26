import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_theme/shared_theme.dart';

import '../../theme/section_palette.dart';

/// Word Travels' small per-tile tilt, so the grid reads hand-placed.
const postageCardTilts = [-0.6, 0.5, -0.4, 0.6, -0.5, 0.4];

/// One country-page card, styled after Word Travels' category tiles: a
/// flag-colored front and a white postcard back. [face] puts content on
/// the front (otherwise it's a big icon); [back] makes it flip; [onOpen]
/// opens a sheet instead. A card without data flips to "Coming soon".
class PostageCard extends StatefulWidget {
  final String title;
  final IconData icon;
  final SectionColors colors;
  final bool hasData;
  final double tiltDegrees;
  final WidgetBuilder? face;
  final WidgetBuilder? back;
  final VoidCallback? onOpen;

  const PostageCard({
    super.key,
    required this.title,
    required this.icon,
    required this.colors,
    required this.hasData,
    this.tiltDegrees = 0,
    this.face,
    this.back,
    this.onOpen,
  }) : assert(face != null || back != null || onOpen != null);

  @override
  State<PostageCard> createState() => _PostageCardState();
}

class _PostageCardState extends State<PostageCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 350),
  );

  bool get _flips => !widget.hasData || widget.back != null;
  bool get _tappable => _flips || widget.onOpen != null;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTap() {
    if (!_tappable) return;
    if (!_flips) {
      widget.onOpen!();
      return;
    }
    if (_controller.isAnimating) return;
    _controller.value == 0 ? _controller.forward() : _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: widget.tiltDegrees * pi / 180,
      child: MouseRegion(
        cursor: _tappable ? SystemMouseCursors.click : MouseCursor.defer,
        child: GestureDetector(
          onTap: _onTap,
          behavior: HitTestBehavior.opaque,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final showBack = _controller.value > 0.5;
              return Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001)
                  ..rotateY(_controller.value * pi),
                // Grid fixes the size, so only the visible face is built.
                child: showBack
                    ? Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.identity()..rotateY(pi),
                        child: _Back(
                          title: widget.title,
                          icon: widget.icon,
                          colors: widget.colors,
                          child: widget.hasData
                              ? widget.back!(context)
                              : const _ComingSoon(),
                        ),
                      )
                    : widget.face != null && widget.hasData
                    ? _FactFront(
                        title: widget.title,
                        icon: widget.icon,
                        colors: widget.colors,
                        flips: _flips,
                        child: widget.face!(context),
                      )
                    : _Front(
                        title: widget.title,
                        icon: widget.icon,
                        colors: widget.colors,
                        hint: !widget.hasData
                            ? 'Coming soon'
                            : _flips
                            ? 'Tap to flip'
                            : 'Tap to open',
                        hintIcon: _flips
                            ? Icons.swap_horiz
                            : Icons.open_in_full,
                      ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _Front extends StatelessWidget {
  final String title;
  final IconData icon;
  final SectionColors colors;
  final String hint;
  final IconData hintIcon;

  const _Front({
    required this.title,
    required this.icon,
    required this.colors,
    required this.hint,
    required this.hintIcon,
  });

  @override
  Widget build(BuildContext context) {
    final soft = colors.textColor.withValues(alpha: 0.7);
    return _Face(
      color: colors.tint,
      child: Stack(
        children: [
          Positioned(
            top: 0,
            right: 0,
            child: Icon(hintIcon, size: 15, color: soft),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Center(
                  child: Icon(icon, size: 46, color: colors.textColor),
                ),
              ),
              Text(
                title,
                style: AccordionTheme.secName.copyWith(
                  fontSize: 17,
                  color: colors.textColor,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 3),
              Text(
                hint,
                style: AccordionTheme.srcRow.copyWith(
                  fontSize: 11,
                  color: soft,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Front with content on it: a small icon + title header over [child].
class _FactFront extends StatelessWidget {
  final String title;
  final IconData icon;
  final SectionColors colors;
  final bool flips;
  final Widget child;

  const _FactFront({
    required this.title,
    required this.icon,
    required this.colors,
    required this.flips,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final soft = colors.textColor.withValues(alpha: 0.7);
    return _Face(
      color: colors.tint,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: colors.textColor),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: AccordionTheme.secName.copyWith(
                    fontSize: 15,
                    color: colors.textColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (flips) Icon(Icons.swap_horiz, size: 15, color: soft),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(child: child),
        ],
      ),
    );
  }
}

/// White postcard back, with the front's icon as a small corner stamp.
class _Back extends StatelessWidget {
  final String title;
  final IconData icon;
  final SectionColors colors;
  final Widget child;

  const _Back({
    required this.title,
    required this.icon,
    required this.colors,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return _Face(
      color: AccordionTheme.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title.toUpperCase(),
                  style: AccordionTheme.sLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: colors.tint,
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(color: AccordionTheme.ink, width: 1),
                ),
                child: Icon(icon, size: 14, color: colors.textColor),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(child: child),
        ],
      ),
    );
  }
}

/// Shared tile chrome: rounded, ink-bordered, with a punch hole.
class _Face extends StatelessWidget {
  final Color color;
  final Widget child;

  const _Face({required this.color, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 16, 14, 12),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AccordionTheme.ink, width: 1.4),
            ),
            child: child,
          ),
        ),
        Positioned(
          top: -5,
          left: 14,
          child: Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AccordionTheme.page,
              border: Border.all(color: AccordionTheme.ink, width: 1.4),
            ),
          ),
        ),
      ],
    );
  }
}

class _ComingSoon extends StatelessWidget {
  const _ComingSoon();

  @override
  Widget build(BuildContext context) {
    return Text(
      "Coming soon — we haven't curated this yet.",
      style: AccordionTheme.sBody.copyWith(
        fontSize: 13.5,
        color: AccordionTheme.ink3,
        fontStyle: FontStyle.italic,
      ),
    );
  }
}

/// Opens a card's long-form content in a bottom sheet, headed by the
/// card's flag color.
Future<void> showPostageSheet(
  BuildContext context, {
  required String title,
  required IconData icon,
  required SectionColors colors,
  required WidgetBuilder builder,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AccordionTheme.white,
    constraints: const BoxConstraints(maxWidth: 720),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
    ),
    clipBehavior: Clip.antiAlias,
    builder: (context) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (context, scrollController) => ListView(
        controller: scrollController,
        padding: EdgeInsets.zero,
        children: [
          Container(
            color: colors.tint,
            padding: const EdgeInsets.fromLTRB(20, 14, 8, 14),
            child: Row(
              children: [
                Icon(icon, size: 22, color: colors.textColor),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: AccordionTheme.secName.copyWith(
                      color: colors.textColor,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Close',
                  icon: Icon(Icons.close, color: colors.textColor),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          builder(context),
          const SizedBox(height: 24),
        ],
      ),
    ),
  );
}
