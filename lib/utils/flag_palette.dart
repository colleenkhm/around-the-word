import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:palette_generator/palette_generator.dart';

import 'flag_url.dart';

/// Extracts a country flag's base/field colors (large stripe/background
/// blocks), for [SectionPalette.fromFlagColors]. Returns `null` on any
/// failure. Sorts [PaletteGenerator.paletteColors] by pixel population
/// and filters out small emblem/seal detail — see HANDOFF.md.
Future<List<Color>?> extractFlagBaseColors(String isoCode) async {
  try {
    final image = await _loadUiImage(flagPngUrl(isoCode));
    if (image == null) return null;
    final palette = await PaletteGenerator.fromImage(image, maximumColorCount: 24);

    final swatches = [...palette.paletteColors]
      ..sort((a, b) => b.population.compareTo(a.population));
    if (swatches.isEmpty) return null;

    // Excludes small emblem/seal detail relative to the largest field.
    final threshold = swatches.first.population * 0.08;
    final major = swatches.where((s) => s.population >= threshold);

    // Keeps only the largest of each near-duplicate color cluster.
    final baseColors = <Color>[];
    for (final swatch in major) {
      final isDuplicate = baseColors.any((c) => _distance(c, swatch.color) < 0.12);
      if (!isDuplicate) baseColors.add(swatch.color);
    }
    return baseColors.isEmpty ? null : baseColors;
  } catch (error) {
    debugPrint('Flag palette extraction failed for $isoCode: $error');
    return null;
  }
}

// Euclidean RGB distance — "basically the same color," not perceptual.
double _distance(Color a, Color b) {
  final dr = a.r - b.r;
  final dg = a.g - b.g;
  final db = a.b - b.b;
  return math.sqrt(dr * dr + dg * dg + db * db);
}

Future<ui.Image?> _loadUiImage(String url) {
  final completer = Completer<ui.Image?>();
  final stream = NetworkImage(url).resolve(const ImageConfiguration());
  late final ImageStreamListener listener;
  listener = ImageStreamListener(
    (info, synchronousCall) {
      stream.removeListener(listener);
      if (!completer.isCompleted) completer.complete(info.image);
    },
    onError: (exception, stackTrace) {
      stream.removeListener(listener);
      if (!completer.isCompleted) completer.complete(null);
    },
  );
  stream.addListener(listener);
  return completer.future;
}
