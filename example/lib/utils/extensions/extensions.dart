import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

extension CheckThemeMode on BuildContext {
  bool isDarkMode() => PlatformInfo.isIOS
      ? CupertinoTheme.brightnessOf(this) == Brightness.dark
      : Theme.of(this).brightness == Brightness.dark;
  bool isLightMode() => PlatformInfo.isIOS
      ? CupertinoTheme.brightnessOf(this) == Brightness.light
      : Theme.of(this).brightness == Brightness.dark;
}

extension ColorOpacity on Color {
  // e.g 0.5 for 50% opacity
  Color withOpacityValue(double opacity) {
    return withAlpha((opacity * 255).round());
  }
}
