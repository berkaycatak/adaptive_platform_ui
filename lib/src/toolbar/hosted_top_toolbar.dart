import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import '../widgets/adaptive_app_bar_action.dart';
import 'toolbar_blend.dart';
import 'toolbar_registry.dart';

/// Height of the toolbar's content area, excluding the status bar.
const double kHostedToolbarHeight = 44.0;

/// What one page contributes to the top toolbar.
@immutable
class TopToolbarContent {
  const TopToolbarContent({
    this.title,
    this.titleOverlay,
    this.customLeading,
    this.impliesBack = false,
    this.actions = const <AdaptiveAppBarAction>[],
    this.tint,
    this.navigator,
  });

  /// No page owns the chrome, the page has no toolbar, or it draws a
  /// non-native bar of its own: nothing to show.
  ///
  /// With [titleOnly] the controls are left out, because the iPhone Duo
  /// vertical bar shows them instead.
  factory TopToolbarContent.of(ToolbarEntry? entry, {bool titleOnly = false}) {
    final appBar = entry?.appBar;
    if (entry == null || appBar == null || !appBar.useNativeToolbar) {
      return const TopToolbarContent();
    }
    return TopToolbarContent(
      title: appBar.title,
      titleOverlay: entry.titleOverlay,
      customLeading: titleOnly ? null : appBar.leading,
      impliesBack: !titleOnly && entry.impliesBackButton,
      actions: titleOnly
          ? const <AdaptiveAppBarAction>[]
          : appBar.actions ?? const <AdaptiveAppBarAction>[],
      tint: appBar.tintColor,
      navigator: entry.navigator,
    );
  }

  final String? title;

  /// A Flutter-drawn title (custom widget, or title with subtitle). The
  /// native title is left empty while one is shown.
  final Widget? titleOverlay;
  final Widget? customLeading;
  final bool impliesBack;
  final List<AdaptiveAppBarAction> actions;
  final Color? tint;
  final NavigatorState? navigator;

  bool get isEmpty =>
      title == null &&
      titleOverlay == null &&
      customLeading == null &&
      !impliesBack &&
      actions.isEmpty;

  /// What the native bar is told to show. Flutter-drawn parts are left out.
  Map<String, dynamic> toNativeParams(int? resolvedTint) => <String, dynamic>{
    if (title != null && titleOverlay == null) 'title': title,
    // An empty string asks for the chevron.
    if (impliesBack && customLeading == null) 'leading': '',
    if (actions.isNotEmpty)
      'actions': actions.map((a) => a.toNativeMap()).toList(),
    if (resolvedTint != null) 'tint': resolvedTint,
  };
}

/// Decides what to send to the native bar, and with which item transition,
/// each time the chrome changes. Kept free of widgets so it can be tested.
class TopToolbarNativeSync {
  Map<String, dynamic>? _sent;
  int _sentSwapCount = 0;

  /// The `setItems` arguments to send now, or null when the native bar is
  /// already showing [params].
  ///
  /// The owner changing to another page plays the system item transition
  /// once, in the direction the navigation went; the same page updating its
  /// own items applies without one.
  Map<String, dynamic>? next(
    Map<String, dynamic> params, {
    required int swapCount,
    required ToolbarSwapKind swapKind,
  }) {
    final ownerChanged = swapCount != _sentSwapCount;
    if (!ownerChanged && _sent != null && _deepEquals(_sent, params)) {
      return null;
    }
    final first = _sent == null;
    _sent = params;
    _sentSwapCount = swapCount;
    return <String, dynamic>{
      ...params,
      'transition': first || !ownerChanged
          ? 'none'
          : switch (swapKind) {
              ToolbarSwapKind.push => 'push',
              ToolbarSwapKind.pop => 'pop',
              ToolbarSwapKind.swap => 'fade',
            },
    };
  }

  /// Forgets what was sent, e.g. because the platform view was recreated.
  void reset() => _sent = null;

  static bool _deepEquals(Object? a, Object? b) {
    if (a is Map && b is Map) {
      if (a.length != b.length) return false;
      for (final key in a.keys) {
        if (!b.containsKey(key) || !_deepEquals(a[key], b[key])) return false;
      }
      return true;
    }
    if (a is List && b is List) {
      if (a.length != b.length) return false;
      for (var i = 0; i < a.length; i++) {
        if (!_deepEquals(a[i], b[i])) return false;
      }
      return true;
    }
    return a == b;
  }
}

/// The one top toolbar of the app: a single native Liquid Glass navigation
/// bar that stays where it is while pages come and go underneath it. Only
/// its items change, and UIKit animates that change the way it does inside a
/// UINavigationController.
class HostedTopToolbar extends StatefulWidget {
  const HostedTopToolbar({
    super.key,
    required this.blend,
    this.titleOnly = false,
  });

  final ToolbarBlend blend;

  /// True on iPhone Duo, where the controls live in the vertical bar.
  final bool titleOnly;

  @override
  State<HostedTopToolbar> createState() => _HostedTopToolbarState();
}

class _HostedTopToolbarState extends State<HostedTopToolbar> {
  final TopToolbarNativeSync _sync = TopToolbarNativeSync();
  MethodChannel? _channel;
  bool? _sentIsDark;

  ToolbarBlend get _blend => widget.blend;

  @override
  void initState() {
    super.initState();
    _blend.addListener(_onBlendChanged);
  }

  @override
  void didUpdateWidget(HostedTopToolbar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.blend != widget.blend) {
      oldWidget.blend.removeListener(_onBlendChanged);
      widget.blend.addListener(_onBlendChanged);
    }
    _pushToNative();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _pushToNative();
  }

  @override
  void dispose() {
    _blend.removeListener(_onBlendChanged);
    _channel?.setMethodCallHandler(null);
    super.dispose();
  }

  void _onBlendChanged() {
    if (!mounted) return;
    _pushToNative();
    setState(() {});
  }

  TopToolbarContent get _ownerContent =>
      TopToolbarContent.of(_blend.owner, titleOnly: widget.titleOnly);

  bool get _isDark =>
      MediaQuery.platformBrightnessOf(context) == Brightness.dark;

  int? _resolveTint(Color? color) {
    if (color == null) return null;
    final resolved = CupertinoDynamicColor.maybeResolve(color, context)!;
    return resolved.toARGB32();
  }

  Future<void> _pushToNative() async {
    final channel = _channel;
    if (channel == null) return;
    final content = _ownerContent;
    final args = _sync.next(
      content.toNativeParams(_resolveTint(content.tint)),
      swapCount: _blend.swapCount,
      swapKind: _blend.lastSwapKind,
    );
    final isDark = _isDark;
    try {
      if (_sentIsDark != isDark) {
        _sentIsDark = isDark;
        await channel.invokeMethod<void>('setBrightness', {'isDark': isDark});
      }
      if (args != null) await channel.invokeMethod<void>('setItems', args);
    } on PlatformException {
      // The platform view went away mid-call; the next one starts afresh.
    } on MissingPluginException {
      // Same.
    }
  }

  void _onPlatformViewCreated(int id) {
    _channel?.setMethodCallHandler(null);
    _channel = MethodChannel('adaptive_platform_ui/ios26_toolbar_$id')
      ..setMethodCallHandler(_onNativeCall);
    // Creation params already carry the first content; remember them so the
    // same items are not sent again with a transition.
    final content = _ownerContent;
    _sync
      ..reset()
      ..next(
        content.toNativeParams(_resolveTint(content.tint)),
        swapCount: _blend.swapCount,
        swapKind: _blend.lastSwapKind,
      );
    _sentIsDark = _isDark;
  }

  Future<dynamic> _onNativeCall(MethodCall call) async {
    if (_blend.ownerIsCovered) return;
    final content = _ownerContent;
    switch (call.method) {
      case 'onLeadingTapped':
        await content.navigator?.maybePop();
      case 'onActionTapped':
        final index = (call.arguments as Map?)?['index'] as int?;
        if (index != null && index >= 0 && index < content.actions.length) {
          content.actions[index].onPressed();
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.viewPaddingOf(context).top;
    final owner = _ownerContent;
    final upperEntry = _blend.upper;
    final lowerEntry = _blend.lower;
    final upper = TopToolbarContent.of(upperEntry, titleOnly: widget.titleOnly);
    final lower = TopToolbarContent.of(lowerEntry, titleOnly: widget.titleOnly);

    // Nothing to show at either end of the blend: step out of the way, but
    // keep the native bar alive so it is there, unmoved, for the next page.
    final hidden = owner.isEmpty && upper.isEmpty && lower.isEmpty;

    return Align(
      alignment: Alignment.topCenter,
      child: SizedBox(
        height: kHostedToolbarHeight + topInset,
        child: IgnorePointer(
          ignoring: hidden || _blend.ownerIsCovered,
          child: AnimatedOpacity(
            opacity: hidden ? 0 : 1,
            duration: kToolbarItemSwapDuration,
            child: FadeTransition(
              opacity: _blend.chromeOpacity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _buildNativeBar(owner),
                  // Flutter-drawn parts follow the same blend as the rest of
                  // the chrome. Keyed, so they survive its start and end.
                  if (lowerEntry != null)
                    _overlays(
                      key: ValueKey<Object>(lowerEntry.id),
                      content: lower,
                      opacity: _blend.lowerOpacity,
                      interactive: !_blend.upperOwns,
                      topInset: topInset,
                    ),
                  if (upperEntry != null)
                    _overlays(
                      key: ValueKey<Object>(upperEntry.id),
                      content: upper,
                      opacity: _blend.upperOpacity,
                      interactive: _blend.upperOwns,
                      topInset: topInset,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNativeBar(TopToolbarContent owner) {
    if (defaultTargetPlatform != TargetPlatform.iOS) {
      return _FallbackBar(
        content: owner,
        onBack: () => owner.navigator?.maybePop(),
      );
    }
    return UiKitView(
      viewType: 'adaptive_platform_ui/ios26_toolbar',
      // Only read when the view is created; later content goes via setItems.
      creationParams: <String, dynamic>{
        ...owner.toNativeParams(_resolveTint(owner.tint)),
        'isDark': _isDark,
      },
      creationParamsCodec: const StandardMessageCodec(),
      onPlatformViewCreated: _onPlatformViewCreated,
      hitTestBehavior: PlatformViewHitTestBehavior.translucent,
    );
  }

  Widget _overlays({
    required Key key,
    required TopToolbarContent content,
    required Animation<double> opacity,
    required bool interactive,
    required double topInset,
  }) {
    return FadeTransition(
      key: key,
      opacity: opacity,
      child: IgnorePointer(
        ignoring: !interactive,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (content.customLeading != null)
              Positioned(left: 16, bottom: 3, child: content.customLeading!),
            if (content.titleOverlay != null)
              Positioned(
                left: 0,
                right: 0,
                top: topInset,
                bottom: 0,
                child: Center(child: content.titleOverlay),
              ),
          ],
        ),
      ),
    );
  }
}

/// Stand-in for the native bar where there is no UIKit (widget tests).
class _FallbackBar extends StatelessWidget {
  const _FallbackBar({required this.content, required this.onBack});

  final TopToolbarContent content;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: SizedBox(
        height: kHostedToolbarHeight,
        child: Row(
          children: [
            if (content.impliesBack && content.customLeading == null)
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: onBack,
                child: const Icon(CupertinoIcons.chevron_left),
              ),
            Expanded(
              child: Center(
                child: content.titleOverlay == null && content.title != null
                    ? Text(content.title!)
                    : null,
              ),
            ),
            for (final action in content.actions)
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: action.onPressed,
                child: action.icon != null
                    ? Icon(action.icon)
                    : Text(action.title ?? ''),
              ),
          ],
        ),
      ),
    );
  }
}
