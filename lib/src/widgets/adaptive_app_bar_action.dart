import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// An app bar action that can be displayed in AdaptiveScaffold
///
/// - On iOS 26+: Rendered as native UIBarButtonItem in UIToolbar
/// - On iOS < 26: Rendered as CupertinoButton in CupertinoNavigationBar
/// - On Android: Rendered as IconButton in Material AppBar
class AdaptiveAppBarAction {
  const AdaptiveAppBarAction({
    this.iosSymbol,
    this.androidIcon,
    this.title,
    required this.onPressed,
  }) : assert(
          iosSymbol != null || androidIcon != null || title != null,
          'At least one of iosSymbol, androidIcon, or title must be provided',
        );

  /// SF Symbol name for iOS (e.g., 'info.circle', 'plus.circle')
  /// - iOS 26+: Uses UIImage(systemName:) in native UIBarButtonItem
  /// - iOS < 26: Rendered as SF Symbol in Flutter widget
  final String? iosSymbol;

  /// Material icon for Android (e.g., Icons.info, Icons.add)
  final IconData? androidIcon;

  /// Text title for the action (optional)
  /// If provided along with icons, title takes precedence
  final String? title;

  /// Callback when the action is tapped
  final VoidCallback onPressed;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AdaptiveAppBarAction &&
        other.iosSymbol == iosSymbol &&
        other.androidIcon == androidIcon &&
        other.title == title;
  }

  @override
  int get hashCode => Object.hash(iosSymbol, androidIcon, title);

  /// Convert action to map for native platform channel (iOS 26+ only)
  Map<String, dynamic> toNativeMap() {
    return {
      if (iosSymbol != null) 'icon': iosSymbol!,
      if (title != null) 'title': title!,
    };
  }
}
