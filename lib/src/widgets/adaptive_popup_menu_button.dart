import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../platform/platform_info.dart';
import 'ios26/ios26_popup_menu_button.dart';

export 'ios26/ios26_popup_menu_button.dart'
    show
        AdaptivePopupMenuItem,
        AdaptivePopupMenuDivider,
        AdaptivePopupMenuEntry,
        PopupButtonStyle;

/// An adaptive popup menu button that renders platform-specific styles
class AdaptivePopupMenuButton<T> {
  AdaptivePopupMenuButton._();

  /// Creates a text-labeled popup menu button
  static Widget text<T>({
    Key? key,
    required String label,
    required List<AdaptivePopupMenuEntry> items,
    required void Function(int index, AdaptivePopupMenuItem<T> entry)
    onSelected,
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
    required void Function(int index, AdaptivePopupMenuItem<T> entry)
    onSelected,
    Color? tint,
    PopupButtonStyle buttonStyle = PopupButtonStyle.plain,
    bool triggerOnLongPress = false,
    VoidCallback? onTap,
    required Widget child,
  }) {
    assert(
      onTap == null || triggerOnLongPress,
      'onTap is only used with triggerOnLongPress: true (tap fires onTap, '
      'long-press opens the menu).',
    );
    // iOS 26+ - Use gesture detector with native menu
    if (PlatformInfo.isIOS26OrHigher()) {
      return IOS26PopupMenuButton<T>.widget(
        items: items,
        onSelected: onSelected,
        tint: tint,
        buttonStyle: buttonStyle,
        triggerOnLongPress: triggerOnLongPress,
        onTap: onTap,
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
        onTap: triggerOnLongPress
            ? onTap
            : () => _showMenu<T>(context, null, items, onSelected),
        onLongPress: triggerOnLongPress
            ? () => _showMenu<T>(context, null, items, onSelected)
            : null,
        child: child,
      ),
    );
  }

  /// Creates a round, icon-only popup menu button
  ///
  /// [icon] can be either:
  /// - String (SF Symbol) for iOS 26+
  /// - IconData for iOS <26 and Android
  static Widget icon<T>({
    Key? key,
    required dynamic icon,
    required List<AdaptivePopupMenuEntry> items,
    required void Function(int index, AdaptivePopupMenuItem<T> entry)
    onSelected,
    Color? tint,
    double size = 44.0,
    PopupButtonStyle buttonStyle = PopupButtonStyle.glass,
  }) {
    // iOS 26+ - Use native iOS 26 popup menu button (expects String - SF Symbol)
    if (PlatformInfo.isIOS26OrHigher()) {
      return IOS26PopupMenuButton<T>.icon(
        buttonIcon: icon is String ? icon : 'ellipsis.circle',
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
          child: Icon(icon is IconData ? icon : CupertinoIcons.ellipsis),
        ),
      ),
    );
  }

  /// Opens [items] for a button drawn elsewhere, such as an app bar action:
  /// an action sheet on iOS, a popup menu at [context]'s button otherwise.
  /// Buttons above the navigator pass the page's [navigator].
  static Future<void> show<T>(
    BuildContext context, {
    required List<AdaptivePopupMenuEntry> items,
    required void Function(int index, AdaptivePopupMenuItem<T> entry)
    onSelected,
    NavigatorState? navigator,
  }) async {
    final menuContext =
        (navigator ?? Navigator.maybeOf(context))?.overlay?.context;
    if (menuContext == null) return;
    if (PlatformInfo.isIOS) {
      return _showMenu<T>(menuContext, null, items, onSelected);
    }
    final button = context.findRenderObject() as RenderBox?;
    final overlay = menuContext.findRenderObject() as RenderBox?;
    if (button == null || overlay == null) return;
    // Global coordinates, as the button may sit in a bar above the navigator
    final topLeft = overlay.globalToLocal(button.localToGlobal(Offset.zero));
    final selected = await showMenu<int>(
      context: menuContext,
      position: RelativeRect.fromRect(
        topLeft & button.size,
        Offset.zero & overlay.size,
      ),
      items: _materialMenuItems<T>(menuContext, items),
    );
    if (selected != null && items[selected] is AdaptivePopupMenuItem<T>) {
      onSelected(selected, items[selected] as AdaptivePopupMenuItem<T>);
    }
  }

  static Widget _buildActionSheetContent<T>(AdaptivePopupMenuItem<T> item) {
    final hasImage = item.imageBytes != null;
    final hasSubtitle = item.subtitle != null && item.subtitle!.isNotEmpty;

    if (!hasImage && !hasSubtitle) {
      if (!item.selected) return Text(item.label);
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(CupertinoIcons.checkmark, size: 18),
          const SizedBox(width: 8),
          Text(item.label),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (item.selected) ...[
          const Icon(CupertinoIcons.checkmark, size: 18),
          const SizedBox(width: 8),
        ],
        if (hasImage) ...[
          ClipOval(
            child: Image.memory(
              item.imageBytes!,
              width: 32,
              height: 32,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 10),
        ],
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: hasImage
              ? CrossAxisAlignment.start
              : CrossAxisAlignment.center,
          children: [
            Text(item.label),
            if (hasSubtitle)
              Text(
                item.subtitle!,
                style: const TextStyle(
                  fontSize: 13,
                  color: CupertinoColors.secondaryLabel,
                ),
              ),
          ],
        ),
      ],
    );
  }

  static List<PopupMenuEntry<int>> _materialMenuItems<T>(
    BuildContext context,
    List<AdaptivePopupMenuEntry> items,
  ) {
    final menuItems = <PopupMenuEntry<int>>[];

    for (var i = 0; i < items.length; i++) {
      if (items[i] is AdaptivePopupMenuDivider) {
        menuItems.addAll(_materialDivider(context, items[i], i));
      } else if (items[i] is AdaptivePopupMenuItem<T>) {
        final item = items[i] as AdaptivePopupMenuItem<T>;
        final labelStyle = item.isDestructive
            ? TextStyle(color: Theme.of(context).colorScheme.error)
            : null;
        final hasSubtitle = item.subtitle != null && item.subtitle!.isNotEmpty;
        menuItems.add(
          PopupMenuItem<int>(
            value: i,
            enabled: item.enabled,
            child: Row(
              children: [
                if (item.imageBytes != null) ...[
                  ClipOval(
                    child: Image.memory(
                      item.imageBytes!,
                      width: 32,
                      height: 32,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 12),
                ] else if (item.icon != null) ...[
                  Icon(
                    item.icon is IconData
                        ? item.icon as IconData
                        : Icons.circle,
                    size: 20,
                    color: item.isDestructive
                        ? Theme.of(context).colorScheme.error
                        : null,
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: hasSubtitle
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(item.label, style: labelStyle),
                            Text(
                              item.subtitle!,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.color
                                        ?.withValues(alpha: 0.7),
                                  ),
                            ),
                          ],
                        )
                      : Text(item.label, style: labelStyle),
                ),
                if (item.selected) ...[
                  const SizedBox(width: 12),
                  Icon(
                    Icons.check,
                    size: 20,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ],
              ],
            ),
          ),
        );
      }
    }
    return menuItems;
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
                  isDestructiveAction:
                      (items[i] as AdaptivePopupMenuItem<T>).isDestructive,
                  child: _buildActionSheetContent<T>(
                    items[i] as AdaptivePopupMenuItem<T>,
                  ),
                )
              else
                _buildSheetDivider(ctx, items[i]),
          ],
          cancelButton: CupertinoActionSheetAction(
            onPressed: () => Navigator.of(ctx).pop(),
            isDefaultAction: true,
            child: Text(
              PlatformInfo.isIOS
                  ? CupertinoLocalizations.of(ctx).cancelButtonLabel
                  : MaterialLocalizations.of(ctx).cancelButtonLabel,
            ),
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

  /// The gap between two groups in the action sheet, carrying the group's
  /// title when the divider has one; the sheet has no section of its own.
  static Widget _buildSheetDivider(
    BuildContext context,
    AdaptivePopupMenuEntry entry,
  ) {
    final title = entry is AdaptivePopupMenuDivider ? entry.title : null;
    if (title == null || title.isEmpty) return const SizedBox(height: 8);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: SizedBox(
        width: double.infinity,
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: CupertinoColors.secondaryLabel.resolveFrom(context),
          ),
        ),
      ),
    );
  }

  /// A Material divider, preceded by nothing for the first group and followed
  /// by a disabled heading row when the divider carries a title.
  static List<PopupMenuEntry<int>> _materialDivider(
    BuildContext context,
    AdaptivePopupMenuEntry entry,
    int index,
  ) {
    final title = entry is AdaptivePopupMenuDivider ? entry.title : null;
    return [
      if (index > 0) const PopupMenuDivider(),
      if (title != null && title.isNotEmpty)
        PopupMenuItem<int>(
          enabled: false,
          height: 32,
          child: Text(title, style: Theme.of(context).textTheme.labelMedium),
        ),
    ];
  }
}

/// Material implementation of popup menu button for Android
class _MaterialPopupMenuButton<T> extends StatefulWidget {
  const _MaterialPopupMenuButton({
    required this.label,
    required this.items,
    required this.onSelected,
    this.tint,
    this.height = 32.0,
  }) : icon = null,
       size = null,
       child = null;

  const _MaterialPopupMenuButton.icon({
    required this.icon,
    required this.items,
    required this.onSelected,
    this.tint,
    this.size = 44.0,
  }) : label = null,
       height = null,
       child = null;

  const _MaterialPopupMenuButton.widget({
    required this.items,
    required this.onSelected,
    this.tint,
    required this.child,
  }) : label = null,
       icon = null,
       height = null,
       size = null;

  final String? label;
  final dynamic icon; // IconData for Android
  final Widget? child;
  final List<AdaptivePopupMenuEntry> items;
  final void Function(int index, AdaptivePopupMenuItem<T> entry) onSelected;
  final Color? tint;
  final double? height;
  final double? size;

  bool get isIconButton => icon != null;
  bool get isCustomWidget => child != null;

  @override
  State<_MaterialPopupMenuButton<T>> createState() =>
      _MaterialPopupMenuButtonState<T>();
}

class _MaterialPopupMenuButtonState<T>
    extends State<_MaterialPopupMenuButton<T>> {
  @override
  Widget build(BuildContext context) {
    final menuItems = AdaptivePopupMenuButton._materialMenuItems<T>(
      context,
      widget.items,
    );

    // Custom widget case
    if (widget.isCustomWidget) {
      return PopupMenuButton<int>(
        child: widget.child!,
        itemBuilder: (context) => menuItems,
        onSelected: (index) {
          final selectedEntry = widget.items[index];
          if (selectedEntry is AdaptivePopupMenuItem<T>) {
            widget.onSelected(index, selectedEntry);
          }
        },
      );
    }

    if (widget.isIconButton) {
      return SizedBox(
        width: widget.size,
        height: widget.size,
        child: PopupMenuButton<int>(
          icon: Icon(
            widget.icon is IconData ? widget.icon as IconData : Icons.more_vert,
            color: widget.tint,
          ),
          itemBuilder: (context) => menuItems,
          onSelected: (index) {
            final selectedEntry = widget.items[index];
            if (selectedEntry is AdaptivePopupMenuItem<T>) {
              widget.onSelected(index, selectedEntry);
            }
          },
        ),
      );
    }

    return SizedBox(
      height: widget.height,
      child: TextButton(
        onPressed: () {},
        child: PopupMenuButton<int>(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(widget.label ?? ''),
              const SizedBox(width: 4),
              const Icon(Icons.arrow_drop_down, size: 20),
            ],
          ),
          itemBuilder: (context) => menuItems,
          onSelected: (index) {
            final selectedEntry = widget.items[index];
            if (selectedEntry is AdaptivePopupMenuItem<T>) {
              widget.onSelected(index, selectedEntry);
            }
          },
        ),
      ),
    );
  }
}
