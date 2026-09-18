import 'package:flutter/material.dart';

import '../theme/pocket_talk_theme.dart';

class PTTabItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  const PTTabItem({required this.icon, required this.selectedIcon, required this.label});
}

/// The mockup's `.tab-bar`: icon-over-label buttons, a thin top divider,
/// no pill/indicator chrome — just an ink-vs-inkSoft color/weight switch
/// for the selected tab.
class PTTabBar extends StatelessWidget {
  const PTTabBar({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onSelect,
  });

  final List<PTTabItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: PTColors.card,
        border: Border(top: BorderSide(color: PTColors.line)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(6, 9, 6, 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              for (var i = 0; i < items.length; i++)
                _TabButton(
                  item: items[i],
                  selected: i == selectedIndex,
                  onTap: () => onSelect(i),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({required this.item, required this.selected, required this.onTap});

  final PTTabItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? PTColors.ink : PTColors.inkSoft;
    return InkResponse(
      onTap: onTap,
      radius: 36,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(selected ? item.selectedIcon : item.icon, size: 19, color: color),
            const SizedBox(height: 3),
            Text(
              item.label,
              style: TextStyle(
                fontFamily: 'IBM Plex Sans',
                fontSize: 10.5,
                color: color,
                fontWeight: selected ? FontWeight.w500 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
