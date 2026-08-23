import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'ios26/ios26_popup_menu_button.dart';

/// Spacer type for toolbar items (iOS 26+ only)
enum ToolbarSpacerType {
  /// No spacer
  none,

  /// Fixed 12pt space - groups items within same section
  fixed,

  /// Flexible space - separates item groups (pushes next items to opposite side)
  flexible,
}

/// An app bar action that can be displayed in AdaptiveScaffold
///
/// - On iOS 26+: Uses iosSymbol (SF Symbol) in native UIToolbar
/// - On iOS < 26: Uses icon (IconData) in CupertinoNavigationBar
/// - On Android: Uses icon (IconData) in Material AppBar
class AdaptiveAppBarAction {
  const AdaptiveAppBarAction({
    this.iosSymbol,
    this.icon,
    this.iconWidget,
    this.title,
    required this.onPressed,
    this.menuItems,
    this.onMenuSelected,
    this.spacerAfter = ToolbarSpacerType.none,
    this.prominent = false,
    this.tintColor,
  }) : assert(
         iosSymbol != null || icon != null || iconWidget != null || title != null,
         'At least one of iosSymbol, icon, iconWidget, or title must be provided',
       );

  /// SF Symbol name for iOS 26+ ONLY (e.g., 'info.circle', 'plus.circle')
  /// - iOS 26+: Uses UIImage(systemName:) in native UIBarButtonItem
  /// - iOS <26: NOT used, use icon parameter instead
  /// - Android: NOT used, use icon parameter instead
  final String? iosSymbol;

  /// Icon for iOS <26 and Android (e.g., Icons.info, CupertinoIcons.info)
  /// - iOS 26+: NOT used (iosSymbol takes priority)
  /// - iOS <26: Used for CupertinoButton
  /// - Android: Used for IconButton
  final IconData? icon;

  /// Custom icon widget for iOS <26 and Android (e.g., SvgPicture.asset)
  /// If provided, this widget is used instead of the icon parameter.
  final Widget? iconWidget;

  /// Text title for the action (optional)
  /// If provided along with icons, title takes precedence
  final String? title;

  /// Callback when the action is tapped
  final VoidCallback onPressed;

  /// Add spacer after this action in iOS 26+ toolbar
  /// - `none`: No spacer (default)
  /// - `fixed`: 12pt fixed space - groups items within same section
  /// - `flexible`: Flexible space - separates item groups (e.g., left vs right groups)
  ///
  /// Example: For Undo/Redo on left and Markup/More on right:
  /// ```dart
  /// actions: [
  ///   AdaptiveAppBarAction(iosSymbol: 'arrow.uturn.backward', ...),
  ///   AdaptiveAppBarAction(iosSymbol: 'arrow.uturn.forward', ..., spacerAfter: ToolbarSpacerType.flexible),
  ///   AdaptiveAppBarAction(iosSymbol: 'pencil', ...),
  ///   AdaptiveAppBarAction(iosSymbol: 'ellipsis', ...),
  /// ]
  /// ```
  final ToolbarSpacerType spacerAfter;

  /// Display this action with a prominent glass background (iOS 26+ only)
  /// - iOS 26+: Uses UIBarButtonItem.Style.prominent for a tinted glass bubble
  /// - iOS <26 / Android: Ignored
  final bool prominent;

  /// Per-action tint color (iOS 26+ only)
  /// Overrides the global AdaptiveAppBar.tintColor for this specific action.
  /// Useful for highlighting individual buttons (e.g., green call button).
  /// - iOS <26 / Android: Ignored
  final Color? tintColor;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AdaptiveAppBarAction &&
        other.iosSymbol == iosSymbol &&
        other.icon == icon &&
        other.iconWidget == iconWidget &&
        other.title == title &&
        other.prominent == prominent &&
        other.tintColor == tintColor;
  }

  @override
  int get hashCode => Object.hash(iosSymbol, icon, iconWidget, title, prominent, tintColor);

  /// Convert action to map for native platform channel (iOS 26+ only)
  /// Menu entries this action opens instead of firing [onPressed]
  ///
  /// - On iOS 26+: attached to the native UIBarButtonItem as a UIMenu, so the
  ///   toolbar button opens a native menu rather than calling back into Dart
  /// - On iOS < 26 and Android: rendered through [AdaptivePopupMenuButton]
  ///
  /// [AdaptivePopupMenuDivider.title] groups the entries into titled sections.
  final List<AdaptivePopupMenuEntry>? menuItems;

  /// Called with the entry the user picked from [menuItems]
  final void Function(int index, AdaptivePopupMenuItem entry)? onMenuSelected;

  /// Whether this action opens a menu rather than firing [onPressed]
  bool get hasMenu => menuItems != null && menuItems!.isNotEmpty;

  Map<String, dynamic> toNativeMap() {
    return {
      if (iosSymbol != null) 'icon': iosSymbol!,
      if (title != null) 'title': title!,
      if (hasMenu) 'menu': _menuToNativeList(),
      'spacerAfter': spacerAfter.index, // 0=none, 1=fixed, 2=flexible
      if (prominent) 'prominent': true,
      if (tintColor != null) 'tint': tintColor!.toARGB32(),
    };
  }

  List<Map<String, dynamic>> _menuToNativeList() {
    return [
      for (final entry in menuItems!)
        if (entry is AdaptivePopupMenuDivider)
          // The title rides along with the divider, naming the group after it.
          {'label': entry.title ?? '', 'isDivider': true, 'enabled': false}
        else if (entry is AdaptivePopupMenuItem)
          {
            'label': entry.label,
            'subtitle': entry.subtitle ?? '',
            'icon': entry.icon is String ? entry.icon as String : '',
            'isDivider': false,
            'enabled': entry.enabled,
            'isDestructive': entry.isDestructive,
          },
    ];
  }
}
