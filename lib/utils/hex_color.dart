import 'package:flutter/material.dart';

/// Parses a "#RRGGBB" (or bare "RRGGBB") hex string into an opaque [Color]
/// — used for the per-country accent color pulled from a country's flag
/// (see `CountryFacts.accentColorHex`). Hand-rolled rather than a package:
/// this is the only place in the app that needs it.
Color hexToColor(String hex) {
  final cleaned = hex.startsWith('#') ? hex.substring(1) : hex;
  return Color(int.parse('FF$cleaned', radix: 16));
}
