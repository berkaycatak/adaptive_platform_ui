import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:foldable/foldable.dart';

import '../platform/platform_info.dart';
import '../style/sf_symbol.dart';
import '../widgets/adaptive_app_bar_action.dart';
import '../widgets/adaptive_button.dart';
import 'duo_vertical_bar.dart';
import 'toolbar_chrome_scope.dart';
import 'toolbar_registry.dart';

/// Fixed toolbar chrome that lives above the navigator.
///
/// Install it once around the navigator (an app `builder` is the right
/// place; [AdaptiveApp] does this for you). It owns a [ToolbarRegistry] that
/// every [AdaptiveScaffold] below publishes its app bar to, and it draws one
/// persistent bar whose items change as routes come and go. Because the bar
/// is not part of any route it stays put during page transitions, exactly
/// like the system bars on iOS 26 and the vertical bar on the iPhone Duo
/// inner display.
///
/// Works with any router: it depends on nothing but the widget tree.
class AdaptiveToolbarHost extends StatefulWidget {
  const AdaptiveToolbarHost({
    super.key,
    required this.child,
    @visibleForTesting this.debugFold,
  });

  /// The navigator (or whatever the app's `builder` receives).
  final Widget child;

  /// Replaces the platform's fold readings and the iOS 26 check, so the
  /// chrome can be exercised in widget tests on any host.
  @visibleForTesting
  final FoldableData? debugFold;

  @override
  State<AdaptiveToolbarHost> createState() => _AdaptiveToolbarHostState();
}

class _AdaptiveToolbarHostState extends State<AdaptiveToolbarHost> {
  final ToolbarRegistry _registry = ToolbarRegistry();

  /// Latest fold / size-class reading; null until the first one arrives and
  /// on platforms where the chrome is never drawn.
  FoldableData? _fold;
  StreamSubscription<FoldableData>? _foldSub;

  @override
  void initState() {
    super.initState();
    // The fixed chrome only exists where pages use the native iOS 26
    // toolbar; elsewhere pages keep their own Cupertino / Material bars.
    if (widget.debugFold == null && PlatformInfo.isIOS26OrHigher()) {
      Foldable.snapshot.then(_onFoldChanged).catchError((Object _) {});
      _foldSub = Foldable.changes.listen(
        _onFoldChanged,
        onError: (Object _) {},
      );
    }
  }

  void _onFoldChanged(FoldableData data) {
    if (!mounted) return;
    setState(() => _fold = data);
  }

  @override
  void dispose() {
    _foldSub?.cancel();
    _registry.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fold = widget.debugFold ?? _fold;
    final hostsDuoControls = DuoLayout.isVerticalBarPose(
      fold,
      MediaQuery.sizeOf(context),
    );

    return ToolbarRegistryScope(
      registry: _registry,
      child: ToolbarChromeScope(
        hostsDuoControls: hostsDuoControls,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Always the first child at a stable position, so toggling the
            // chrome never rebuilds the navigator from scratch.
            widget.child,
            if (hostsDuoControls)
              Positioned(
                top: 0,
                right: 0,
                bottom: 0,
                width: DuoLayout.bandWidth(MediaQuery.paddingOf(context)),
                child: _HostedDuoBar(
                  registry: _registry,
                  regions: fold?.regions ?? const <ReservedRegion>[],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// The one vertical bar of the app. It never moves; only its controls follow
/// the page that owns the chrome.
class _HostedDuoBar extends StatelessWidget {
  const _HostedDuoBar({required this.registry, required this.regions});

  final ToolbarRegistry registry;
  final List<ReservedRegion> regions;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: registry,
      builder: (context, _) {
        final entry = registry.active;
        final appBar = entry?.appBar;

        // No page owns the chrome (a dialog or sheet is on top), the page has
        // no toolbar, or it draws a non-native bar of its own: the bar stays
        // in place, empty, instead of showing another page's controls.
        if (entry == null || appBar == null || !appBar.useNativeToolbar) {
          return const SizedBox.shrink();
        }

        return DuoVerticalBar(
          leading:
              appBar.leading ??
              (entry.impliesBackButton ? _BackButton(entry: entry) : null),
          actions: appBar.actions ?? const <AdaptiveAppBarAction>[],
          regions: regions,
        );
      },
    );
  }
}

/// Back for the page that owns the chrome, performed on that page's own
/// navigator so nested navigators (tabs, shell routes) pop the right stack.
class _BackButton extends StatelessWidget {
  const _BackButton({required this.entry});

  final ToolbarEntry entry;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      width: 38,
      child: AdaptiveButton.sfSymbol(
        onPressed: () => entry.navigator?.maybePop(),
        sfSymbol: const SFSymbol('chevron.left', size: 20),
      ),
    );
  }
}
