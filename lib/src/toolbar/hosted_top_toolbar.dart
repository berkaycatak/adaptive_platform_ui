import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';

import '../style/sf_symbol.dart';
import '../widgets/adaptive_app_bar_action.dart';
import '../widgets/adaptive_button.dart';
import '../widgets/ios26/ios26_native_toolbar.dart';
import 'duo_vertical_bar.dart';
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
}

/// The one top toolbar of the app. It stays where it is while pages come and
/// go underneath it; only its items change.
///
/// It works exactly like the iPhone Duo vertical bar: every page involved in
/// a transition gets a layer of its own (here a native Liquid Glass
/// navigation bar), the layers are blended as [ToolbarBlend] dictates, so the
/// outgoing items fade out before the incoming ones fade in, in step with the
/// route transition and with a back swipe. A back button that both pages show
/// is one control in a layer of its own and stays put.
class HostedTopToolbar extends StatelessWidget {
  const HostedTopToolbar({
    super.key,
    required this.blend,
    this.titleOnly = false,
  });

  final ToolbarBlend blend;

  /// True on iPhone Duo, where the controls live in the vertical bar.
  final bool titleOnly;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(listenable: blend, builder: _build);
  }

  Widget _build(BuildContext context, Widget? _) {
    final topInset = MediaQuery.viewPaddingOf(context).top;
    final upperEntry = blend.upper;
    final lowerEntry = blend.lower;
    final upper = TopToolbarContent.of(upperEntry, titleOnly: titleOnly);
    final lower = TopToolbarContent.of(lowerEntry, titleOnly: titleOnly);
    final upperOwns = blend.upperOwns;
    final upperOpacity = blend.upperOpacity;
    final lowerOpacity = blend.lowerOpacity;

    final upperBack = upper.impliesBack && upper.customLeading == null;
    final lowerBack = lower.impliesBack && lower.customLeading == null;
    final Animation<double>? backOpacity = switch ((upperBack, lowerBack)) {
      (true, true) => kAlwaysCompleteAnimation,
      (true, false) => upperOpacity,
      (false, true) => lowerOpacity,
      (false, false) => null,
    };

    // The bar's backdrop belongs to the chrome, not to a page: it only fades
    // when the toolbar as a whole comes or goes.
    final Animation<double> backdropOpacity = switch ((
      upper.isEmpty,
      lower.isEmpty,
    )) {
      (false, false) => kAlwaysCompleteAnimation,
      (false, true) =>
        blend.isBlending && lowerEntry != null
            ? upperOpacity
            : kAlwaysCompleteAnimation,
      (true, false) => lowerOpacity,
      (true, true) => kAlwaysDismissedAnimation,
    };

    return Align(
      alignment: Alignment.topCenter,
      child: SizedBox(
        height: titleOnly
            ? kDuoTitleBandHeight
            : kHostedToolbarHeight + topInset,
        child: IgnorePointer(
          ignoring: blend.ownerIsCovered,
          child: FadeTransition(
            opacity: blend.chromeOpacity,
            // Every layer is keyed, so a page's native bar survives the start
            // and the end of a blend instead of being torn down and rebuilt.
            child: Stack(
              fit: StackFit.expand,
              clipBehavior: Clip.none,
              children: [
                FadeTransition(
                  key: const ValueKey<String>('adaptive_toolbar_backdrop'),
                  opacity: backdropOpacity,
                  child: titleOnly
                      ? const DuoTitleBackdrop()
                      : const _Backdrop(),
                ),
                if (lowerEntry != null && !lower.isEmpty)
                  _layer(
                    key: ValueKey<Object>(lowerEntry.id),
                    content: lower,
                    opacity: lowerOpacity,
                    interactive: !upperOwns,
                  ),
                if (upperEntry != null && !upper.isEmpty)
                  _layer(
                    key: ValueKey<Object>(upperEntry.id),
                    content: upper,
                    opacity: upperOpacity,
                    interactive: upperOwns,
                  ),
                if (backOpacity != null)
                  Positioned(
                    key: const ValueKey<String>('adaptive_toolbar_back'),
                    left: 16 + (_isWindowed(context) ? 62 : 0),
                    bottom: 3,
                    child: FadeTransition(
                      key: const ValueKey<String>('adaptive_toolbar_back_fade'),
                      opacity: backOpacity,
                      child: _BackButton(
                        navigator: (upperOwns ? upper : lower).navigator,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// One page's bar. The back button is not part of it: the shared one is
  /// drawn on top of all page layers.
  Widget _layer({
    required Key key,
    required TopToolbarContent content,
    required Animation<double> opacity,
    required bool interactive,
  }) {
    return FadeTransition(
      key: key,
      opacity: opacity,
      child: IgnorePointer(
        ignoring: !interactive,
        child: titleOnly
            // On iPhone Duo the title sits at the leading edge and the
            // controls are in the trailing bar, so there is no bar to draw.
            ? DuoToolbarTitle(
                title: content.title,
                titleWidget: content.titleOverlay,
              )
            : defaultTargetPlatform == TargetPlatform.iOS
            ? IOS26NativeToolbar(
                title: content.title,
                titleWidget: content.titleOverlay,
                leading: content.customLeading,
                actions: content.actions,
                tintColor: content.tint,
                showsGradient: false,
                onActionTap: (index) {
                  if (index >= 0 && index < content.actions.length) {
                    content.actions[index].onPressed();
                  }
                },
              )
            : _FallbackBar(content: content),
      ),
    );
  }

  /// Whether the app runs in a window smaller than the display (iPadOS),
  /// where the system's window controls take the bar's leading corner.
  static bool _isWindowed(BuildContext context) {
    final display = View.of(context).display.size;
    final viewport =
        MediaQuery.sizeOf(context) * MediaQuery.devicePixelRatioOf(context);
    return (display.longestSide - viewport.longestSide).abs() > 1 ||
        (display.shortestSide - viewport.shortestSide).abs() > 1;
  }
}

/// The soft gradient that keeps the bar readable over scrolling content.
class _Backdrop extends StatelessWidget {
  const _Backdrop();

  @override
  Widget build(BuildContext context) {
    final dark = MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    final base = dark ? const Color(0xFF000000) : const Color(0xFFFFFFFF);
    return IgnorePointer(
      child: OverflowBox(
        alignment: Alignment.topCenter,
        maxHeight: double.infinity,
        child: LayoutBuilder(
          builder: (context, constraints) => Container(
            // Runs on below the bar for a smooth fade into the content.
            height:
                MediaQuery.viewPaddingOf(context).top +
                kHostedToolbarHeight +
                30,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0.0, 0.4, 0.7, 1.0],
                colors: [
                  base.withValues(alpha: 0.85),
                  base.withValues(alpha: 0.6),
                  base.withValues(alpha: 0.2),
                  base.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Back for the page that owns the chrome, performed on that page's own
/// navigator so nested navigators (tabs, shell routes) pop the right stack.
class _BackButton extends StatelessWidget {
  const _BackButton({required this.navigator});

  final NavigatorState? navigator;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      width: 38,
      child: AdaptiveButton.sfSymbol(
        onPressed: () => navigator?.maybePop(),
        sfSymbol: const SFSymbol('chevron.left', size: 20),
      ),
    );
  }
}

/// Stand-in for the native bar where there is no UIKit (widget tests).
class _FallbackBar extends StatelessWidget {
  const _FallbackBar({required this.content});

  final TopToolbarContent content;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: SizedBox(
        height: kHostedToolbarHeight,
        child: Row(
          children: [
            if (content.customLeading != null) content.customLeading!,
            Expanded(
              child: Center(
                child:
                    content.titleOverlay ??
                    (content.title != null ? Text(content.title!) : null),
              ),
            ),
            for (final action in content.actions)
              Builder(
                builder: (context) => CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () =>
                      action.press(context, navigator: content.navigator),
                  child: action.icon != null
                      ? Icon(action.icon)
                      : Text(action.title ?? ''),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
