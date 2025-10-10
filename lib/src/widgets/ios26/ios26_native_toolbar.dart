import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import '../adaptive_app_bar_action.dart';

/// Native iOS 26 UIToolbar widget using platform views
/// Implements Liquid Glass design with blur effects
class iOS26NativeToolbar extends StatefulWidget {
  const iOS26NativeToolbar({
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
  State<iOS26NativeToolbar> createState() => _iOS26NativeToolbarState();
}

class _iOS26NativeToolbarState extends State<iOS26NativeToolbar> {
  MethodChannel? _channel;
  String? _lastTitle;
  String? _lastLeadingText;
  List<AdaptiveAppBarAction>? _lastActions;
  late final Key _persistentKey;

  @override
  void initState() {
    super.initState();
    // Create a persistent key that won't change across rebuilds
    _persistentKey = UniqueKey();
  }

  @override
  void didUpdateWidget(iOS26NativeToolbar oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncPropsToNativeIfNeeded();
  }

  Future<void> _syncPropsToNativeIfNeeded() async {
    final ch = _channel;
    if (ch == null) return;

    bool needsUpdate = false;
    final params = <String, dynamic>{};

    // Check title
    if (_lastTitle != widget.title) {
      params['title'] = widget.title ?? '';
      _lastTitle = widget.title;
      needsUpdate = true;
    }

    // Check leading text - send null/empty explicitly when removed
    if (_lastLeadingText != widget.leadingText) {
      if (widget.leadingText != null) {
        params['leading'] = widget.leadingText!;
      } else {
        // Explicitly send null to clear the leading button
        params['clearLeading'] = true;
      }
      _lastLeadingText = widget.leadingText;
      needsUpdate = true;
    }

    // Check actions (compare by reference or serialize)
    if (_lastActions != widget.actions) {
      if (widget.actions != null && widget.actions!.isNotEmpty) {
        params['actions'] = widget.actions!.map((action) => action.toNativeMap()).toList();
      } else {
        params['actions'] = [];
      }
      _lastActions = widget.actions;
      needsUpdate = true;
    }

    if (needsUpdate) {
      await ch.invokeMethod('updateToolbar', params);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Only use native toolbar on iOS 26+
    if (defaultTargetPlatform != TargetPlatform.iOS) {
      return _buildFallbackToolbar();
    }

    final creationParams = <String, dynamic>{
      if (widget.title != null) 'title': widget.title!,
      if (widget.leadingText != null) 'leading': widget.leadingText!,
      if (widget.leading != null) 'leading': '',
      if (widget.actions != null && widget.actions!.isNotEmpty)
        'actions': widget.actions!.map((action) => action.toNativeMap()).toList(),
    };

    return SizedBox(
      height: widget.height + MediaQuery.of(context).padding.top,
      child: UiKitView(
        key: _persistentKey,
        viewType: 'adaptive_platform_ui/ios26_toolbar',
        creationParams: creationParams,
        creationParamsCodec: const StandardMessageCodec(),
        onPlatformViewCreated: _onPlatformViewCreated,
        hitTestBehavior: PlatformViewHitTestBehavior.opaque,
        // Enable Hybrid Composition mode for better layer integration
        gestureRecognizers: const <Factory<OneSequenceGestureRecognizer>>{},
      ),
    );
  }

  void _onPlatformViewCreated(int id) {
    _channel = MethodChannel('adaptive_platform_ui/ios26_toolbar_$id');
    _channel!.setMethodCallHandler(_handleMethodCall);

    // Cache initial values to prevent unnecessary updates
    _lastTitle = widget.title;
    _lastLeadingText = widget.leadingText;
    _lastActions = widget.actions;
  }

  Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onLeadingTapped':
        widget.onLeadingTap?.call();
        break;
      case 'onActionTapped':
        if (call.arguments is Map) {
          final args = call.arguments as Map;
          final index = args['index'] as int?;
          if (index != null) {
            widget.onActionTap?.call(index);
          }
        }
        break;
    }
  }

  /// Fallback toolbar for non-iOS platforms or older iOS versions
  Widget _buildFallbackToolbar() {
    return Container(
      height: widget.height + MediaQuery.of(context).padding.top,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top,
        left: 16,
        right: 16,
      ),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground.resolveFrom(context),
        border: Border(
          bottom: BorderSide(
            color: CupertinoColors.separator.resolveFrom(context),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          if (widget.leading != null) widget.leading!,
          const Spacer(),
          if (widget.title != null)
            Text(
              widget.title!,
              style: CupertinoTheme.of(context).textTheme.navTitleTextStyle,
            ),
          const Spacer(),
          if (widget.actions != null && widget.actions!.isNotEmpty)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: widget.actions!.map((action) {
                return CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: action.onPressed,
                  child: action.title != null
                      ? Text(action.title!)
                      : const Icon(CupertinoIcons.circle),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}
