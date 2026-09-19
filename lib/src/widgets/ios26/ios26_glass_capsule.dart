import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import '../adaptive_app_bar_action.dart';
import '../adaptive_scaffold.dart';

/// One control inside an [IOS26GlassCapsule].
@immutable
class GlassCapsuleItem {
  const GlassCapsuleItem({
    this.symbol,
    this.selectedSymbol,
    this.asset,
    this.file,
    this.network,
    this.title,
    this.label,
    this.tint,
    this.badge,
    this.fallback,
    this.menu,
  });

  /// A toolbar action. Needs an SF Symbol or a title; see [canShow].
  factory GlassCapsuleItem.fromAction(AdaptiveAppBarAction action) =>
      GlassCapsuleItem(
        symbol: action.iosSymbol,
        title: action.iosSymbol == null ? action.title : null,
        label: action.effectiveLabel,
        tint: action.tintColor,
        fallback:
            action.iconWidget ??
            (action.icon != null ? Icon(action.icon, size: 22) : null),
      );

  /// A tab. The icon may be an SF Symbol name, an asset path, or an
  /// [AssetImage], [FileImage] or [NetworkImage] (shown as a round avatar).
  factory GlassCapsuleItem.fromDestination(AdaptiveNavigationDestination d) {
    String? symbolOf(Object? icon) =>
        icon is String && !icon.contains('/') ? icon : null;
    ImageProvider? imageOf(Object? icon) => icon is ImageProvider
        ? icon
        : icon is ImageIcon
        ? icon.image
        : null;
    final image = imageOf(d.icon);
    final icon = d.icon;
    return GlassCapsuleItem(
      symbol: symbolOf(icon) ?? (d.isSearch ? 'magnifyingglass' : null),
      selectedSymbol: symbolOf(d.selectedIcon),
      asset: image is AssetImage
          ? image.assetName
          : (icon is String && icon.contains('/') ? icon : null),
      file: image is FileImage ? image.file.path : null,
      network: image is NetworkImage ? image.url : null,
      label: d.label,
      badge: d.badgeCount,
      fallback: icon is IconData
          ? Icon(icon, size: 22)
          : image != null
          ? ClipOval(
              child: Image(
                image: image,
                width: 26,
                height: 26,
                fit: BoxFit.cover,
              ),
            )
          : null,
    );
  }

  final String? symbol;
  final String? selectedSymbol;
  final String? asset;
  final String? file;
  final String? network;
  final String? title;

  /// Accessibility label.
  final String? label;
  final Color? tint;
  final int? badge;

  /// When set, tapping the item opens a native menu of these entries instead
  /// of reporting a tap: the overflow control of the trailing bar.
  final List<GlassCapsuleMenuEntry>? menu;

  /// Drawn where there is no UIKit (widget tests, other platforms).
  final Widget? fallback;

  /// Whether the native capsule has something to draw for this item.
  bool get canShowNatively =>
      symbol != null ||
      asset != null ||
      file != null ||
      network != null ||
      title != null;

  Map<String, dynamic> toNativeMap() => <String, dynamic>{
    if (symbol != null) 'symbol': symbol,
    if (selectedSymbol != null) 'selectedSymbol': selectedSymbol,
    if (asset != null) 'asset': asset,
    if (file != null) 'file': file,
    if (network != null) 'network': network,
    if (title != null) 'title': title,
    if (label != null) 'label': label,
    if (tint != null) 'tint': tint!.toARGB32(),
    if (badge != null && badge! > 0) 'badge': badge,
    if (menu != null)
      'menu': [
        for (final entry in menu!)
          {
            'id': entry.id,
            'title': entry.title,
            if (entry.symbol != null) 'symbol': entry.symbol,
          },
      ],
  };
}

/// One entry of a [GlassCapsuleItem.menu].
@immutable
class GlassCapsuleMenuEntry {
  const GlassCapsuleMenuEntry({
    required this.id,
    required this.title,
    this.symbol,
  });

  /// Reported back through [IOS26GlassCapsule.onMenuTap].
  final int id;
  final String title;
  final String? symbol;
}

/// A vertical Liquid Glass capsule holding a column of icon buttons: the
/// shape the system gives each group of toolbar items, and the tab bar, in
/// the trailing bar of iPhone Duo. With a [selectedIndex] it behaves as a
/// tab bar and highlights that item.
class IOS26GlassCapsule extends StatefulWidget {
  const IOS26GlassCapsule({
    super.key,
    required this.items,
    required this.onTap,
    this.onMenuTap,
    this.selectedIndex,
    this.inset = 0,
    this.tint,
  });

  final List<GlassCapsuleItem> items;
  final ValueChanged<int> onTap;

  /// Called with the [GlassCapsuleMenuEntry.id] chosen from an item's menu.
  final ValueChanged<int>? onMenuTap;
  final int? selectedIndex;

  /// Space kept free above the first and below the last item.
  final double inset;

  /// Tint of a selected tab, or of every item when there is no selection.
  final Color? tint;

  /// Width of every control in the trailing bar, as measured on the system's
  /// own bar.
  static const double width = 48;

  /// Height of a capsule of [count] toolbar items.
  static double actionsHeight(int count) => 48.0 + (count - 1) * 52.0;

  /// Height of a tab capsule of [count] tabs, and the matching [inset].
  static double tabsHeight(int count) => tabsInset * 2 + count * 50.0;
  static const double tabsInset = 6;

  @override
  State<IOS26GlassCapsule> createState() => _IOS26GlassCapsuleState();
}

class _IOS26GlassCapsuleState extends State<IOS26GlassCapsule> {
  MethodChannel? _channel;
  Map<String, dynamic>? _sent;

  bool get _isDark =>
      MediaQuery.platformBrightnessOf(context) == Brightness.dark;

  Map<String, dynamic> get _params {
    final tint = widget.tint == null
        ? null
        : CupertinoDynamicColor.resolve(widget.tint!, context);
    return <String, dynamic>{
      'items': widget.items.map((i) => i.toNativeMap()).toList(),
      if (widget.selectedIndex != null) 'selectedIndex': widget.selectedIndex,
      'inset': widget.inset,
      'isDark': _isDark,
      if (tint != null) 'tint': tint.toARGB32(),
    };
  }

  @override
  void didUpdateWidget(IOS26GlassCapsule oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void dispose() {
    _channel?.setMethodCallHandler(null);
    super.dispose();
  }

  Future<void> _sync() async {
    final channel = _channel;
    if (channel == null) return;
    final params = _params;
    if (_sent != null && _sent.toString() == params.toString()) return;
    _sent = params;
    try {
      await channel.invokeMethod<void>('update', params);
    } on PlatformException {
      // The view went away mid-call.
    } on MissingPluginException {
      // Same.
    }
  }

  void _onCreated(int id) {
    _channel?.setMethodCallHandler(null);
    _channel = MethodChannel('adaptive_platform_ui/ios26_glass_capsule_$id')
      ..setMethodCallHandler((call) async {
        if (call.method == 'onItemTapped') {
          final index = (call.arguments as Map?)?['index'] as int?;
          if (index != null && index >= 0 && index < widget.items.length) {
            widget.onTap(index);
          }
        } else if (call.method == 'onMenuItemTapped') {
          final id = (call.arguments as Map?)?['id'] as int?;
          if (id != null) widget.onMenuTap?.call(id);
        }
      });
    // Catch up with anything that changed while the view was being created.
    _sync();
  }

  @override
  Widget build(BuildContext context) {
    if (defaultTargetPlatform != TargetPlatform.iOS) return _buildFallback();
    final params = _params;
    _sent ??= params;
    final glass = UiKitView(
      viewType: 'adaptive_platform_ui/ios26_glass_capsule',
      creationParams: params,
      creationParamsCodec: const StandardMessageCodec(),
      onPlatformViewCreated: _onCreated,
      hitTestBehavior: PlatformViewHitTestBehavior.opaque,
    );
    if (widget.items.every((item) => item.canShowNatively)) return glass;

    // An item with only a Flutter icon (an IconData or a custom widget) has
    // nothing the native side can draw. The glass and the button stay native;
    // the icon is laid over its cell and lets touches through.
    final label = CupertinoColors.label.resolveFrom(context);
    return Stack(
      fit: StackFit.expand,
      children: [
        glass,
        IgnorePointer(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: widget.inset),
            child: Column(
              children: [
                for (final item in widget.items)
                  Expanded(
                    child: Center(
                      child: item.canShowNatively
                          ? null
                          : IconTheme.merge(
                              data: IconThemeData(color: item.tint ?? label),
                              child: item.fallback ?? const SizedBox.shrink(),
                            ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFallback() {
    final label = CupertinoColors.label.resolveFrom(context);
    final tint = widget.tint ?? CupertinoTheme.of(context).primaryColor;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: CupertinoColors.systemFill.resolveFrom(context),
        borderRadius: BorderRadius.circular(IOS26GlassCapsule.width / 2),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: widget.inset),
        child: Column(
          children: [
            for (var i = 0; i < widget.items.length; i++)
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => widget.onTap(i),
                  child: Center(
                    child: IconTheme.merge(
                      data: IconThemeData(
                        color: i == widget.selectedIndex ? tint : label,
                      ),
                      child:
                          widget.items[i].fallback ??
                          Text(
                            widget.items[i].title ??
                                widget.items[i].symbol ??
                                widget.items[i].label ??
                                '',
                            style: TextStyle(fontSize: 10, color: label),
                            overflow: TextOverflow.ellipsis,
                          ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
