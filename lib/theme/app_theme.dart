import 'package:flutter/material.dart';

/// Design tokens from design/DESIGN.md (palette P19, postal "send a letter" brand).
class C {
  static const bg = Color(0xFFF7FCF4);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceAlt = Color(0xFFF2F6EE);
  static const accent = Color(0xFF9FE870);
  static const accentPressed = Color(0xFF8FD660);
  static const accentFill = Color(0xFF557D3C);
  static const accentTint = Color(0xFFF2FCEB);
  static const support = Color(0xFFFFB08A);
  static const ink = Color(0xFF141F0C);
  static const ink2 = Color(0xFF4A5541);
  static const ink3 = Color(0xFF626C59);
  static const border = Color(0xFFE3E9DE);
  static const borderStrong = Color(0xFF749F6F);
  static const up = Color(0xFF0E7C3A);
  static const upTint = Color(0xFFE3F4E9);
  static const down = Color(0xFFCE2020);
  static const downTint = Color(0xFFFBE5E5);
  static const warn = Color(0xFFA75906);
  static const warnTint = Color(0xFFFAEFE1);
  static const scrim = Color(0x66141F0C);
}

class T {
  static const sans = 'Inter';
  static const display = 'Familjen Grotesk';
  static const _tab = [FontFeature.tabularFigures()];

  static TextStyle num(double size, {Color color = C.ink, FontWeight w = FontWeight.w700}) => TextStyle(
      fontFamily: display, fontSize: size, fontWeight: w, color: color, letterSpacing: -0.02 * size, height: 1.1, fontFeatures: _tab);
  static const displayL = TextStyle(fontFamily: display, fontSize: 40, fontWeight: FontWeight.w700, color: C.ink, letterSpacing: -0.8, height: 1.1, fontFeatures: _tab);
  static const title = TextStyle(fontFamily: sans, fontSize: 20, fontWeight: FontWeight.w600, color: C.ink, height: 1.3);
  static const body = TextStyle(fontFamily: sans, fontSize: 16, fontWeight: FontWeight.w400, color: C.ink2, height: 1.45);
  static const label = TextStyle(fontFamily: sans, fontSize: 14, fontWeight: FontWeight.w500, color: C.ink, height: 1.3);
  static const caption = TextStyle(fontFamily: sans, fontSize: 13, fontWeight: FontWeight.w500, color: C.ink3, height: 1.35);
  static const overline = TextStyle(fontFamily: sans, fontSize: 13, fontWeight: FontWeight.w600, color: C.ink3, letterSpacing: 1.2);
  static const mono = TextStyle(fontFamily: 'Courier', fontSize: 13, fontWeight: FontWeight.w600, color: C.ink2, letterSpacing: .4);
}

ThemeData buildTheme() => ThemeData(
      useMaterial3: true,
      fontFamily: T.sans,
      scaffoldBackgroundColor: C.bg,
      colorScheme: ColorScheme.fromSeed(seedColor: C.accent, primary: C.accentFill, surface: C.surface),
      splashFactory: InkSparkle.splashFactory,
      sliderTheme: const SliderThemeData(
        activeTrackColor: C.accent,
        inactiveTrackColor: C.border,
        thumbColor: C.ink,
        trackHeight: 6,
        overlayShape: RoundSliderOverlayShape(overlayRadius: 18),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.all(Colors.white),
        trackColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? C.accentFill : C.border),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
    );
