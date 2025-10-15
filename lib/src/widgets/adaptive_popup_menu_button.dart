import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../platform/platform_info.dart';
import 'ios26/ios26_popup_menu_button.dart';

export 'ios26/ios26_popup_menu_button.dart' show AdaptivePopupMenuItem, AdaptivePopupMenuDivider, AdaptivePopupMenuEntry, PopupButtonStyle;

/// An adaptive popup menu button that renders platform-specific styles
class AdaptivePopupMenuButton<T> {
  AdaptivePopupMenuButton._();

  /// Creates a text-labeled popup menu button
  static Widget text<T>({
    Key? key,
    required String label,
    required List<AdaptivePopupMenuEntry> items,
    required void Function(int index, AdaptivePopupMenuItem<T> entry) onSelected,
    Color? tint,
    double height = 32.0,
    bool shrinkWrap = false,
    PopupButtonStyle buttonStyle = PopupButtonStyle.plain,
  }) {
    // iOS 26+ - Use native iOS 26 popup menu button
    if (PlatformInfo.isIOS26OrHigher()) {
      return IOS26PopupMenuButton<T>(
        buttonLabel: label,
        items: items,
        onSelected: onSelected,
        tint: tint,
        height: height,
        shrinkWrap: shrinkWrap,
        buttonStyle: buttonStyle,
      );
    }

    // Android - Use Material PopupMenuButton
    if (PlatformInfo.isAndroid) {
      return _MaterialPopupMenuButton<T>(
        label: label,
        items: items,
        onSelected: onSelected,
        tint: tint,
        height: height,
      );
    }

    // iOS <26 (iOS 18 and below) - Use CupertinoButton with action sheet (iOS fallback)
    return Builder(
      builder: (context) => SizedBox(
        height: height,
        child: CupertinoButton(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          onPressed: () => _showMenu<T>(context, label, items, onSelected),
          child: Text(label),
        ),
      ),
    );
  }

  /// Creates a popup menu button with a custom child widget
  static Widget widget<T>({
    Key? key,
    required List<AdaptivePopupMenuEntry> items,
    required void Function(int index, AdaptivePopupMenuItem<T> entry) onSelected,
    Color? tint,
    PopupButtonStyle buttonStyle = PopupButtonStyle.plain,
    required Widget child,
  }) {
    // iOS 26+ - Use gesture detector with native menu
    if (PlatformInfo.isIOS26OrHigher()) {
      return IOS26PopupMenuButton<T>.widget(
        items: items,
        onSelected: onSelected,
        tint: tint,
        buttonStyle: buttonStyle,
        child: child,
      );
    }

    // Android - Use Material PopupMenuButton with custom child
    if (PlatformInfo.isAndroid) {
      return _MaterialPopupMenuButton<T>.widget(
        items: items,
        onSelected: onSelected,
        tint: tint,
        child: child,
      );
    }

    // iOS <26 (iOS 18 and below) - Use GestureDetector with action sheet
    return Builder(
      builder: (context) => GestureDetector(
        onTap: () => _showMenu<T>(context, null, items, onSelected),
        child: child,
      ),
    );
  }

  /// Creates a round, icon-only popup menu button
  static Widget icon<T>({
    Key? key,
    required String icon,
    required List<AdaptivePopupMenuEntry> items,
    required void Function(int index, AdaptivePopupMenuItem<T> entry) onSelected,
    Color? tint,
    double size = 44.0,
    PopupButtonStyle buttonStyle = PopupButtonStyle.glass,
  }) {
    // iOS 26+ - Use native iOS 26 popup menu button
    if (PlatformInfo.isIOS26OrHigher()) {
      return IOS26PopupMenuButton<T>.icon(
        buttonIcon: icon,
        items: items,
        onSelected: onSelected,
        tint: tint,
        size: size,
        buttonStyle: buttonStyle,
      );
    }

    // Android - Use Material IconButton with PopupMenu
    if (PlatformInfo.isAndroid) {
      return _MaterialPopupMenuButton<T>.icon(
        icon: icon,
        items: items,
        onSelected: onSelected,
        tint: tint,
        size: size,
      );
    }

    // iOS <26 (iOS 18 and below) - Use icon button with action sheet (iOS fallback)
    return Builder(
      builder: (context) => SizedBox(
        width: size,
        height: size,
        child: CupertinoButton(
          padding: const EdgeInsets.all(4),
          onPressed: () => _showMenu<T>(context, null, items, onSelected),
          child: const Icon(CupertinoIcons.ellipsis),
        ),
      ),
    );
  }

  static Future<void> _showMenu<T>(
    BuildContext context,
    String? title,
    List<AdaptivePopupMenuEntry> items,
    void Function(int index, AdaptivePopupMenuItem<T> entry) onSelected,
  ) async {
    final selected = await showCupertinoModalPopup<int>(
      context: context,
      builder: (ctx) {
        return CupertinoActionSheet(
          title: title != null ? Text(title) : null,
          actions: [
            for (var i = 0; i < items.length; i++)
              if (items[i] is AdaptivePopupMenuItem<T>)
                CupertinoActionSheetAction(
                  onPressed: () => Navigator.of(ctx).pop(i),
                  child: Text((items[i] as AdaptivePopupMenuItem<T>).label),
                )
              else
                const SizedBox(height: 8),
          ],
          cancelButton: CupertinoActionSheetAction(
            onPressed: () => Navigator.of(ctx).pop(),
            isDefaultAction: true,
            child: const Text('Cancel'),
          ),
        );
      },
    );

    if (selected != null) {
      final selectedEntry = items[selected];
      if (selectedEntry is AdaptivePopupMenuItem<T>) {
        onSelected(selected, selectedEntry);
      }
    }
  }

  // SF Symbol to Material Icon mapping
  static IconData _sfSymbolToMaterialIcon(String sfSymbol) {
    const iconMap = {
      'ellipsis.circle': Icons.more_horiz,
      'ellipsis': Icons.more_vert,
      'gear': Icons.settings,
      'square.and.arrow.up': Icons.share,
      'star.fill': Icons.star,
      'star': Icons.star_border,
      'doc.on.doc': Icons.content_copy,
      'trash': Icons.delete,
      'info.circle': Icons.info,
      'checkmark': Icons.check,
      'xmark': Icons.close,
      'plus': Icons.add,
      'minus': Icons.remove,
      'heart': Icons.favorite_border,
      'heart.fill': Icons.favorite,
      'book': Icons.book,
      'folder': Icons.folder,
      'doc.badge.plus': Icons.note_add,
      'square.and.arrow.down': Icons.save,
      'square.and.arrow.down.on.square': Icons.save_as,
      'scissors': Icons.content_cut,
      'doc.on.clipboard': Icons.content_paste,
      'selection.pin.in.out': Icons.select_all,
      'arrow.uturn.backward': Icons.undo,
      'exclamationmark.triangle': Icons.warning,
      'nosign': Icons.block,
    };
    return iconMap[sfSymbol] ?? Icons.circle;
  }
}

/// Material implementation of popup menu button for Android
class _MaterialPopupMenuButton<T> extends StatelessWidget {
  const _MaterialPopupMenuButton({
    required this.label,
    required this.items,
    required this.onSelected,
    this.tint,
    this.height = 32.0,
  })  : icon = null,
        size = null,
        child = null;

  const _MaterialPopupMenuButton.icon({
    required this.icon,
    required this.items,
    required this.onSelected,
    this.tint,
    this.size = 44.0,
  })  : label = null,
        height = null,
        child = null;

  const _MaterialPopupMenuButton.widget({
    required this.items,
    required this.onSelected,
    this.tint,
    required this.child,
  })  : label = null,
        icon = null,
        height = null,
        size = null;

  final String? label;
  final String? icon;
  final Widget? child;
  final List<AdaptivePopupMenuEntry> items;
  final void Function(int index, AdaptivePopupMenuItem<T> entry) onSelected;
  final Color? tint;
  final double? height;
  final double? size;

  bool get isIconButton => icon != null;
  bool get isCustomWidget => child != null;

  @override
  Widget build(BuildContext context) {
    final menuItems = <PopupMenuEntry<int>>[];

    for (var i = 0; i < items.length; i++) {
      if (items[i] is AdaptivePopupMenuDivider) {
        menuItems.add(const PopupMenuDivider());
      } else if (items[i] is AdaptivePopupMenuItem<T>) {
        final item = items[i] as AdaptivePopupMenuItem<T>;
        menuItems.add(
          PopupMenuItem<int>(
            value: i,
            enabled: item.enabled,
            child: Row(
              children: [
                if (item.icon != null) ...[
                  Icon(
                    AdaptivePopupMenuButton._sfSymbolToMaterialIcon(item.icon!),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(child: Text(item.label)),
              ],
            ),
          ),
        );
      }
    }

    // Custom widget case
    if (isCustomWidget) {
      return PopupMenuButton<int>(
        child: child!,
        itemBuilder: (context) => menuItems,
        onSelected: (index) {
          final selectedEntry = items[index];
          if (selectedEntry is AdaptivePopupMenuItem<T>) {
            onSelected(index, selectedEntry);
          }
        },
      );
    }

    if (isIconButton) {
      return SizedBox(
        width: size,
        height: size,
        child: PopupMenuButton<int>(
          icon: Icon(
            icon != null
                ? AdaptivePopupMenuButton._sfSymbolToMaterialIcon(icon!)
                : Icons.more_vert,
            color: tint,
          ),
          itemBuilder: (context) => menuItems,
          onSelected: (index) {
            final selectedEntry = items[index];
            if (selectedEntry is AdaptivePopupMenuItem<T>) {
              onSelected(index, selectedEntry);
            }
          },
        ),
      );
    }

    return SizedBox(
      height: height,
      child: TextButton(
        onPressed: () {},
        child: PopupMenuButton<int>(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label ?? ''),
              const SizedBox(width: 4),
              const Icon(Icons.arrow_drop_down, size: 20),
            ],
          ),
          itemBuilder: (context) => menuItems,
          onSelected: (index) {
            final selectedEntry = items[index];
            if (selectedEntry is AdaptivePopupMenuItem<T>) {
              onSelected(index, selectedEntry);
            }
          },
        ),
      ),
    );
  }
}
