import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import '../adaptive_app_bar_action.dart';

/// Native iOS 26 UINavigationBar widget using platform views
/// Implements Liquid Glass design with native blur effects
class IOS26NativeToolbar extends StatefulWidget {
  const IOS26NativeToolbar({
    super.key,
    this.title,
    this.leading,
    this.leadingText,
    this.actions,
    this.onLeadingTap,
    this.onActionTap,
    this.height = 44.0,
  });

  final String? title;
  final Widget? leading;
  final String? leadingText;
  final List<AdaptiveAppBarAction>? actions;
  final VoidCallback? onLeadingTap;
  final ValueChanged<int>? onActionTap;
  final double height;

  @override
  State<IOS26NativeToolbar> createState() => _IOS26NativeToolbarState();
}

class _IOS26NativeToolbarState extends State<IOS26NativeToolbar> {
  MethodChannel? _channel;
  bool? _lastIsDark;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncBrightnessIfNeeded();
  }

  Future<void> _syncBrightnessIfNeeded() async {
    final ch = _channel;
    if (ch == null) return;
    final isDark = MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    if (_lastIsDark != isDark) {
      try {
        await ch.invokeMethod('setBrightness', {'isDark': isDark});
        _lastIsDark = isDark;
      } catch (e) {
        // Ignore errors if platform view is not yet ready
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Only use native toolbar on iOS
    if (defaultTargetPlatform != TargetPlatform.iOS) {
      return _buildFallbackToolbar();
    }

    final safePadding = MediaQuery.of(context).padding.top;

    // Priority: custom leading widget > leadingText
    // If custom leading widget provided, don't send leadingText to native
    final creationParams = <String, dynamic>{
      if (widget.title != null) 'title': widget.title!,
      if (widget.leading == null && widget.leadingText != null)
        'leading': widget.leadingText!,
      if (widget.actions != null && widget.actions!.isNotEmpty)
        'actions': widget.actions!.map((a) => a.toNativeMap()).toList(),
      'isDark': MediaQuery.platformBrightnessOf(context) == Brightness.dark,
    };

    // iOS 26 native scroll edge effect - no manual gradient needed
    return SizedBox(
      height: widget.height + safePadding,
      child: Stack(
        children: [
          UiKitView(
            viewType: 'adaptive_platform_ui/ios26_toolbar',
            creationParams: creationParams,
            creationParamsCodec: const StandardMessageCodec(),
            onPlatformViewCreated: _onPlatformViewCreated,
            hitTestBehavior: PlatformViewHitTestBehavior.translucent,
          ),
          // Custom leading widget overlay
          if (widget.leading != null)
            Positioned(
              left: 8,
              top: safePadding,
              bottom: 0,
              child: Align(
                alignment: Alignment.centerLeft,
                child: widget.leading!,
              ),
            ),
        ],
      ),
    );
  }

  void _onPlatformViewCreated(int id) {
    _channel = MethodChannel('adaptive_platform_ui/ios26_toolbar_$id');
    _channel!.setMethodCallHandler(_handleMethodCall);
  }

  Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onLeadingTapped':
        widget.onLeadingTap?.call();
        break;
      case 'onActionTapped':
        if (call.arguments is Map) {
          final index = (call.arguments as Map)['index'] as int?;
          if (index != null) widget.onActionTap?.call(index);
        }
        break;
    }
  }

  /// Fallback toolbar using CupertinoNavigationBar for non-iOS or older iOS
  Widget _buildFallbackToolbar() {
    return CupertinoNavigationBar(
      middle: widget.title != null ? Text(widget.title!) : null,
      leading: widget.leading,
      trailing: widget.actions != null && widget.actions!.isNotEmpty
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: widget.actions!.map((action) {
                return CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: action.onPressed,
                  child: action.icon != null
                      ? Icon(action.icon)
                      : Text(action.title ?? ''),
                );
              }).toList(),
            )
          : null,
    );
  }
}
