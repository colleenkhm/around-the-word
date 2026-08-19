import 'package:flutter/material.dart';

/// Parses a "#RRGGBB" (or bare "RRGGBB") hex string into an opaque [Color].
Color hexToColor(String hex) {
  final cleaned = hex.startsWith('#') ? hex.substring(1) : hex;
  return Color(int.parse('FF$cleaned', radix: 16));
}
