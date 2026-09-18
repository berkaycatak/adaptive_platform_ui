import 'package:flutter/widgets.dart';
import 'package:foldable/foldable.dart';

import '../style/sf_symbol.dart';
import '../widgets/adaptive_app_bar_action.dart';
import '../widgets/adaptive_button.dart';
import 'duo_vertical_bar.dart';
import 'toolbar_registry.dart';

/// Length of the crossfade used when the owner of the chrome changes without
/// a route transition to follow (switching tabs, a dialog opening).
const Duration kToolbarItemSwapDuration = Duration(milliseconds: 220);

/// The one vertical bar of the app. It never moves; only its controls follow
/// the page that owns the chrome.
///
/// While a page is pushed, popped or dragged back, the controls of the two
/// pages involved are blended by that route's own transition animation, so
/// the swap takes exactly as long as the page transition, follows a back
/// swipe under the finger, and reverses when the swipe is cancelled. A back
/// button that both pages show stays put instead of fading out and in.
class HostedDuoBar extends StatefulWidget {
  const HostedDuoBar({
    super.key,
    required this.registry,
    required this.regions,
  });

  final ToolbarRegistry registry;
  final List<ReservedRegion> regions;

  @override
  State<HostedDuoBar> createState() => _HostedDuoBarState();
}

class _HostedDuoBarState extends State<HostedDuoBar>
    with SingleTickerProviderStateMixin {
  /// Drives swaps that have no route transition to follow.
  late final AnimationController _swap;

  /// The page whose controls are shown when no blend is running.
  Object? _ownerId;

  /// The running blend: [_upperId]'s controls show at [_driver] value 1,
  /// [_lowerId]'s at 0. Either id may be null (nothing to show on that side).
  Animation<double>? _driver;
  Object? _upperId;
  Object? _lowerId;

  /// Last known entries by id, so a page that has just been popped (and has
  /// left the registry) can still fade its controls out.
  final Map<Object, ToolbarEntry> _known = <Object, ToolbarEntry>{};

  ValueNotifier<bool>? _gesture;

  /// False until the first owner has been shown; the app's first page gets
  /// its controls at once rather than fading them in.
  bool _hasShownOwner = false;

  @override
  void initState() {
    super.initState();
    _swap = AnimationController(
      vsync: this,
      duration: kToolbarItemSwapDuration,
    );
    widget.registry.addListener(_onRegistryChanged);
    _onRegistryChanged();
  }

  @override
  void didUpdateWidget(HostedDuoBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.registry != widget.registry) {
      oldWidget.registry.removeListener(_onRegistryChanged);
      widget.registry.addListener(_onRegistryChanged);
      _onRegistryChanged();
    }
  }

  @override
  void dispose() {
    widget.registry.removeListener(_onRegistryChanged);
    _gesture?.removeListener(_onGestureChanged);
    _stopBlend();
    _swap.dispose();
    super.dispose();
  }

  ToolbarEntry? _entry(Object? id) {
    if (id == null) return null;
    final live = widget.registry.byId(id);
    if (live != null) _known[id] = live;
    return _known[id];
  }

  void _onRegistryChanged() {
    final previous = _entry(_ownerId);
    final next = widget.registry.active;
    if (next != null) _known[next.id] = next;
    _watchGestures(next?.navigator);

    if (!_hasShownOwner) {
      _ownerId = next?.id;
      _hasShownOwner = next != null;
    } else if (next?.id != previous?.id) {
      _ownerId = next?.id;
      final pushing = next?.route?.animation;
      final popping = previous?.route?.animation;
      if (pushing != null && pushing.status == AnimationStatus.forward) {
        // A new page is coming in on top of the previous owner.
        _startBlend(pushing, upper: next, lower: previous);
      } else if (popping != null && popping.status == AnimationStatus.reverse) {
        // The previous owner is leaving and uncovers the new one. When a
        // back swipe was already blending the two, this continues it.
        _startBlend(popping, upper: previous, lower: next);
      } else {
        _swap.value = 0;
        _startBlend(_swap, upper: next, lower: previous);
        _swap.forward();
      }
    }

    _forgetUnused();
    if (mounted) setState(() {});
  }

  /// A back swipe does not change the owner until the finger lifts, so it is
  /// followed through the navigator's gesture flag instead.
  void _watchGestures(NavigatorState? navigator) {
    final notifier = navigator?.userGestureInProgressNotifier;
    if (identical(notifier, _gesture)) return;
    _gesture?.removeListener(_onGestureChanged);
    _gesture = notifier;
    _gesture?.addListener(_onGestureChanged);
  }

  void _onGestureChanged() {
    if (_gesture?.value ?? false) {
      final owner = _entry(_ownerId);
      final animation = owner?.route?.animation;
      if (owner == null || animation == null) return;
      _startBlend(animation, upper: owner, lower: widget.registry.below(owner));
      setState(() {});
    } else {
      // Released: the route now either settles back or pops.
      _endBlendIfSettled();
    }
  }

  void _startBlend(
    Animation<double> driver, {
    required ToolbarEntry? upper,
    required ToolbarEntry? lower,
  }) {
    _stopBlend();
    _driver = driver;
    _upperId = upper?.id;
    _lowerId = lower?.id;
    driver.addStatusListener(_onDriverStatus);
  }

  void _stopBlend() {
    _driver?.removeStatusListener(_onDriverStatus);
    _driver = null;
    _upperId = null;
    _lowerId = null;
  }

  void _onDriverStatus(AnimationStatus status) => _endBlendIfSettled();

  void _endBlendIfSettled() {
    final driver = _driver;
    if (driver == null) return;
    // During a back swipe the route sits at "completed" until the finger
    // moves, and may touch either end while being dragged.
    if (_gesture?.value ?? false) return;
    if (driver.status.isAnimating) return;
    _stopBlend();
    _forgetUnused();
    if (mounted) setState(() {});
  }

  void _forgetUnused() {
    _known.removeWhere(
      (id, _) =>
          id != _ownerId &&
          id != _upperId &&
          id != _lowerId &&
          widget.registry.byId(id) == null,
    );
  }

  /// Fades the outgoing controls out over the first part of the transition
  /// and the incoming ones in over the last part. Blending two sets of glass
  /// buttons at half opacity on top of each other reads as a smudge, so the
  /// two fades only overlap briefly around the middle.
  static final Animatable<double> _fadeIn = CurveTween(
    curve: const Interval(0.3, 0.85, curve: Curves.easeIn),
  );
  static final Animatable<double> _fadeOut = Tween<double>(
    begin: 1,
    end: 0,
  ).chain(CurveTween(curve: const Interval(0, 0.5, curve: Curves.easeOut)));

  @override
  Widget build(BuildContext context) {
    final driver = _driver;
    final blending = driver != null;
    final upperId = blending ? _upperId : _ownerId;
    final upper = _BarContent.of(_entry(upperId));
    final lower = _BarContent.of(blending ? _entry(_lowerId) : null);
    final upperOwns = upperId == _ownerId;

    final Animation<double> upperOpacity = blending
        ? driver.drive(_fadeIn)
        : kAlwaysCompleteAnimation;
    final Animation<double> lowerOpacity = blending
        ? driver.drive(_fadeOut)
        : kAlwaysDismissedAnimation;

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

    // Every layer is keyed, so a page's native buttons survive the start and
    // the end of a blend instead of being torn down and rebuilt.
    return Stack(
      fit: StackFit.expand,
      children: [
        if (_lowerId != null && blending && !lower.isEmpty)
          _layer(
            key: ValueKey<Object>(_lowerId!),
            content: lower,
            opacity: lowerOpacity,
            interactive: !upperOwns,
          ),
        if (upperId != null && !upper.isEmpty)
          _layer(
            key: ValueKey<Object>(upperId),
            content: upper,
            opacity: upperOpacity,
            interactive: upperOwns,
          ),
        if (backOpacity != null)
          FadeTransition(
            key: const ValueKey<String>('adaptive_toolbar_back'),
            opacity: backOpacity,
            child: DuoVerticalBar(
              leading: _BackButton(
                navigator: (upperOwns ? upper : lower).navigator,
              ),
              regions: widget.regions,
            ),
          ),
      ],
    );
  }

  /// One page's controls. The back button's slot is left empty because the
  /// shared one is drawn on top of all page layers.
  Widget _layer({
    required Key key,
    required _BarContent content,
    required Animation<double> opacity,
    required bool interactive,
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
                  ? const SizedBox(width: 38, height: 38)
                  : null),
          actions: content.actions,
          regions: widget.regions,
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
  });

  /// No page owns the chrome (a dialog or sheet is on top), the page has no
  /// toolbar, or it draws a non-native bar of its own: the bar stays in
  /// place, empty, instead of showing another page's controls.
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
    );
  }

  final Widget? customLeading;
  final bool impliesBack;
  final NavigatorState? navigator;
  final List<AdaptiveAppBarAction> actions;

  bool get isEmpty => customLeading == null && !impliesBack && actions.isEmpty;
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
