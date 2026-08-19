import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';

/// Encodes a Flutter color for the iOS platform channel.
///
/// Concrete colors keep the existing ARGB representation. Dynamic Cupertino
/// colors retain every native trait variant so UIKit can resolve them inside
/// Liquid Glass instead of receiving a color already resolved by Flutter.
@internal
Object encodeColorForNative(Color color) {
  if (color is! CupertinoDynamicColor) return color.toARGB32();

  return <String, int>{
    'light': color.color.toARGB32(),
    'dark': color.darkColor.toARGB32(),
    'lightHighContrast': color.highContrastColor.toARGB32(),
    'darkHighContrast': color.darkHighContrastColor.toARGB32(),
    'lightElevated': color.elevatedColor.toARGB32(),
    'darkElevated': color.darkElevatedColor.toARGB32(),
    'lightHighContrastElevated': color.highContrastElevatedColor.toARGB32(),
    'darkHighContrastElevated': color.darkHighContrastElevatedColor.toARGB32(),
  };
}

@internal
bool nativeColorsEqual(Object? left, Object? right) {
  if (left is Map<String, int> && right is Map<String, int>) {
    return mapEquals(left, right);
  }
  return left == right;
}
