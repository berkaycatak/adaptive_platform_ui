import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'adaptive_popup_menu_button.dart';

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
    this.label,
    this.onPressed = _noAction,
    this.menuItems,
    this.onMenuItemSelected,
    this.spacerAfter = ToolbarSpacerType.none,
    this.prominent = false,
    this.tintColor,
  }) : assert(
         iosSymbol != null ||
             icon != null ||
             iconWidget != null ||
             title != null,
         'At least one of iosSymbol, icon, iconWidget, or title must be provided',
       ),
       assert(
         menuItems != null || !identical(onPressed, _noAction),
         'Either onPressed or menuItems must be provided',
       ),
       assert(
         (menuItems == null) == (onMenuItemSelected == null),
         'menuItems and onMenuItemSelected go together',
       );

  static void _noAction() {}

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

  /// A short name for the action, such as "Undo" or "Share". It never
  /// changes how the action looks; it names it wherever a name is needed:
  ///
  /// - iPhone Duo: the entry in the overflow menu that toolbar items move
  ///   into when the trailing bar runs out of room
  /// - iOS: the VoiceOver label of the button
  /// - Android: the tooltip of the button
  ///
  /// Give every icon action one. Unlike [title], it does not replace the icon
  /// with text on iOS <26 and Android. Falls back to [title].
  final String? label;

  /// The name to show or speak for this action: [label], else [title].
  String? get effectiveLabel => label ?? title;

  /// Callback when the action is tapped (not used with [menuItems])
  final VoidCallback onPressed;

  /// Menu shown when the action is tapped
  /// - iOS 26+: Native UIMenu on the bar button
  /// - iOS <26: Action sheet
  /// - Android: Popup menu
  final List<AdaptivePopupMenuEntry>? menuItems;

  /// Callback with the item chosen from [menuItems] and its index
  final void Function(int index, AdaptivePopupMenuItem<dynamic> item)?
  onMenuItemSelected;

  /// Whether tapping the action opens [menuItems].
  bool get hasMenu => menuItems?.isNotEmpty ?? false;

  /// Calls [onPressed], or opens [menuItems] in a bar drawn by Flutter
  void press(BuildContext context, {NavigatorState? navigator}) {
    if (!hasMenu) return onPressed();
    AdaptivePopupMenuButton.show<dynamic>(
      context,
      items: menuItems!,
      onSelected: (index, _) => selectMenuItem(index),
      navigator: navigator,
    );
  }

  /// Calls [onMenuItemSelected] for the item at [index]
  void selectMenuItem(int index) {
    final items = menuItems;
    if (items == null || index < 0 || index >= items.length) return;
    final item = items[index];
    if (item is AdaptivePopupMenuItem) onMenuItemSelected?.call(index, item);
  }

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
        other.label == label &&
        other.prominent == prominent &&
        other.tintColor == tintColor &&
        listEquals(_menuSignature, other._menuSignature);
  }

  @override
  int get hashCode => Object.hash(
    iosSymbol,
    icon,
    iconWidget,
    title,
    label,
    prominent,
    tintColor,
    Object.hashAll(_menuSignature ?? const []),
  );

  /// Menu fields compared by ==, without callbacks (new on every build)
  List<Object?>? get _menuSignature => menuItems == null
      ? null
      : [
          for (final entry in menuItems!)
            if (entry is AdaptivePopupMenuItem)
              (
                entry.label,
                entry.subtitle,
                entry.icon,
                entry.enabled,
                entry.isDestructive,
              )
            else
              null,
        ];

  /// Convert action to map for native platform channel (iOS 26+ only)
  Map<String, dynamic> toNativeMap() {
    return {
      if (iosSymbol != null) 'icon': iosSymbol!,
      if (title != null) 'title': title!,
      if (effectiveLabel != null) 'label': effectiveLabel!,
      'spacerAfter': spacerAfter.index, // 0=none, 1=fixed, 2=flexible
      if (prominent) 'prominent': true,
      if (tintColor != null) 'tint': tintColor!.toARGB32(),
      if (hasMenu)
        'menu': [
          for (final entry in menuItems!)
            if (entry is AdaptivePopupMenuItem)
              {
                'title': entry.label,
                if (entry.subtitle != null) 'subtitle': entry.subtitle,
                if (entry.icon is String) 'icon': entry.icon,
                if (!entry.enabled) 'enabled': false,
                if (entry.isDestructive) 'destructive': true,
              }
            else
              {'divider': true},
        ],
    };
  }
}
