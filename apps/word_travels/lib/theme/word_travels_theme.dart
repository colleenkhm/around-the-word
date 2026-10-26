import 'package:flutter/material.dart';
import 'package:shared_theme/shared_theme.dart';

/// Word Travels' palette and type ramp, blended with whereabout's: surfaces,
/// ink and type come from the shared [AccordionTheme], while the postal red
/// and the per-category tints stay as this app's own warm accent family.
class PTColors {
  PTColors._();

  // Shared with whereabout.
  static const card = AccordionTheme.page; // the app's base surface
  static const cardRow = AccordionTheme.white;
  static const ink = AccordionTheme.ink;
  static const inkSoft = AccordionTheme.ink3;
  static const line = AccordionTheme.rule;

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
  // The one cool red in the set — the other warm reds (postal, clay) were
  // already spoken for when a ninth category arrived.
  static const rose = Color(0xFFA8556B);
  static const roseInk = Color(0xFF3D1A24);
  static const roseTint = Color(0xFFF2E1E7);
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
  static const activities = PTTint(PTColors.roseTint, PTColors.roseInk);
}

/// The shared base theme, plus this app's postal-red text selection.
ThemeData buildWordTravelsTheme() {
  return sharedThemeData.copyWith(
    splashFactory: InkRipple.splashFactory,
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

/// Headline/display text — Fraunces, shared with whereabout.
TextStyle ptHeading({double size = 20, FontWeight weight = FontWeight.w600, Color? color}) {
  return TextStyle(
    fontFamily: AccordionTheme.fraunces,
    fontWeight: weight,
    fontSize: size,
    color: color ?? PTColors.ink,
    letterSpacing: -0.2,
  );
}

/// Body text — DM Sans, shared with whereabout.
TextStyle ptBody({double size = 14, FontWeight weight = FontWeight.w400, Color? color}) {
  return TextStyle(
    fontFamily: AccordionTheme.dmSans,
    fontWeight: weight,
    fontSize: size,
    color: color ?? PTColors.ink,
  );
}

/// Mono labels — pronunciation, counts, chips of fact.
TextStyle ptMono({double size = 11, FontWeight weight = FontWeight.w400, Color? color}) {
  return TextStyle(
    fontFamily: AccordionTheme.dmMono,
    fontWeight: weight,
    fontSize: size,
    color: color ?? PTColors.inkSoft,
  );
}
