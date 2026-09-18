import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import 'toolbar_registry.dart';

/// Length of the crossfade used when the owner of the chrome changes without
/// a route transition to follow (switching tabs), and of the dimming applied
/// while a dialog or sheet covers the owner.
const Duration kToolbarItemSwapDuration = Duration(milliseconds: 220);

/// How far the chrome is dimmed while a dialog or sheet covers its owner.
const double kToolbarCoveredOpacity = 0.45;

/// Why the owner of the chrome changed.
enum ToolbarSwapKind {
  /// A page was pushed on top of the previous owner.
  push,

  /// The previous owner was popped (or swiped away) and uncovered this one.
  pop,

  /// No route transition links the two: a tab switch, a replaced stack.
  swap,
}

/// Works out, for every part of the fixed chrome, whose controls to show and
/// how to move from one page's controls to the next.
///
/// While a page is pushed, popped or dragged back, the two pages involved
/// are blended by that route's own transition animation, so the swap takes
/// exactly as long as the page transition, follows a back swipe under the
/// finger, and reverses when the swipe is cancelled.
class ToolbarBlend extends ChangeNotifier {
  ToolbarBlend({required this.registry, required TickerProvider vsync})
    : _swap = AnimationController(
        vsync: vsync,
        duration: kToolbarItemSwapDuration,
      ),
      _cover = AnimationController(
        vsync: vsync,
        duration: kToolbarItemSwapDuration,
      ) {
    registry.addListener(_onRegistryChanged);
    // A dialog pushed on an outer navigator covers a page inside a tab
    // without that page, or the registry, hearing of it. Every route owns a
    // focus scope that takes focus when pushed and gives it back when popped,
    // so a focus change is the router-agnostic cue to look again.
    FocusManager.instance.addListener(_onFocusChanged);
    _onRegistryChanged();
  }

  final ToolbarRegistry registry;

  /// Drives swaps that have no route transition to follow.
  final AnimationController _swap;

  /// 0 while the owner is in front, 1 while a dialog or sheet covers it.
  final AnimationController _cover;

  Object? _ownerId;
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
  bool _disposed = false;

  /// The page whose controls the chrome shows and acts on.
  ToolbarEntry? get owner => _entry(_ownerId);

  /// Whether a dialog or sheet is on top of [owner]: its controls stay, but
  /// must not react.
  bool get ownerIsCovered => owner?.isCovered ?? false;

  /// Opacity of the whole chrome: full in front, dimmed while covered.
  late final Animation<double> chromeOpacity = _cover.drive(
    Tween<double>(begin: 1, end: kToolbarCoveredOpacity),
  );

  /// Whether two pages are being blended right now.
  bool get isBlending => _driver != null;

  /// While blending: the page shown at [driver] value 1. Otherwise [owner].
  ToolbarEntry? get upper => _entry(isBlending ? _upperId : _ownerId);

  /// While blending: the page shown at [driver] value 0. Otherwise null.
  ToolbarEntry? get lower => isBlending ? _entry(_lowerId) : null;

  /// Whether [upper] (rather than [lower]) is the [owner].
  bool get upperOwns => !isBlending || _upperId == _ownerId;

  /// The animation blending [lower] (0) into [upper] (1); null when idle.
  Animation<double>? get driver => _driver;

  /// Fades the outgoing controls out over the first part of the transition
  /// and the incoming ones in over the last part. Two sets of glass buttons
  /// at half opacity on top of each other read as a smudge, so the two fades
  /// only overlap briefly around the middle.
  static final Animatable<double> _fadeIn = CurveTween(
    curve: const Interval(0.3, 0.85, curve: Curves.easeIn),
  );
  static final Animatable<double> _fadeOut = Tween<double>(
    begin: 1,
    end: 0,
  ).chain(CurveTween(curve: const Interval(0, 0.5, curve: Curves.easeOut)));

  Animation<double> get upperOpacity =>
      _driver?.drive(_fadeIn) ?? kAlwaysCompleteAnimation;

  Animation<double> get lowerOpacity =>
      _driver?.drive(_fadeOut) ?? kAlwaysDismissedAnimation;

  /// Incremented every time [owner] changes to another page, with
  /// [lastSwapKind] saying how. Parts of the chrome that animate natively use
  /// it to start the matching animation once per change.
  int get swapCount => _swapCount;
  int _swapCount = 0;

  ToolbarSwapKind get lastSwapKind => _lastSwapKind;
  ToolbarSwapKind _lastSwapKind = ToolbarSwapKind.swap;

  ToolbarEntry? _entry(Object? id) {
    if (id == null) return null;
    final live = registry.byId(id);
    if (live != null) _known[id] = live;
    return _known[id];
  }

  /// Looks again once the frame that follows the focus change is done: by
  /// then the pages affected by the same navigation have republished
  /// themselves, exactly as when the registry itself notifies.
  void _onFocusChanged() {
    if (_focusCheckScheduled || _disposed) return;
    _focusCheckScheduled = true;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _focusCheckScheduled = false;
      _onRegistryChanged();
    });
    SchedulerBinding.instance.ensureVisualUpdate();
  }

  bool _focusCheckScheduled = false;

  void _onRegistryChanged() {
    if (_disposed) return;
    final previous = _entry(_ownerId);
    final next = registry.owner;
    if (next != null) _known[next.id] = next;
    _watchGestures(next?.navigator);

    if (!_hasShownOwner) {
      _ownerId = next?.id;
      _hasShownOwner = next != null;
    } else if (next?.id != previous?.id) {
      _ownerId = next?.id;
      _swapCount++;
      final pushing = next?.route?.animation;
      final popping = previous?.route?.animation;
      if (pushing != null && pushing.status == AnimationStatus.forward) {
        // A new page is coming in on top of the previous owner.
        _lastSwapKind = ToolbarSwapKind.push;
        _startBlend(pushing, upper: next, lower: previous);
      } else if (popping != null && popping.status == AnimationStatus.reverse) {
        // The previous owner is leaving and uncovers the new one. When a
        // back swipe was already blending the two, this continues it.
        _lastSwapKind = ToolbarSwapKind.pop;
        _startBlend(popping, upper: previous, lower: next);
      } else {
        _lastSwapKind = ToolbarSwapKind.swap;
        _swap.value = 0;
        _startBlend(_swap, upper: next, lower: previous);
        _swap.forward();
      }
    }

    if (ownerIsCovered) {
      _cover.forward();
    } else {
      _cover.reverse();
    }

    _forgetUnused();
    notifyListeners();
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
    if (_disposed) return;
    if (_gesture?.value ?? false) {
      final owner = this.owner;
      final animation = owner?.route?.animation;
      if (owner == null || animation == null) return;
      _startBlend(animation, upper: owner, lower: registry.below(owner));
      notifyListeners();
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
    if (driver == null || _disposed) return;
    // During a back swipe the route sits at "completed" until the finger
    // moves, and may touch either end while being dragged.
    if (_gesture?.value ?? false) return;
    if (driver.status.isAnimating) return;
    _stopBlend();
    _forgetUnused();
    notifyListeners();
  }

  void _forgetUnused() {
    _known.removeWhere(
      (id, _) =>
          id != _ownerId &&
          id != _upperId &&
          id != _lowerId &&
          registry.byId(id) == null,
    );
  }

  @override
  void dispose() {
    _disposed = true;
    registry.removeListener(_onRegistryChanged);
    FocusManager.instance.removeListener(_onFocusChanged);
    _gesture?.removeListener(_onGestureChanged);
    _stopBlend();
    _swap.dispose();
    _cover.dispose();
    super.dispose();
  }
}
