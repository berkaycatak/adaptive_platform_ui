import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import '../adaptive_app_bar_action.dart';
import '../adaptive_scaffold.dart';
import 'ios26_popup_menu_button.dart';

/// One control inside an [IOS26GlassCapsule].
@immutable
class GlassCapsuleItem {
  const GlassCapsuleItem({
    this.symbol,
    this.selectedSymbol,
    this.asset,
    this.file,
    this.network,
    this.image,
    this.title,
    this.label,
    this.tint,
    this.badge,
    this.fallback,
    this.menu,
  });

  /// A toolbar action. Needs an SF Symbol or a title; see [canShow].
  /// Menu entries report `menuIdBase + index` through onMenuTap
  factory GlassCapsuleItem.fromAction(
    AdaptiveAppBarAction action, {
    int menuIdBase = 0,
  }) => GlassCapsuleItem(
    symbol: action.iosSymbol,
    image: action.iconImage,
    title: action.iosSymbol == null ? action.title : null,
    label: action.effectiveLabel,
    tint: action.tintColor,
    badge: action.badgeCount,
    fallback:
        action.imageWidget ??
        action.iconWidget ??
        (action.icon != null ? Icon(action.icon, size: 22) : null),
    menu: action.hasMenu
        ? [
            for (var i = 0; i < action.menuItems!.length; i++)
              if (action.menuItems![i] case final AdaptivePopupMenuItem item)
                GlassCapsuleMenuEntry(
                  id: menuIdBase + i,
                  title: item.label,
                  symbol: item.icon is String ? item.icon as String : null,
                ),
          ]
        : null,
  );

  /// A tab. The icon may be an SF Symbol name, an asset path, or an
  /// [AssetImage], [FileImage] or [NetworkImage] (shown as a round avatar).
  /// [fallback] replaces the icon drawn where the capsule is not native.
  factory GlassCapsuleItem.fromDestination(
    AdaptiveNavigationDestination d, {
    Widget? fallback,
  }) {
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
      fallback:
          fallback ??
          (icon is IconData
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
              : null),
    );
  }

  final String? symbol;
  final String? selectedSymbol;
  final String? asset;
  final String? file;
  final String? network;

  /// PNG or JPEG bytes shown round, as an avatar, in place of [symbol].
  final Uint8List? image;
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
      image != null ||
      title != null;

  Map<String, dynamic> toNativeMap() => <String, dynamic>{
    if (symbol != null) 'symbol': symbol,
    if (selectedSymbol != null) 'selectedSymbol': selectedSymbol,
    if (asset != null) 'asset': asset,
    if (file != null) 'file': file,
    if (network != null) 'network': network,
    if (image != null) 'image': image,
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
    this.showLabels = false,
    this.expandOnLensDrag = false,
    this.native = true,
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

  /// Whether each item shows its [GlassCapsuleItem.label] under its icon, as
  /// a navigation rail does. Give the capsule [labeledWidth] and
  /// [labeledTabsHeight] for it.
  final bool showLabels;

  /// Whether the capsule grows while its lens is held, and shows each item's
  /// label under its icon until it is let go, as the vertical tab bar of the
  /// iPhone Duo does: wider ([labeledWidth]) and [lensItemGrowth] taller a
  /// tab, around the place it has (what is beside it does not move). See
  /// [lensExpandedSize].
  final bool expandOnLensDrag;

  /// Whether the capsule is the native view. Off, it is drawn by Flutter with
  /// the same layout, for a moment when a native view would be wrong (under
  /// another route or a dimming overlay, in a hero flight).
  final bool native;

  /// On the selected item of the capsule drawn by Flutter.
  @visibleForTesting
  static const Key fallbackSelectionKey = ValueKey(
    'ios26_glass_capsule_fallback_selection',
  );

  /// Width of a capsule that shows labels.
  static const double labeledWidth = 72;

  /// Height of a tab capsule of [count] labeled tabs, with [tabsInset].
  static double labeledTabsHeight(int count) => tabsInset * 2 + count * 60.0;

  /// How much taller each item gets while the lens is held
  /// ([expandOnLensDrag]), for its label under the icon.
  static const double lensItemGrowth = 6;

  /// How long the capsule takes to grow, or to go back, around a held lens.
  static const Duration lensExpandDuration = Duration(milliseconds: 320);

  /// The size of a capsule of [count] items, [compact] at rest, while its lens
  /// is held ([expandOnLensDrag]): as wide as a labeled capsule (never
  /// narrower than it is) and [lensItemGrowth] taller a tab.
  static Size lensExpandedSize(Size compact, int count) => Size(
    math.max(compact.width, labeledWidth),
    compact.height + count * lensItemGrowth,
  );

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

  /// Whether the native view reports its lens held, so the capsule is grown
  /// ([IOS26GlassCapsule.expandOnLensDrag]).
  bool _lensHeld = false;

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
      if (widget.showLabels) 'showLabels': true,
      if (widget.expandOnLensDrag) 'expandOnLensDrag': true,
      'isDark': _isDark,
      if (tint != null) 'tint': tint.toARGB32(),
    };
  }

  @override
  void didUpdateWidget(IOS26GlassCapsule oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Without the native view (drawn by Flutter for a moment) no lens is held.
    if (!widget.native || !widget.expandOnLensDrag) _lensHeld = false;
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
        } else if (call.method == 'onLensDrag') {
          final held = (call.arguments as Map?)?['active'] == true;
          if (mounted && widget.expandOnLensDrag && held != _lensHeld) {
            setState(() => _lensHeld = held);
          }
        }
      });
    // Catch up with anything that changed while the view was being created.
    _sync();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.native || defaultTargetPlatform != TargetPlatform.iOS) {
      return _buildFallback();
    }
    final params = _params;
    _sent ??= params;
    final glass = UiKitView(
      viewType: 'adaptive_platform_ui/ios26_glass_capsule',
      creationParams: params,
      creationParamsCodec: const StandardMessageCodec(),
      onPlatformViewCreated: _onCreated,
      hitTestBehavior: PlatformViewHitTestBehavior.opaque,
    );
    if (widget.items.every((item) => item.canShowNatively)) {
      return _growingAroundLens(glass);
    }

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

  /// [glass] grown to [IOS26GlassCapsule.lensExpandedSize] while the lens is
  /// held, around the place it is given, which keeps its size: the native
  /// view draws its labels in the room it gets. The touch that holds the lens
  /// is already the native view's, so the room outside its place needs none.
  Widget _growingAroundLens(Widget glass) {
    if (!widget.expandOnLensDrag) return glass;
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : IOS26GlassCapsule.lensExpandDuration;
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.biggest;
        if (!compact.isFinite) return glass;
        final target = _lensHeld
            ? IOS26GlassCapsule.lensExpandedSize(compact, widget.items.length)
            : compact;
        return OverflowBox(
          minWidth: 0,
          minHeight: 0,
          maxWidth: double.infinity,
          maxHeight: double.infinity,
          child: TweenAnimationBuilder<Size?>(
            tween: SizeTween(end: target),
            duration: duration,
            // Out quickly, with a touch of overshoot, as the glass does.
            curve: _lensHeld ? Curves.easeOutBack : Curves.easeOutCubic,
            builder: (context, size, child) =>
                SizedBox.fromSize(size: size ?? compact, child: child),
            child: glass,
          ),
        );
      },
    );
  }

  /// The capsule drawn by Flutter: a blurred, tinted pill with the same cells,
  /// the selected one highlighted, as the native view lays them out.
  Widget _buildFallback() {
    final label = CupertinoColors.label.resolveFrom(context);
    // The native capsule tints a selected tab system blue unless it is told
    // otherwise, not with the app's primary color.
    final tint = widget.tint ?? CupertinoColors.systemBlue.resolveFrom(context);
    // With no selection (a capsule of actions) the native one leaves the
    // controls in the label color unless told otherwise: blue is for a tab.
    final restingTint = widget.tint ?? label;
    final dark = CupertinoTheme.brightnessOf(context) == Brightness.dark;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : IOS26GlassCapsule.width;
        final radius = BorderRadius.circular(width / 2);
        return ClipRRect(
          borderRadius: radius,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: dark ? const Color(0x1FFFFFFF) : const Color(0xBFFFFFFF),
                borderRadius: radius,
                border: Border.all(
                  color: dark
                      ? const Color(0x2EFFFFFF)
                      : const Color(0x14000000),
                  width: 0.5,
                ),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: widget.inset),
                child: Column(
                  children: [
                    for (var i = 0; i < widget.items.length; i++)
                      Expanded(
                        child: _fallbackCell(
                          i,
                          width,
                          label,
                          tint,
                          restingTint,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _fallbackCell(
    int i,
    double width,
    Color label,
    Color tint,
    Color restingTint,
  ) {
    final item = widget.items[i];
    final selected = i == widget.selectedIndex;
    final color = widget.selectedIndex == null
        ? (item.tint ?? restingTint)
        : (selected ? (item.tint ?? tint) : label);
    final badge = item.badge;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => widget.onTap(i),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Padding(
            // As the native highlight: 6 narrower than the capsule.
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: DecoratedBox(
              key: selected ? IOS26GlassCapsule.fallbackSelectionKey : null,
              decoration: BoxDecoration(
                color: selected ? label.withValues(alpha: 0.1) : null,
                borderRadius: BorderRadius.circular(width / 2),
              ),
              child: Center(
                child: IconTheme.merge(
                  data: IconThemeData(color: color),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      item.fallback ??
                          Text(
                            item.title ?? item.symbol ?? item.label ?? '',
                            style: TextStyle(fontSize: 10, color: label),
                            overflow: TextOverflow.ellipsis,
                          ),
                      if (widget.showLabels && item.label != null)
                        Text(
                          item.label!,
                          style: TextStyle(fontSize: 10, color: color),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (badge != null && badge > 0)
            // As the native badge: 11 to the right of the cell's center and 12
            // above it, over the glass.
            Transform.translate(
              offset: const Offset(11, -12),
              child: _FallbackBadge(count: badge),
            ),
        ],
      ),
    );
  }
}

/// The count on an item of the capsule drawn by Flutter: the native one is a
/// red pill, 18 tall, with the count capped at "99+".
class _FallbackBadge extends StatelessWidget {
  const _FallbackBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final text = count > 99 ? '99+' : '$count';
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: CupertinoColors.systemRed,
          borderRadius: BorderRadius.circular(9),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
          child: Center(
            widthFactor: 1,
            heightFactor: 1,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                text,
                style: const TextStyle(
                  color: CupertinoColors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  height: 1.1,
                  decoration: TextDecoration.none,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
