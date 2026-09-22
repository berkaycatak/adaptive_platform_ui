import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../adaptive_context_menu.dart';

/// Native iOS 26 context menu: a transparent platform view over [child] runs a
/// `UIContextMenuInteraction`, lifting a snapshot of [child] as the preview.
class IOS26ContextMenu extends StatefulWidget {
  /// Creates a native context menu around [child]
  const IOS26ContextMenu({
    super.key,
    required this.actions,
    required this.child,
  });

  /// Menu items shown on long press
  final List<AdaptiveContextMenuAction> actions;

  /// The widget that opens the menu and is lifted as the preview
  final Widget child;

  @override
  State<IOS26ContextMenu> createState() => _IOS26ContextMenuState();
}

class _IOS26ContextMenuState extends State<IOS26ContextMenu> {
  final _boundaryKey = GlobalKey();
  MethodChannel? _channel;
  bool? _lastIsDark;

  bool get _isDark =>
      MediaQuery.platformBrightnessOf(context) == Brightness.dark;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncBrightnessIfNeeded();
  }

  @override
  void dispose() {
    _channel?.setMethodCallHandler(null);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final labels = widget.actions.map((a) => a.title).toList();
    return Listener(
      onPointerDown: (_) => _sendPreview(),
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          RepaintBoundary(key: _boundaryKey, child: widget.child),
          Positioned.fill(
            child: UiKitView(
              key: ValueKey(labels.join('_')),
              viewType: 'adaptive_platform_ui/ios26_context_menu',
              creationParams: <String, dynamic>{
                'labels': labels,
                'sfSymbols': widget.actions
                    .map((a) => a.icon is String ? a.icon as String : '')
                    .toList(),
                'enabled': widget.actions.map((a) => !a.isDisabled).toList(),
                'isDestructive': widget.actions
                    .map((a) => a.isDestructive)
                    .toList(),
                'isDark': _isDark,
              },
              creationParamsCodec: const StandardMessageCodec(),
              hitTestBehavior: PlatformViewHitTestBehavior.translucent,
              gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                Factory<LongPressGestureRecognizer>(
                  () => LongPressGestureRecognizer(),
                ),
              },
              onPlatformViewCreated: _onCreated,
            ),
          ),
        ],
      ),
    );
  }

  void _onCreated(int id) {
    _channel = MethodChannel('adaptive_platform_ui/ios26_context_menu_$id')
      ..setMethodCallHandler(_onMethodCall);
    _lastIsDark = _isDark;
  }

  Future<dynamic> _onMethodCall(MethodCall call) async {
    if (call.method == 'itemSelected') {
      final index = ((call.arguments as Map?)?['index'] as num?)?.toInt();
      if (index != null) widget.actions[index].onPressed();
    }
    return null;
  }

  /// Snapshots the child on touch-down. Flutter holds the touch until the long
  /// press is recognised, so the image is on the native side before the menu opens.
  Future<void> _sendPreview() async {
    final channel = _channel;
    final boundary =
        _boundaryKey.currentContext?.findRenderObject()
            as RenderRepaintBoundary?;
    if (channel == null || boundary == null) return;
    final pixelRatio = MediaQuery.devicePixelRatioOf(context);
    final image = await boundary.toImage(pixelRatio: pixelRatio);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    if (bytes == null) return;
    try {
      await channel.invokeMethod('setPreview', {
        'image': bytes.buffer.asUint8List(),
      });
    } catch (_) {}
  }

  Future<void> _syncBrightnessIfNeeded() async {
    final channel = _channel;
    if (channel == null || _lastIsDark == _isDark) return;
    _lastIsDark = _isDark;
    try {
      await channel.invokeMethod('setBrightness', {'isDark': _lastIsDark});
    } catch (_) {}
  }
}
