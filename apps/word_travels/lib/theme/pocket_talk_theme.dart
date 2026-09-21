import 'package:flutter/material.dart';

/// Pocket Talk's palette and type ramp, ported from the postal/vintage-travel
/// mockup this app started from.
///
/// One thing the mockup's CSS makes easy to miss: `--paper` is the *outer
/// webpage* backdrop behind the phone mockups (textured, never seen inside
/// a real device) — the phone's actual screen surface is `--card`. So the
/// app itself uses [card] as its base surface throughout; [paper] isn't
/// used at all here.
class PTColors {
  PTColors._();

  static const paper = Color(0xFFEDE6D6); // outer mockup backdrop only
  static const card = Color(0xFFF7F2E7); // the app's actual surface
  static const cardRow = Color(0xFFF1EAD8);
  static const ink = Color(0xFF1E2A38);
  static const inkSoft = Color(0xFF5B6472);
  static const line = Color(0x291E2A38); // ink @ 16%

  static const postal = Color(0xFFB4402C);
  static const postalInk = Color(0xFF5C1C12);
  static const postalTint = Color(0xFFF3DFDA);
  static const mustard = Color(0xFFC68A2E);
  static const mustardInk = Color(0xFF5B3D0F);
  static const mustardTint = Color(0xFFF6E9D2);
  static const teal = Color(0xFF2F6E62);
  static const tealInk = Color(0xFF0F2A24);
  static const tealTint = Color(0xFFE4EEEC);
  static const plum = Color(0xFF7A4B6B);
  static const plumInk = Color(0xFF33172C);
  static const plumTint = Color(0xFFEFE1EA);
  static const sage = Color(0xFF5C7A45);
  static const sageInk = Color(0xFF26331C);
  static const sageTint = Color(0xFFE9EFE0);
  static const slate = Color(0xFF6B6659);
  static const slateInk = Color(0xFF2C2A24);
  static const slateTint = Color(0xFFE7E5DE);
  static const sky = Color(0xFF3E6A8A);
  static const skyInk = Color(0xFF14283A);
  static const skyTint = Color(0xFFE1EAF1);
  static const clay = Color(0xFF9A5B3C);
  static const clayInk = Color(0xFF3D2113);
  static const clayTint = Color(0xFFF1E4DC);
}

/// One category's tile tint — a soft background plus the ink color that
/// reads on top of it, matching the mockup's per-category tile treatment.
class PTTint {
  final Color background;
  final Color ink;
  const PTTint(this.background, this.ink);
}

class PTTints {
  PTTints._();

  static const transport = PTTint(PTColors.tealTint, PTColors.tealInk);
  static const food = PTTint(PTColors.sageTint, PTColors.sageInk);
  static const conversation = PTTint(PTColors.plumTint, PTColors.plumInk);
  static const emergencies = PTTint(PTColors.postalTint, PTColors.postalInk);
  static const basics = PTTint(PTColors.slateTint, PTColors.slateInk);
  static const shopping = PTTint(PTColors.mustardTint, PTColors.mustardInk);
  static const lodging = PTTint(PTColors.skyTint, PTColors.skyInk);
  static const health = PTTint(PTColors.clayTint, PTColors.clayInk);
}

ThemeData buildPocketTalkTheme() {
  final base = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: PTColors.card,
    colorScheme: ColorScheme.fromSeed(
      seedColor: PTColors.postal,
      brightness: Brightness.light,
      surface: PTColors.card,
    ),
    splashFactory: InkRipple.splashFactory,
  );

  return base.copyWith(
    scaffoldBackgroundColor: PTColors.card,
    textTheme: base.textTheme.apply(
      bodyColor: PTColors.ink,
      displayColor: PTColors.ink,
      fontFamily: 'IBM Plex Sans',
    ),
    dividerTheme: const DividerThemeData(
      color: PTColors.line,
      thickness: 1,
      space: 1,
    ),
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: PTColors.postal,
      selectionColor: PTColors.postalTint,
      selectionHandleColor: PTColors.postal,
    ),
  );
}

/// Headline/display text — Fraunces, matches the mockup's serif accents.
TextStyle ptHeading({double size = 20, FontWeight weight = FontWeight.w600, Color? color}) {
  return TextStyle(
    fontFamily: 'Fraunces',
    fontWeight: weight,
    fontSize: size,
    color: color ?? PTColors.ink,
    letterSpacing: -0.2,
  );
}

/// Body text — IBM Plex Sans, the mockup's default sans.
TextStyle ptBody({double size = 14, FontWeight weight = FontWeight.w400, Color? color}) {
  return TextStyle(
    fontFamily: 'IBM Plex Sans',
    fontWeight: weight,
    fontSize: size,
    color: color ?? PTColors.ink,
  );
}

/// Mono labels — pronunciation, counts, chips of fact.
TextStyle ptMono({double size = 11, FontWeight weight = FontWeight.w400, Color? color}) {
  return TextStyle(
    fontFamily: 'IBM Plex Mono',
    fontWeight: weight,
    fontSize: size,
    color: color ?? PTColors.inkSoft,
  );
}
