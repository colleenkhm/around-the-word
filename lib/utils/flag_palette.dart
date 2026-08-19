import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:palette_generator/palette_generator.dart';

import 'flag_url.dart';

/// Extracts a country flag's actual **base/field colors** — the large
/// stripe/background blocks — as a list of [Color]s, for
/// [SectionPalette.fromFlagColors] to spread across the six accordion
/// sections. Returns `null` on any failure (network, decode, nothing
/// usable found) — the caller falls back to [SectionPalette.fallback]
/// rather than this throwing into a build method.
///
/// **2026-08-18 rewrite**: the previous version used [PaletteGenerator]'s
/// `vibrant`/`muted`/etc. *target* swatches, which are deliberately
/// tuned to surface visually interesting colors regardless of how much
/// of the image they cover — exactly the wrong bias here. Colleen
/// flagged it directly against Costa Rica's flag (blue/white/red
/// stripes, plus a small coat-of-arms seal in the center): "I only want
/// to incorporate base flag colors, not every color in the seal on the
/// flag as well... I see purple, green, and orange in this as well,"
/// none of which are in the flag's actual field. This version instead
/// sorts [PaletteGenerator.paletteColors] by **`population`** — the
/// pixel count each quantized color bucket represents — and keeps only
/// buckets that are a real fraction of the single largest one. A flag's
/// stripes are enormous relative to a small central emblem, so this
/// separates them cleanly without needing to know anything about where
/// the emblem sits.
///
/// **No lightening/pastel-generation of the result** — colors come back
/// exactly as extracted (aside from de-duplicating near-identical
/// quantizer buckets). Colleen was explicit: "don't even do a pastel
/// version. Just do the main colors that are in the flag."
///
/// **Resolves the [NetworkImage] by hand (`_loadUiImage`) rather than
/// calling `PaletteGenerator.fromImageProvider` directly** — that method
/// doesn't attach its own `onError` to the `ImageStream` listener the
/// way `Image.network`'s `errorBuilder` does, so a failed fetch gets
/// reported to `FlutterError.reportError` ("image resource service")
/// *regardless* of this function's own `try`/`catch`. Attaching a real
/// `onError` to the `ImageStreamListener` here is what actually
/// suppresses that. `PaletteGenerator.fromImage` (a decoded `ui.Image`,
/// not an `ImageProvider`) then runs entirely on data already in hand.
Future<List<Color>?> extractFlagBaseColors(String isoCode) async {
  try {
    final image = await _loadUiImage(flagPngUrl(isoCode));
    if (image == null) return null;
    final palette = await PaletteGenerator.fromImage(image, maximumColorCount: 24);

    final swatches = [...palette.paletteColors]
      ..sort((a, b) => b.population.compareTo(a.population));
    if (swatches.isEmpty) return null;

    // A small emblem/seal covers a tiny fraction of the flag compared to
    // its field stripes — 8% of the largest region's pixel count is a
    // generous cutoff that still excludes that kind of detail without
    // needing to know anything about the emblem's actual position.
    final threshold = swatches.first.population * 0.08;
    final major = swatches.where((s) => s.population >= threshold);

    // The quantizer can split one visually-uniform stripe into a couple
    // of very similar buckets (edges, compression artifacts) — keep only
    // the first (largest) of each near-duplicate cluster.
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

/// Euclidean distance between two colors' RGB channels (each 0.0-1.0, so
/// the result ranges 0.0-√3) — good enough for "basically the same
/// color," not meant as a perceptual color-difference formula.
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
