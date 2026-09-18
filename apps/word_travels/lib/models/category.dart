import 'package:flutter/material.dart';

import '../theme/pocket_talk_theme.dart';

/// A topic grouping of phrases (Food & drink, Transportation, ...).
/// Not tied to a country or trip — just a bucket a user can browse and
/// pull phrases from into their vocab bank.
class Category {
  final String id;
  final String name;
  final IconData icon;
  final PTTint tint;

  const Category({
    required this.id,
    required this.name,
    required this.icon,
    required this.tint,
  });
}
