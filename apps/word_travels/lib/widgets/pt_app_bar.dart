import 'package:flutter/material.dart';

import '../theme/pocket_talk_theme.dart';

/// The app's one app-bar shape, matching the mockup's `.app-bar`: a thin
/// bottom divider, Fraunces title, and either the circular "PT" monogram
/// (top-level screens) or a back chevron (pushed screens) as the leading
/// element. Built on Flutter's own [AppBar] (for correct status-bar/notch
/// handling) rather than a hand-rolled container, just fully restyled.
/// Built once here per the project's "don't duplicate a shared widget's
/// styling across call sites" rule — every screen asks for one of these
/// rather than assembling its own AppBar.
class PTAppBar extends StatelessWidget implements PreferredSizeWidget {
  const PTAppBar.mark({super.key, required this.title}) : showBack = false;

  const PTAppBar.back({super.key, required this.title}) : showBack = true;

  final String title;
  final bool showBack;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 1);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: PTColors.card,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleSpacing: 4,
      leadingWidth: showBack ? 44 : 48,
      leading: showBack
          ? IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 17, color: PTColors.ink),
              onPressed: () => Navigator.of(context).maybePop(),
            )
          : const Center(child: _Mark()),
      title: Text(title, style: ptHeading(size: 16), overflow: TextOverflow.ellipsis),
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Divider(height: 1, thickness: 1, color: PTColors.line),
      ),
    );
  }
}

class _Mark extends StatelessWidget {
  const _Mark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 26,
      height: 26,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: PTColors.ink, width: 1.6),
      ),
      child: Text('PT', style: ptHeading(size: 10)),
    );
  }
}
