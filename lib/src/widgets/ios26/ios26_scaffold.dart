import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:foldable/foldable.dart';
import '../../style/sf_symbol.dart';
import '../../toolbar/duo_vertical_bar.dart';
import '../../toolbar/toolbar_chrome_scope.dart';
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
    this.useFixedToolbar = true,
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

  /// Whether the fixed toolbar host, when there is one, draws this page's
  /// toolbar. False makes the page draw its own, as it does without a host.
  final bool useFixedToolbar;
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

    // Show native view only if it's the current route OR it's popping, AND the tab bar is not explicitly hidden
    final showNativeView = (isCurrentRoute || isPopping) && !widget.tabBarHidden;

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

    // iPhone Duo (inner display, and the cover display while folded): the
    // system reserves a trailing strip and moves *controls* (back button,
    // actions) into a vertical bar on the trailing edge and leaves the title
    // in place. Our toolbar is a hand-built UINavigationBar, which iOS never
    // lays out vertically, so mirror that behaviour here: keep a title-only
    // toolbar at the top (when there is a title) and render the controls in a
    // trailing vertical bar of our own.
    //
    // With an AdaptiveToolbarHost above the navigator the host decides the
    // pose and draws the one fixed vertical bar for every page, so this page
    // keeps only its title. Without a host it draws its own bar.
    final chrome = widget.useFixedToolbar
        ? ToolbarChromeScope.maybeOf(context)
        : null;
    final duoVerticalPose =
        chrome?.hostsDuoControls ??
        DuoLayout.isVerticalBarPose(MediaQuery.viewPaddingOf(context));
    final hasTitle = widget.title != null || widget.titleWidget != null;
    final hasControls =
        widget.leading != null ||
        heroLeading != null ||
        (widget.actions != null && widget.actions!.isNotEmpty);
    final showTopToolbar = duoVerticalPose ? hasTitle : hasToolbarContent;
    final tabs = widget.tabBarHidden ? null : widget.bottomNavigationBar;
    final hasTabs = tabs?.items?.isNotEmpty ?? false;
    final showDuoSideBar =
        duoVerticalPose && (hasControls || hasTabs) && chrome == null;

    // The Liquid Glass toolbar is drawn as a Positioned overlay on top of the
    // body (see below), so, unlike CupertinoPageScaffold with a translucent
    // nav bar, it does NOT inset the body automatically. Mirror that framework
    // behaviour here by adding the toolbar's height to the body's top padding,
    // so any SafeArea/SliverSafeArea inside a page clears it without per-screen
    // offset hacks. Content still scrolls behind it (scroll-edge effect)
    // because SafeArea insets rather than clips.
    //
    // On iPhone Duo the body is also kept out of the trailing strip, the way
    // UIKit keeps content out of it: that strip holds the status cluster and
    // the vertical bar, and a page that does not use SafeArea would otherwise
    // run underneath both. The inset is taken from `padding` and consumed, so
    // a scaffold nested in this one (a tab inside a shell) does not inset a
    // second time, and a SafeArea further down has nothing left to add.
    final mq = MediaQuery.of(context);
    // The strip is on the right in most poses and on the left in one
    // landscape rotation; the controls stay aligned with the hardware.
    final barOnLeft = DuoLayout.barSide(mq.viewPadding) == DuoBarSide.left;
    final trailingInset = !duoVerticalPose
        ? 0.0
        : barOnLeft
        ? mq.padding.left
        : mq.padding.right;
    if (showTopToolbar || trailingInset > 0) {
      final topInset = !showTopToolbar
          ? 0.0
          : duoVerticalPose
          ? kDuoTitleBandHeight
          : kToolbarContentHeight;
      bodyContent = Padding(
        padding: EdgeInsets.only(
          left: barOnLeft ? trailingInset : 0,
          right: barOnLeft ? 0 : trailingInset,
        ),
        child: MediaQuery(
          data: mq.copyWith(
            padding: mq.padding.copyWith(
              top: mq.padding.top + topInset,
              left: mq.padding.left - (barOnLeft ? trailingInset : 0),
              right: mq.padding.right - (barOnLeft ? 0 : trailingInset),
            ),
            viewPadding: mq.viewPadding.copyWith(
              top: mq.viewPadding.top + topInset,
            ),
          ),
          child: bodyContent,
        ),
      );
    }

    // Build the stack content
    final stackContent = Stack(
      children: [
        bodyContent,
        // Top toolbar - iOS 26 Liquid Glass style. On iPhone Duo it carries
        // only the title; the controls live in the trailing vertical bar.
        if (showTopToolbar && !(chrome?.hostsToolbar ?? false))
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: duoVerticalPose ? kDuoTitleBandHeight : null,
            child: duoVerticalPose
                // On iPhone Duo the title sits at the leading edge; the
                // controls are in the trailing bar.
                ? Stack(
                    fit: StackFit.expand,
                    clipBehavior: Clip.none,
                    children: [
                      const DuoTitleBackdrop(),
                      DuoToolbarTitle(
                        title: widget.title,
                        titleWidget: widget.titleWidget,
                      ),
                    ],
                  )
                : IOS26NativeToolbar(
                    title: widget.title,
                    leading: duoVerticalPose
                        ? null
                        : (widget.leading ?? heroLeading),
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
            bottom: 0,
            left: barOnLeft ? 0 : null,
            right: barOnLeft ? null : 0,
            width: DuoLayout.bandWidth(MediaQuery.viewPaddingOf(context)),
            child: DuoVerticalBar(
              leading:
                  widget.leading ??
                  (heroLeading == null
                      ? null
                      : DuoBarBackButton(
                          onPressed: () => Navigator.of(context).maybePop(),
                        )),
              actions: widget.actions ?? const <AdaptiveAppBarAction>[],
              tabBar: tabs,
              tint: widget.tintColor,
              regions: _fold?.regions ?? const <ReservedRegion>[],
            ),
          ),
        // Tab bar - only show if destinations exist
        // On iPhone Duo the tabs are at the bottom of the trailing bar instead.
        if (!duoVerticalPose &&
            widget.bottomNavigationBar?.items != null &&
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
