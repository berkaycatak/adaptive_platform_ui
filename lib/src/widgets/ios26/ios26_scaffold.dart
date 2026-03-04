import 'package:flutter/cupertino.dart';
import '../../style/sf_symbol.dart';
import '../adaptive_app_bar_action.dart';
import '../adaptive_bottom_navigation_bar.dart';
import '../adaptive_button.dart';
import '../adaptive_scaffold.dart';
import 'ios26_native_tab_bar.dart';
import 'ios26_native_toolbar.dart';

/// Native iOS 26 scaffold with UITabBar
class IOS26Scaffold extends StatefulWidget {
  const IOS26Scaffold({
    super.key,
    this.bottomNavigationBar,
    this.title,
    this.actions,
    this.leading,
    this.tintColor,
    this.minimizeBehavior = TabBarMinimizeBehavior.automatic,
    this.enableBlur = true,
    this.useHeroBackButton = true,
    required this.children,
  });

  final AdaptiveBottomNavigationBar? bottomNavigationBar;
  final String? title;
  final List<AdaptiveAppBarAction>? actions;
  final Widget? leading;
  final Color? tintColor;
  final TabBarMinimizeBehavior minimizeBehavior;
  final bool enableBlur;
  final bool useHeroBackButton;
  final List<Widget> children;

  @override
  State<IOS26Scaffold> createState() => _IOS26ScaffoldState();
}

class _IOS26ScaffoldState extends State<IOS26Scaffold>
    with SingleTickerProviderStateMixin {
  late AnimationController _tabBarController;
  late Animation<double> _tabBarAnimation;
  bool _isMinimized = false;

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
  }

  @override
  void dispose() {
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
        final backButton = SizedBox(
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

    // Build the stack content
    final stackContent = Stack(
      children: [
        // Content - full screen - use KeepAlive to prevent rebuild
        // Wrap content with DefaultTextStyle to ensure proper text color
        DefaultTextStyle(
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
        ),
        // Top toolbar - iOS 26 Liquid Glass style - only show if there's content
        if (hasToolbarContent)
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: IOS26NativeToolbar(
              title: widget.title,
              leading: widget.leading ?? heroLeading,
              showNativeView: showNativeView,
              actions: widget.actions,
              tintColor: widget.tintColor,
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
                    )
                  : IOS26NativeTabBar(
                      destinations: widget.bottomNavigationBar!.items!,
                      selectedIndex: widget.bottomNavigationBar!.selectedIndex!,
                      onTap: widget.bottomNavigationBar!.onTap!,
                      tint: CupertinoTheme.of(context).primaryColor,
                      minimizeBehavior: widget.minimizeBehavior,
                      showNativeView: showNativeView,
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
      resizeToAvoidBottomInset: !hasBottomNav,
      child: hasBottomNav
          ? NotificationListener<ScrollNotification>(
              onNotification: _handleScrollNotification,
              child: stackContent,
            )
          : stackContent,
    );
  }
}
