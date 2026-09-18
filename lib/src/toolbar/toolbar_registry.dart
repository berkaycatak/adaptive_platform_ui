import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../widgets/adaptive_app_bar.dart';

/// One page's contribution to the fixed toolbar chrome.
///
/// An [AdaptiveScaffold] publishes one of these while it is mounted. The
/// chrome shows the items of the [ToolbarRegistry.active] entry, so pages
/// never draw their own bar; only the items change as routes come and go.
@immutable
class ToolbarEntry {
  const ToolbarEntry({
    required this.id,
    required this.appBar,
    required this.route,
    required this.navigator,
    required this.visible,
    this.hasTabBar = false,
  });

  /// Identifies the registering scaffold instance.
  final Object id;

  /// The page's app bar configuration; null when the page shows no toolbar.
  /// A null entry still counts, so the chrome empties out instead of keeping
  /// the previous page's items on a page that has none.
  final AdaptiveAppBar? appBar;

  /// The route the page lives in; null when it is not inside a Navigator.
  final ModalRoute<Object?>? route;

  /// The navigator owning [route]. "Back" is resolved and performed against
  /// this navigator, so nested navigators (shell routes, tabs) stay correct.
  final NavigatorState? navigator;

  /// False while the page is kept alive but not on screen, e.g. a
  /// non-selected tab of an IndexedStack.
  final bool visible;

  /// Whether the registering scaffold shows a tab bar. Such a scaffold is the
  /// root of a tab layout and never gets an automatic back button.
  final bool hasTabBar;

  /// Whether the user is looking at this page right now: it is visible and
  /// on top of its own navigator. Read live, so it tracks pushes and pops.
  bool get isActive => visible && (route?.isCurrent ?? true);

  /// Whether the chrome should offer a back button for this page.
  ///
  /// Asked of the page's own route rather than of the navigator's current
  /// stack, so the answer stays the same while the page is being pushed,
  /// dragged back or popped, and its back button does not flicker mid
  /// transition.
  bool get canPop {
    final route = this.route;
    if (route == null) return navigator?.canPop() ?? false;
    return !route.isFirst || route.willHandlePopInternally;
  }

  /// Whether the chrome should supply a back button on its own: the page can
  /// go back, brought no leading widget of its own, and is not a tab root.
  bool get impliesBackButton => canPop && appBar?.leading == null && !hasTabBar;
}

/// Ordered set of the pages currently mounted under an [AdaptiveToolbarHost].
///
/// Router-agnostic by design: it relies only on [ModalRoute] (every
/// Navigator-based router creates one per page) and on the scaffold's own
/// lifecycle, never on a [NavigatorObserver] that a user-owned router config
/// (GoRouter, auto_route, ...) would have to be told about.
class ToolbarRegistry extends ChangeNotifier {
  final List<ToolbarEntry> _entries = <ToolbarEntry>[];
  bool _notifyScheduled = false;
  bool _disposed = false;

  /// All mounted entries in registration order (oldest first).
  List<ToolbarEntry> get entries => List<ToolbarEntry>.unmodifiable(_entries);

  /// The entry whose items the chrome shows.
  ///
  /// The most recently registered page that is on its navigator's top and
  /// visible. Newest wins so a page inside a nested navigator beats the shell
  /// page hosting it, and a freshly pushed page beats the one beneath it.
  ToolbarEntry? get active {
    for (var i = _entries.length - 1; i >= 0; i--) {
      if (_entries[i].isActive) return _entries[i];
    }
    return null;
  }

  /// The latest version of the entry registered under [id], if still mounted.
  ToolbarEntry? byId(Object id) {
    for (final entry in _entries) {
      if (entry.id == id) return entry;
    }
    return null;
  }

  /// The page that [entry] covers in its own navigator: the one that comes
  /// back when [entry] is popped or dragged away. Null for a root page.
  ToolbarEntry? below(ToolbarEntry entry) {
    final index = _entries.indexWhere((e) => e.id == entry.id);
    for (var i = index - 1; i >= 0; i--) {
      final candidate = _entries[i];
      // Not filtered by [ToolbarEntry.visible]: a covered page is kept alive
      // with its tickers off until the page above starts to leave, and that
      // is exactly the page being asked for.
      if (candidate.navigator == entry.navigator &&
          (candidate.route?.isActive ?? false)) {
        return candidate;
      }
    }
    return null;
  }

  /// Adds [entry] or replaces the one with the same [ToolbarEntry.id].
  ///
  /// Always notifies, even when the fields are unchanged: callers invoke this
  /// from `didChangeDependencies` precisely because the route's live status
  /// (`isCurrent`) changed, which no field comparison would reveal.
  void upsert(ToolbarEntry entry) {
    final index = _entries.indexWhere((e) => e.id == entry.id);
    if (index == -1) {
      _entries.add(entry);
    } else {
      _entries[index] = entry;
    }
    _notifySafely();
  }

  /// Removes the entry registered under [id], if any.
  void remove(Object id) {
    final before = _entries.length;
    _entries.removeWhere((e) => e.id == id);
    if (_entries.length != before) _notifySafely();
  }

  /// Pages register from `didChangeDependencies`, i.e. while the framework is
  /// building. Notifying listeners synchronously there would mark the chrome
  /// (a sibling of the navigator) dirty mid-build, which the framework
  /// rejects, so notifications are always delivered after the current frame.
  ///
  /// The scheduler phase cannot be used to tell "building" from "idle": the
  /// very first build of an app runs outside of a frame, with the phase still
  /// [SchedulerPhase.idle]. Deferring unconditionally is the only rule that
  /// holds everywhere; bursts (several pages registering in one build) are
  /// coalesced into a single notification.
  void _notifySafely() {
    if (_disposed || _notifyScheduled) return;
    _notifyScheduled = true;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _notifyScheduled = false;
      if (!_disposed) notifyListeners();
    });
    // Make sure that frame actually happens when nothing else asked for one.
    SchedulerBinding.instance.ensureVisualUpdate();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  /// The registry installed by the nearest [AdaptiveToolbarHost], or null
  /// when there is none (the scaffold then falls back to drawing its own
  /// toolbar).
  ///
  /// Deliberately does not create a dependency: a scaffold must not rebuild
  /// every time any page updates the registry. Only the chrome listens.
  static ToolbarRegistry? maybeOf(BuildContext context) =>
      context.getInheritedWidgetOfExactType<ToolbarRegistryScope>()?.notifier;
}

/// Makes a [ToolbarRegistry] available to the subtree.
///
/// Installed by [AdaptiveToolbarHost]; widgets that should rebuild when the
/// active entry changes depend on it, everything else uses
/// [ToolbarRegistry.maybeOf].
class ToolbarRegistryScope extends InheritedNotifier<ToolbarRegistry> {
  const ToolbarRegistryScope({
    super.key,
    required ToolbarRegistry registry,
    required super.child,
  }) : super(notifier: registry);
}
