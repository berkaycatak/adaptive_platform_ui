import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:foldable/foldable.dart';
import '../../style/sf_symbol.dart';
import '../adaptive_app_bar_action.dart';
import '../adaptive_bottom_navigation_bar.dart';
import '../adaptive_button.dart';
import '../adaptive_scaffold.dart';
import 'ios26_native_tab_bar.dart';
import 'ios26_native_toolbar.dart';

/// Height of the iOS 26 Liquid Glass toolbar's content area (excluding the
/// status bar), matching [IOS26NativeToolbar]'s default height. The toolbar is
/// an overlay, so this amount is added to the body's top padding.
const double kToolbarContentHeight = 44.0;

/// Fallback width of the trailing vertical control bar on the iPhone Duo inner
/// display, used only if the system reports no trailing safe-area inset. The
/// bar normally takes the width of that inset (`padding.right`), which is the
/// strip iOS reserves for its own vertical bars and status cluster.
const double kDuoVerticalBarWidth = 60.0;

/// Native iOS 26 scaffold with UITabBar
class IOS26Scaffold extends StatefulWidget {
  const IOS26Scaffold({
    super.key,
    this.bottomNavigationBar,
    this.title,
    this.actions,
    this.leading,
    this.tintColor,
    this.titleWidget,
    this.minimizeBehavior = TabBarMinimizeBehavior.automatic,
    this.enableBlur = true,
    this.useHeroBackButton = true,
    this.tabBarHidden = false,
    this.resizeToAvoidBottomInset,
    required this.children,
  });

  final AdaptiveBottomNavigationBar? bottomNavigationBar;
  final String? title;
  final List<AdaptiveAppBarAction>? actions;
  final Widget? leading;
  final Color? tintColor;

  /// Custom widget overlaid at the toolbar's title position.
  /// When set, the native title is hidden and this widget is centered instead.
  final Widget? titleWidget;
  final TabBarMinimizeBehavior minimizeBehavior;
  final bool enableBlur;
  final bool useHeroBackButton;
  final bool tabBarHidden;
  final bool? resizeToAvoidBottomInset;
  final List<Widget> children;

  @override
  State<IOS26Scaffold> createState() => _IOS26ScaffoldState();
}

class _IOS26ScaffoldState extends State<IOS26Scaffold>
    with SingleTickerProviderStateMixin {
  late AnimationController _tabBarController;
  late Animation<double> _tabBarAnimation;
  bool _isMinimized = false;

  /// Latest iPhone Duo fold / size-class snapshot from the `foldable` package.
  /// Null until the first snapshot arrives; stays null on non-iOS.
  FoldableData? _fold;
  StreamSubscription<FoldableData>? _foldSub;

  /// True on the inner display of an iPhone Duo.
  ///
  /// Branches on the size classes iOS itself lays out from: a regular
  /// horizontal *and* vertical size class is unique to the Duo inner display
  /// among iPhones (the cover display is compact width; a Plus/Max in landscape
  /// is regular width but compact height). This mirrors how the system moves
  /// its own bars to the side there.
  ///
  /// `isFoldable` is deliberately not required: it is derived from the hinge
  /// API, whose status arrives asynchronously after the first snapshot (the
  /// initial value is `unknown`, then the stream reports e.g. `fullyOpen`).
  /// Requiring it would lay the toolbar out at the top on the first frames and
  /// jump it to the side a moment later; the size classes are correct at once.
  ///
  /// Known gap: an iPad is also regular/regular and cannot be told apart by
  /// size class alone; exposing the interface idiom from `foldable` would
  /// close this.
  bool get _isDuoInnerDisplay {
    final fold = _fold;
    if (fold == null) return false;
    return fold.horizontalSizeClass == SizeClass.regular &&
        fold.verticalSizeClass == SizeClass.regular;
  }

  @override
  void initState() {
    super.initState();
    _tabBarController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _tabBarAnimation = CurvedAnimation(
      parent: _tabBarController,
      curve: Curves.easeInOut,
    );
    _listenToFold();
  }

  /// Seeds [_fold] with the current snapshot and follows fold / size-class
  /// changes (opening, closing, rotating, Split View). Failures degrade to
  /// "not foldable" so the normal top toolbar is used.
  void _listenToFold() {
    Foldable.snapshot.then(_onFoldChanged).catchError((Object _) {});
    _foldSub = Foldable.changes.listen(_onFoldChanged, onError: (Object _) {});
  }

  void _onFoldChanged(FoldableData data) {
    if (!mounted) return;
    setState(() => _fold = data);
  }

  @override
  void dispose() {
    _foldSub?.cancel();
    _tabBarController.dispose();
    super.dispose();
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if (widget.minimizeBehavior == TabBarMinimizeBehavior.never) {
      return false;
    }

    if (notification is ScrollUpdateNotification) {
      final delta = notification.scrollDelta ?? 0;

      if (widget.minimizeBehavior == TabBarMinimizeBehavior.onScrollDown ||
          widget.minimizeBehavior == TabBarMinimizeBehavior.automatic) {
        // Minimize when scrolling down (positive delta)
        if (delta > 0 && !_isMinimized) {
          _minimizeTabBar();
        } else if (delta < 0 && _isMinimized) {
          _expandTabBar();
        }
      } else if (widget.minimizeBehavior == TabBarMinimizeBehavior.onScrollUp) {
        // Minimize when scrolling up (negative delta)
        if (delta < 0 && !_isMinimized) {
          _minimizeTabBar();
        } else if (delta > 0 && _isMinimized) {
          _expandTabBar();
        }
      }
    }

    return false;
  }

  void _minimizeTabBar() {
    if (!_isMinimized) {
      _isMinimized = true;
      _tabBarController.forward();
    }
  }

  void _expandTabBar() {
    if (_isMinimized) {
      _isMinimized = false;
      _tabBarController.reverse();
    }
  }

  /// Determines if the current window is in a windowed mode.
  ///
  /// This method compares the display size of the device with the viewport size
  /// calculated from the logical size and device pixel ratio.
  /// It returns true if the sizes do not match, indicating that the application is not in full-screen mode.
  bool _getIsWindowed() {
    final displaySize = View.of(context).display.size;
    final logicalSize = MediaQuery.sizeOf(context);
    final devicePixelRatio = MediaQuery.devicePixelRatioOf(context);
    final viewportSize = Size(
      logicalSize.width * devicePixelRatio,
      logicalSize.height * devicePixelRatio,
    );

    return (displaySize.longestSide != viewportSize.longestSide) ||
        (displaySize.shortestSide != viewportSize.shortestSide);
  }

  /// Width of the trailing strip the system reserves on the iPhone Duo inner
  /// display (its status cluster lives there, so `padding.right` is non-zero
  /// while `padding.top` is 0). The vertical bar sits inside that strip, which
  /// is also where iOS places its own vertical bars. Falls back to
  /// [kDuoVerticalBarWidth] if the inset is ever reported as 0.
  static double _duoBarWidth(EdgeInsets padding) =>
      padding.right > 0 ? padding.right : kDuoVerticalBarWidth;

  /// Top clearance for the vertical bar: below any active occlusion region
  /// (the under-display camera / status cluster) that overlaps the trailing
  /// strip, so controls never sit under the camera the way they would under
  /// the plain top safe-area inset (which is 0 on this display).
  double _duoBarTopClearance(BuildContext context, EdgeInsets padding) {
    final size = MediaQuery.sizeOf(context);
    final stripLeft = size.width - _duoBarWidth(padding);
    var clearance = padding.top;
    for (final region in _fold?.regions ?? const <ReservedRegion>[]) {
      if (region.kind == ReservedRegionKind.occlusion &&
          region.isActive &&
          region.bounds.right > stripLeft) {
        if (region.bounds.bottom > clearance) clearance = region.bounds.bottom;
      }
    }
    return clearance;
  }

  /// The trailing vertical bar used on the iPhone Duo inner display. It holds
  /// the controls the top toolbar would otherwise show, ordered top to bottom
  /// the way the system orders its own vertical bar: primary navigation (back)
  /// first, then the actions in their original grouping.
  ///
  /// This is a Flutter overlay rather than a native bar: iOS only lays out
  /// container-managed bars vertically, never a hand-built UINavigationBar.
  Widget _buildDuoVerticalBar(BuildContext context, Widget? heroLeading) {
    final padding = MediaQuery.paddingOf(context);
    final leading = widget.leading ?? heroLeading;
    final actions = widget.actions ?? const <AdaptiveAppBarAction>[];

    final children = <Widget>[];
    if (leading != null) {
      children.add(leading);
      children.add(const SizedBox(height: 12));
    }
    for (final action in actions) {
      children.add(_buildDuoBarAction(action));
      switch (action.spacerAfter) {
        case ToolbarSpacerType.flexible:
          children.add(const Spacer());
        case ToolbarSpacerType.fixed:
          children.add(const SizedBox(height: 12));
        case ToolbarSpacerType.none:
          children.add(const SizedBox(height: 8));
      }
    }

    return Padding(
      // Safe areas are asymmetric on iPhone Duo; read each edge on its own.
      padding: EdgeInsets.only(
        top: _duoBarTopClearance(context, padding) + 8,
        bottom: padding.bottom + 8,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: children,
      ),
    );
  }

  /// One control in the Duo vertical bar. A narrow, tall bar favours the
  /// icon-only representation, so prefer the SF Symbol (the iOS 26 form),
  /// then a custom icon widget or IconData, and fall back to the title text.
  Widget _buildDuoBarAction(AdaptiveAppBarAction action) {
    final Widget child;
    if (action.iosSymbol != null) {
      child = AdaptiveButton.sfSymbol(
        onPressed: action.onPressed,
        sfSymbol: SFSymbol(action.iosSymbol!, size: 20),
      );
    } else if (action.iconWidget != null) {
      child = CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: action.onPressed,
        child: action.iconWidget!,
      );
    } else if (action.icon != null) {
      child = CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: action.onPressed,
        child: Icon(action.icon, size: 22),
      );
    } else {
      child = CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: action.onPressed,
        child: Text(action.title ?? '', style: const TextStyle(fontSize: 12)),
      );
    }
    return SizedBox(height: 38, width: 38, child: child);
  }

  @override
  Widget build(BuildContext context) {
    // Auto back button logic
    // Priority: custom leading widget > Hero back button
    Widget? heroLeading;

    final canPop = Navigator.of(context).canPop();

    // Only show auto back button if no custom leading widget
    if (widget.leading == null &&
        (widget.bottomNavigationBar?.items == null ||
            widget.bottomNavigationBar!.items!.isEmpty) &&
        canPop) {
      final isCurrent = ModalRoute.of(context)?.isCurrent ?? true;
      if (isCurrent) {
        final backButton = Container(
          // 62px accounts for the iPadOS system window toolbar width in windowed mode
          margin: EdgeInsets.only(left: _getIsWindowed() ? 62 : 0),
          height: 38,
          width: 38,
          child: AdaptiveButton.sfSymbol(
            onPressed: () => Navigator.of(context).pop(),
            sfSymbol: SFSymbol("chevron.left", size: 20),
          ),
        );
        heroLeading = widget.useHeroBackButton
            ? Hero(
                tag: 'adaptive_back_button',
                flightShuttleBuilder: (_, __, ___, ____, toHeroContext) =>
                    toHeroContext.widget,
                child: backButton,
              )
            : backButton;
      } else {
        const placeholder = SizedBox(height: 38, width: 38);
        heroLeading = widget.useHeroBackButton
            ? const Hero(tag: 'adaptive_back_button', child: placeholder)
            : placeholder;
      }
    }

    // Determine if toolbar/tab bar's underlying UiKitView should be shown.
    // Hide native platform views when another route is pushed on top to prevent bleed-through.
    final isCurrentRoute = ModalRoute.of(context)?.isCurrent ?? true;
    final isPopping =
        ModalRoute.of(context)?.animation?.status == AnimationStatus.reverse;

    // The Flutter widgets (like Hero) should ALWAYS stay in the tree during transitions.
    // Only the underlying UiKitView should be hidden.
    final hasToolbarContent =
        (widget.title != null ||
        widget.titleWidget != null ||
        widget.leading != null ||
        heroLeading != null ||
        (widget.actions != null && widget.actions!.isNotEmpty));

    // Show native view only if it's the current route OR it's popping
    final showNativeView = isCurrentRoute || isPopping;

    // Get brightness and determine text color
    final brightness = MediaQuery.platformBrightnessOf(context);
    final textColor = brightness == Brightness.dark
        ? CupertinoColors.white
        : CupertinoColors.black;

    // Content - full screen - use KeepAlive to prevent rebuild
    // Wrap content with DefaultTextStyle to ensure proper text color
    Widget bodyContent = DefaultTextStyle(
      style: TextStyle(
        color: textColor,
        fontSize: 17, // iOS default
      ),
      child: widget.children.length == 1
          ? widget.children.first
          : IndexedStack(
              index: widget.bottomNavigationBar?.selectedIndex ?? 0,
              sizing: StackFit.expand,
              children: widget.children,
            ),
    );

    // iPhone Duo inner display: the system moves *controls* (back button,
    // actions) into a vertical bar on the trailing edge and leaves the title
    // in place. Our toolbar is a hand-built UINavigationBar, which iOS never
    // lays out vertically, so mirror that behaviour here: keep a title-only
    // toolbar at the top (when there is a title) and render the controls in a
    // trailing vertical bar of our own.
    final duo = _isDuoInnerDisplay;
    // iOS keeps horizontal bars on the inner display in portrait and only moves
    // controls to the side while the display is wider than tall, so gate the
    // vertical bar on the pose, not just on the display.
    final size = MediaQuery.sizeOf(context);
    final duoVerticalPose = duo && size.width > size.height;
    final hasTitle = widget.title != null || widget.titleWidget != null;
    final hasControls =
        widget.leading != null ||
        heroLeading != null ||
        (widget.actions != null && widget.actions!.isNotEmpty);
    final showTopToolbar = duoVerticalPose ? hasTitle : hasToolbarContent;
    final showDuoSideBar = duoVerticalPose && hasControls;

    // The Liquid Glass toolbar is drawn as a Positioned overlay on top of the
    // body (see below), so, unlike CupertinoPageScaffold with a translucent
    // nav bar, it does NOT inset the body automatically. Mirror that framework
    // behaviour here by adding the toolbar's height to the body's top padding,
    // so any SafeArea/SliverSafeArea inside a page clears it without per-screen
    // offset hacks. Content still scrolls behind it (scroll-edge effect)
    // because SafeArea insets rather than clips.
    //
    // The Duo vertical bar needs no extra inset: it lives inside the trailing
    // strip the system already reserves (`padding.right`), which SafeArea
    // honours on its own. Adding more would over-inset the body.
    if (showTopToolbar) {
      final mq = MediaQuery.of(context);
      bodyContent = MediaQuery(
        data: mq.copyWith(
          padding: mq.padding.copyWith(
            top: mq.padding.top + kToolbarContentHeight,
          ),
          viewPadding: mq.viewPadding.copyWith(
            top: mq.viewPadding.top + kToolbarContentHeight,
          ),
        ),
        child: bodyContent,
      );
    }

    // Build the stack content
    final stackContent = Stack(
      children: [
        bodyContent,
        // Top toolbar - iOS 26 Liquid Glass style. On iPhone Duo it carries
        // only the title; the controls live in the trailing vertical bar.
        if (showTopToolbar)
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: IOS26NativeToolbar(
              title: widget.title,
              leading: duoVerticalPose ? null : (widget.leading ?? heroLeading),
              showNativeView: showNativeView,
              actions: duoVerticalPose ? null : widget.actions,
              tintColor: widget.tintColor,
              titleWidget: widget.titleWidget,
              onActionTap: (index) {
                // Call the appropriate action callback
                if (widget.actions != null &&
                    index >= 0 &&
                    index < widget.actions!.length) {
                  widget.actions![index].onPressed();
                }
              },
            ),
          ),
        // iPhone Duo: controls in a vertical bar on the trailing edge
        if (showDuoSideBar)
          Positioned(
            top: 0,
            right: 0,
            bottom: 0,
            // Widen the band inward a little so the centred controls sit a
            // few points off the bezel instead of hugging the display edge.
            width: _duoBarWidth(MediaQuery.paddingOf(context)) + 12,
            child: _buildDuoVerticalBar(context, heroLeading),
          ),
        // Tab bar - only show if destinations exist
        if (widget.bottomNavigationBar?.items != null &&
            widget.bottomNavigationBar!.items!.isNotEmpty &&
            widget.bottomNavigationBar!.selectedIndex != null &&
            widget.bottomNavigationBar!.onTap != null)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: AnimatedBuilder(
              animation: _tabBarAnimation,
              builder: (context, child) {
                // Calculate minimized state
                // value: 0.0 = expanded (full size), 1.0 = minimized (70% size, 50% opacity)
                final minimizeProgress = _tabBarAnimation.value;
                final scale = 1.0 - (minimizeProgress * 0.3); // 1.0 → 0.7
                final opacity = 1.0 - (minimizeProgress * 0.5); // 1.0 → 0.5

                return Transform.scale(
                  scale: scale,
                  alignment: Alignment.bottomCenter,
                  child: Opacity(opacity: opacity, child: child),
                );
              },
              child: widget.enableBlur
                  ? IOS26NativeTabBar(
                      destinations: widget.bottomNavigationBar!.items!,
                      selectedIndex: widget.bottomNavigationBar!.selectedIndex!,
                      onTap: widget.bottomNavigationBar!.onTap!,
                      tint: CupertinoTheme.of(context).primaryColor,
                      minimizeBehavior: widget.minimizeBehavior,
                      showNativeView: showNativeView,
                      hidden: widget.tabBarHidden,
                    )
                  : IOS26NativeTabBar(
                      destinations: widget.bottomNavigationBar!.items!,
                      selectedIndex: widget.bottomNavigationBar!.selectedIndex!,
                      onTap: widget.bottomNavigationBar!.onTap!,
                      tint: CupertinoTheme.of(context).primaryColor,
                      minimizeBehavior: widget.minimizeBehavior,
                      showNativeView: showNativeView,
                      hidden: widget.tabBarHidden,
                    ),
            ),
          ),
      ],
    );

    // Only use NotificationListener if tab bar exists (destinations not empty)
    // This allows scroll notifications to bubble up in single-page scenarios
    final hasBottomNav =
        widget.bottomNavigationBar?.items != null &&
        widget.bottomNavigationBar!.items!.isNotEmpty;

    return CupertinoPageScaffold(
      // When a native tab bar is present it sits in Positioned(bottom: 0)
      // inside a Stack. If the scaffold resizes for the keyboard the tab bar
      // floats above it — non-standard on iOS. Disable the resize so the
      // keyboard window (higher z-order) covers the tab bar naturally.
      resizeToAvoidBottomInset:
          widget.resizeToAvoidBottomInset ?? !hasBottomNav,
      child: hasBottomNav
          ? NotificationListener<ScrollNotification>(
              onNotification: _handleScrollNotification,
              child: stackContent,
            )
          : stackContent,
    );
  }
}
