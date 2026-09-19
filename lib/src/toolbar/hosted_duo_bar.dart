import 'package:flutter/widgets.dart';
import 'package:foldable/foldable.dart';

import '../widgets/adaptive_app_bar_action.dart';
import '../widgets/ios26/ios26_glass_capsule.dart';
import 'duo_vertical_bar.dart';
import 'toolbar_blend.dart';
import 'toolbar_registry.dart';

/// The one vertical bar of the app. It never moves; only its controls follow
/// the page that owns the chrome, blended as [ToolbarBlend] dictates. A back
/// button that both pages show stays put instead of fading out and in.
class HostedDuoBar extends StatelessWidget {
  const HostedDuoBar({super.key, required this.blend, required this.regions});

  final ToolbarBlend blend;
  final List<ReservedRegion> regions;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(listenable: blend, builder: _build);
  }

  Widget _build(BuildContext context, Widget? _) {
    final upperEntry = blend.upper;
    final lowerEntry = blend.lower;
    final upper = _BarContent.of(upperEntry);
    final lower = _BarContent.of(lowerEntry);
    final upperOwns = blend.upperOwns;
    final upperOpacity = blend.upperOpacity;
    final lowerOpacity = blend.lowerOpacity;

    // The tab bar belongs to the tab layout, not to a page: it stays still
    // while pages inside the tabs change, and fades with the page when the
    // navigation leaves or enters the tabs.
    final upperTabs = blend.registry.tabBarOwnerFor(upperEntry);
    final lowerTabs = blend.registry.tabBarOwnerFor(lowerEntry);
    final tabLayers = <(ToolbarEntry, Animation<double>)>[
      if (lowerTabs != null && lowerTabs.id != upperTabs?.id)
        (lowerTabs, lowerOpacity),
      if (upperTabs != null)
        (
          upperTabs,
          lowerTabs?.id == upperTabs.id
              ? kAlwaysCompleteAnimation
              : upperOpacity,
        ),
    ];

    // The back button is one control shared by every page, drawn in a layer
    // of its own: it stays still when both pages have it, and fades with the
    // only page that has it otherwise. Page layers just keep its slot free.
    final Animation<double>? backOpacity = switch ((
      upper.impliesBack,
      lower.impliesBack,
    )) {
      (true, true) => kAlwaysCompleteAnimation,
      (true, false) => upperOpacity,
      (false, true) => lowerOpacity,
      (false, false) => null,
    };

    // Dimmed and inert while a dialog or sheet covers the owner. Every layer
    // is keyed, so a page's native buttons survive the start and the end of a
    // blend instead of being torn down and rebuilt.
    return IgnorePointer(
      ignoring: blend.ownerIsCovered,
      child: FadeTransition(
        opacity: blend.chromeOpacity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (lowerEntry != null && !lower.isEmpty)
              _layer(
                key: ValueKey<Object>(lowerEntry.id),
                content: lower,
                opacity: lowerOpacity,
                interactive: !upperOwns,
                reservedTabs: lowerTabs?.tabBar?.items?.length ?? 0,
              ),
            if (upperEntry != null && !upper.isEmpty)
              _layer(
                key: ValueKey<Object>(upperEntry.id),
                content: upper,
                opacity: upperOpacity,
                interactive: upperOwns,
                reservedTabs: upperTabs?.tabBar?.items?.length ?? 0,
              ),
            if (backOpacity != null)
              FadeTransition(
                key: const ValueKey<String>('adaptive_toolbar_back'),
                opacity: backOpacity,
                child: DuoVerticalBar(
                  leading: DuoBarBackButton(
                    onPressed: () =>
                        (upperOwns ? upper : lower).navigator?.maybePop(),
                  ),
                  regions: regions,
                ),
              ),
            for (final (tabs, opacity) in tabLayers)
              FadeTransition(
                key: ValueKey<(String, Object)>(('adaptive_tabs', tabs.id)),
                opacity: opacity,
                child: DuoVerticalBar(tabBar: tabs.tabBar, regions: regions),
              ),
          ],
        ),
      ),
    );
  }

  /// One page's controls. The back button's slot is left empty because the
  /// shared one is drawn on top of all page layers.
  Widget _layer({
    required Key key,
    required _BarContent content,
    required Animation<double> opacity,
    required bool interactive,
    required int reservedTabs,
  }) {
    return FadeTransition(
      key: key,
      opacity: opacity,
      child: IgnorePointer(
        ignoring: !interactive,
        child: DuoVerticalBar(
          leading:
              content.customLeading ??
              (content.impliesBack
                  ? const SizedBox.square(dimension: IOS26GlassCapsule.width)
                  : null),
          actions: content.actions,
          reservedTabs: reservedTabs,
          tint: content.tint,
          regions: regions,
        ),
      ),
    );
  }
}

/// What one page contributes to the bar.
class _BarContent {
  const _BarContent({
    this.customLeading,
    this.impliesBack = false,
    this.navigator,
    this.actions = const <AdaptiveAppBarAction>[],
    this.tint,
  });

  /// No page owns the chrome (a page without an [AdaptiveScaffold] is in
  /// front), the page has no toolbar, or it draws a non-native bar of its
  /// own: the bar stays in place, empty, instead of showing another page's
  /// controls.
  factory _BarContent.of(ToolbarEntry? entry) {
    final appBar = entry?.appBar;
    if (entry == null || appBar == null || !appBar.useNativeToolbar) {
      return const _BarContent();
    }
    return _BarContent(
      customLeading: appBar.leading,
      impliesBack: entry.impliesBackButton,
      navigator: entry.navigator,
      actions: appBar.actions ?? const <AdaptiveAppBarAction>[],
      tint: appBar.tintColor,
    );
  }

  final Widget? customLeading;
  final bool impliesBack;
  final NavigatorState? navigator;
  final List<AdaptiveAppBarAction> actions;
  final Color? tint;

  bool get isEmpty => customLeading == null && !impliesBack && actions.isEmpty;
}
