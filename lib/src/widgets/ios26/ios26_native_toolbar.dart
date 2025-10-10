import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

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
  final List<Widget>? actions;
  final VoidCallback? onLeadingTap;
  final ValueChanged<int>? onActionTap;
  final double height;

  @override
  State<iOS26NativeToolbar> createState() => _iOS26NativeToolbarState();
}

class _iOS26NativeToolbarState extends State<iOS26NativeToolbar> {
  MethodChannel? _channel;

  @override
  void didUpdateWidget(iOS26NativeToolbar oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Update toolbar if title, leading, or actions changed
    if (oldWidget.title != widget.title ||
        oldWidget.leading != widget.leading ||
        oldWidget.leadingText != widget.leadingText ||
        oldWidget.actions != widget.actions) {
      _updateToolbar();
    }
  }

  void _updateToolbar() {
    if (_channel == null) return;

    final params = <String, dynamic>{
      if (widget.title != null) 'title': widget.title!,
      if (widget.leadingText != null) 'leading': widget.leadingText!,
      if (widget.leading != null) 'leading': _extractText(widget.leading!),
      if (widget.actions != null && widget.actions!.isNotEmpty)
        'actions': widget.actions!.map((action) => _extractButtonInfo(action)).toList(),
    };

    _channel!.invokeMethod('updateToolbar', params);
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
      if (widget.leading != null) 'leading': _extractText(widget.leading!),
      if (widget.actions != null && widget.actions!.isNotEmpty)
        'actions': widget.actions!.map((action) => _extractButtonInfo(action)).toList(),
    };

    return SizedBox(
      height: widget.height + MediaQuery.of(context).padding.top,
      child: UiKitView(
        viewType: 'adaptive_platform_ui/ios26_toolbar',
        creationParams: creationParams,
        creationParamsCodec: const StandardMessageCodec(),
        onPlatformViewCreated: _onPlatformViewCreated,
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
          final args = call.arguments as Map;
          final index = args['index'] as int?;
          if (index != null) {
            widget.onActionTap?.call(index);
          }
        }
        break;
    }
  }

  Map<String, dynamic> _extractButtonInfo(Widget widget) {
    // Try to extract from Text widget
    if (widget is Text) {
      if (widget.data != null) {
        return {'title': widget.data!};
      }
    }

    // Try to extract from CupertinoButton
    if (widget is CupertinoButton) {
      final child = widget.child;
      if (child is Icon) {
        // Extract icon name from IconData
        return {'icon': 'info.circle'}; // Default SF Symbol
      }
      if (child is Text && child.data != null) {
        return {'title': child.data!};
      }
      if (child is Row) {
        // For back button with icon + text
        return {'title': 'Back'};
      }
    }

    // Default: return empty
    return {};
  }

  String _extractText(Widget widget) {
    final info = _extractButtonInfo(widget);
    return info['title'] ?? '';
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
              children: widget.actions!,
            ),
        ],
      ),
    );
  }
}
