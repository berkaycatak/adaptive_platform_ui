import 'package:adaptive_platform_ui/src/widgets/ios26/ios_native_color.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('encodes a concrete color as the existing ARGB value', () {
    const color = Color(0x7F123456);

    expect(encodeColorForNative(color), color.toARGB32());
  });

  test('preserves every CupertinoDynamicColor trait variant', () {
    const color = CupertinoDynamicColor(
      color: Color(0xFF000001),
      darkColor: Color(0xFF000002),
      highContrastColor: Color(0xFF000003),
      darkHighContrastColor: Color(0xFF000004),
      elevatedColor: Color(0xFF000005),
      darkElevatedColor: Color(0xFF000006),
      highContrastElevatedColor: Color(0xFF000007),
      darkHighContrastElevatedColor: Color(0xFF000008),
    );

    expect(encodeColorForNative(color), <String, int>{
      'light': color.color.toARGB32(),
      'dark': color.darkColor.toARGB32(),
      'lightHighContrast': color.highContrastColor.toARGB32(),
      'darkHighContrast': color.darkHighContrastColor.toARGB32(),
      'lightElevated': color.elevatedColor.toARGB32(),
      'darkElevated': color.darkElevatedColor.toARGB32(),
      'lightHighContrastElevated': color.highContrastElevatedColor.toARGB32(),
      'darkHighContrastElevated': color.darkHighContrastElevatedColor
          .toARGB32(),
    });
  });

  test('compares separately encoded dynamic colors by value', () {
    const color = CupertinoDynamicColor.withBrightness(
      color: Color(0xFF075293),
      darkColor: Color(0xFF0A95F0),
    );

    expect(
      nativeColorsEqual(
        encodeColorForNative(color),
        encodeColorForNative(color),
      ),
      isTrue,
    );
    expect(
      nativeColorsEqual(
        encodeColorForNative(color),
        encodeColorForNative(const Color(0xFF075293)),
      ),
      isFalse,
    );
  });
}
