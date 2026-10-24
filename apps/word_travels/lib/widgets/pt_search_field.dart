import 'package:flutter/material.dart';

import '../theme/word_travels_theme.dart';

/// The app's one search input: a tinted rounded row with a leading magnifier.
/// Used by Translate, Phrasebook and the category screens — built once here
/// rather than restyled per call site, like [PTAppBar].
class PTSearchField extends StatelessWidget {
  const PTSearchField({
    super.key,
    required this.controller,
    required this.hint,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: PTColors.cardRow,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: PTColors.line),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, size: 18, color: PTColors.inkSoft),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: ptBody(size: 13.5),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(color: PTColors.inkSoft),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
