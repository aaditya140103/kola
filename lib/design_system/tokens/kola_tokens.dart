import 'package:flutter/material.dart';

abstract final class KolaBreakpoints {
  static const double compact = 600;
  static const double medium = 840;
  static const double expanded = 1200;
  static const double large = 1600;
}

abstract final class KolaSpacing {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

abstract final class KolaRadius {
  static const BorderRadius sm = BorderRadius.all(Radius.circular(10));
  static const BorderRadius md = BorderRadius.all(Radius.circular(16));
  static const BorderRadius lg = BorderRadius.all(Radius.circular(24));
  static const BorderRadius pill = BorderRadius.all(Radius.circular(999));
}

abstract final class KolaMotion {
  static const Duration quick = Duration(milliseconds: 140);
  static const Duration standard = Duration(milliseconds: 220);
  static const Duration emphasized = Duration(milliseconds: 320);
}

abstract final class KolaColors {
  static const Color mint = Color(0xFF52E0C4);
  static const Color mintDark = Color(0xFF23B89D);
  static const Color ink = Color(0xFF101413);
  static const Color paper = Color(0xFFF7F4ED);
  static const Color warmPaper = Color(0xFFF2E8D5);
}
