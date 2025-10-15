import 'package:adaptive_platform_ui/src/widgets/ios26/ios26_native_tab_bar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../platform/platform_info.dart';
import '../style/sf_symbol.dart';
import 'adaptive_app_bar.dart';
import 'adaptive_button.dart';
import 'ios26/ios26_scaffold.dart';

/// Navigation destination for bottom navigation
class AdaptiveNavigationDestination {
  const AdaptiveNavigationDestination({
    required this.icon,
    required this.label,
    this.selectedIcon,
    this.isSearch = false,
  });

  /// Icon to display (SF Symbol name for iOS, IconData for cross-platform)
  final dynamic icon;

  /// Label text for the destination
  final String label;

  /// Optional selected state icon
  final dynamic selectedIcon;

  /// Whether this is a search tab (iOS 26+)
  /// Search tabs are visually separated and transform into a search field
  final bool isSearch;
}

/// Tab bar minimize behavior for iOS 26+
enum TabBarMinimizeBehavior {
  /// Never minimize the tab bar
  never,

  /// Minimize when scrolling down
  onScrollDown,

  /// Minimize when scrolling up
  onScrollUp,

  /// Let the system decide
  automatic,
}

/// An adaptive scaffold that renders platform-specific navigation
class AdaptiveScaffold extends StatefulWidget {
  const AdaptiveScaffold({
    super.key,
    this.appBar,
    this.destinations,
    this.selectedIndex,
    this.onDestinationSelected,
    this.body,
    this.floatingActionButton,
    this.minimizeBehavior = TabBarMinimizeBehavior.automatic,
    this.enableBlur = true,
  });

  /// App bar configuration
  /// If null, no app bar or toolbar will be shown
  final AdaptiveAppBar? appBar;

  /// Navigation destinations for bottom navigation bar
  /// If null, no bottom navigation will be shown
  final List<AdaptiveNavigationDestination>? destinations;

  /// Currently selected destination index
  /// If null, no destination will be selected
  final int? selectedIndex;

  /// Called when a destination is selected
  /// If null, navigation will not be interactive
  final ValueChanged<int>? onDestinationSelected;

  /// Body widget
  final Widget? body;

  /// Floating action button (Material only)
  final Widget? floatingActionButton;

  /// Tab bar minimize behavior (iOS 26+ only)
  /// Controls how the tab bar minimizes when scrolling
  final TabBarMinimizeBehavior minimizeBehavior;

  /// Enable Liquid Glass blur effect behind tab bar (iOS 26+ only)
  /// When enabled, content behind the tab bar will be blurred
  final bool enableBlur;

  @override
  State<AdaptiveScaffold> createState() => _AdaptiveScaffoldState();
}

class _AdaptiveScaffoldState extends State<AdaptiveScaffold> {
  final GlobalKey<_MinimizableTabBarState> _tabBarKey = GlobalKey<_MinimizableTabBarState>();

  @override
  Widget build(BuildContext context) {
    final useNativeToolbar = widget.appBar?.useNativeToolbar ?? false;

    // iOS 26+ with native toolbar enabled - Use IOS26Scaffold
    if (PlatformInfo.isIOS26OrHigher() && useNativeToolbar) {
      // For GoRouter compatibility: Use body directly if it's StatefulNavigationShell
      // Otherwise replicate body for each destination
      List<Widget> childrenList;
      final bodyType = widget.body?.runtimeType.toString() ?? '';
      final isNavigationShell = bodyType.contains('StatefulNavigationShell');

      if (isNavigationShell) {
        // GoRouter's StatefulNavigationShell already manages children
        // Don't replicate, just use it directly
        childrenList = [widget.body ?? const SizedBox.shrink()];
      } else if (widget.destinations != null && widget.destinations!.isNotEmpty) {
        // Tab-based navigation: replicate single body for all tabs with unique keys
        childrenList = List.generate(
          widget.destinations!.length,
          (index) => KeyedSubtree(
            key: ValueKey('tab_$index'),
            child: widget.body ?? const SizedBox.shrink(),
          ),
        );
      } else {
        // Single page: just one body
        childrenList = [widget.body ?? const SizedBox.shrink()];
      }

      return IOS26Scaffold(
        key: ValueKey(
          'ios26_scaffold_${widget.selectedIndex ?? 0}_${widget.body?.runtimeType.toString() ?? "empty"}',
        ),
        destinations: widget.destinations ?? [],
        selectedIndex: widget.selectedIndex ?? 0,
        onDestinationSelected: widget.onDestinationSelected ?? (_) {},
        title: widget.appBar?.title,
        actions: widget.appBar?.actions,
        leading: widget.appBar?.leading,
        minimizeBehavior: widget.minimizeBehavior,
        enableBlur: widget.enableBlur,
        children: childrenList,
      );
    }

    // iOS <26 (iOS 18 and below) OR iOS 26+ with useNativeToolbar: false
    // Use CupertinoPageScaffold with CupertinoTabBar if destinations provided
    if (PlatformInfo.isIOS) {
      // Auto back button for iOS 26+ when useNativeToolbar is false
      Widget? effectiveLeading = widget.appBar?.leading;
      if (PlatformInfo.isIOS26OrHigher() &&
          !useNativeToolbar &&
          widget.appBar?.leading == null &&
          (widget.destinations == null || widget.destinations!.isEmpty)) {
        // Check if we can pop AND this is the current route (to prevent showing on previous page during transition)
        final canPop = Navigator.maybeOf(context)?.canPop() ?? false;
        final isCurrent = ModalRoute.of(context)?.isCurrent ?? true;

        if (canPop) {
          if (isCurrent) {
            // Active route: show animated back button
            effectiveLeading = _AnimatedBackButton(
              onPressed: () => Navigator.of(context).pop(),
            );
          } else {
            // Transition/background route: show empty SizedBox to prevent native back button
            effectiveLeading = const SizedBox(height: 38, width: 38);
          }
        }
      }

      if (widget.destinations != null &&
          widget.destinations!.isNotEmpty &&
          widget.selectedIndex != null &&
          widget.onDestinationSelected != null) {
        // Tab-based navigation

        // Determine which navigation bar to use
        ObstructingPreferredSizeWidget? navigationBar;

        // Priority 1: Custom CupertinoNavigationBar (if provided and useNativeToolbar is false)
        if (widget.appBar?.cupertinoNavigationBar != null) {
          navigationBar = widget.appBar!.cupertinoNavigationBar as ObstructingPreferredSizeWidget;
        }
        // Priority 2: Build from title, actions, leading (if appBar has content)
        else if (widget.appBar != null &&
            (widget.appBar!.title != null ||
                (widget.appBar!.actions != null && widget.appBar!.actions!.isNotEmpty) ||
                effectiveLeading != null)) {
          navigationBar = CupertinoNavigationBar(
            automaticallyImplyLeading: PlatformInfo.isIOS26OrHigher()
                ? false
                : true, // Let CupertinoNavigationBar handle back button for iOS < 26
            middle: widget.appBar!.title != null ? Text(widget.appBar!.title!) : null,
            trailing: widget.appBar!.actions != null && widget.appBar!.actions!.isNotEmpty
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: widget.appBar!.actions!.map((action) {
                      Widget actionChild;
                      if (action.title != null) {
                        actionChild = Text(action.title!);
                      } else if (action.iosSymbol != null) {
                        actionChild = Icon(
                          _sfSymbolToCupertinoIcon(action.iosSymbol!),
                        );
                      } else {
                        actionChild = const Icon(CupertinoIcons.circle);
                      }
                      return CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: action.onPressed,
                        child: actionChild,
                      );
                    }).toList(),
                  )
                : null,
            leading: effectiveLeading,
          );
        }

        return CupertinoPageScaffold(
          navigationBar: navigationBar,
          child: Column(
            children: [
              Expanded(
                child: NotificationListener<ScrollNotification>(
                  onNotification: (notification) {
                    // Forward scroll notifications to _MinimizableTabBar state
                    _tabBarKey.currentState?.handleScrollNotification(notification);
                    return false; // Let it bubble up
                  },
                  child: Stack(
                    children: [
                      widget.body ?? const SizedBox.shrink(),
                      if (PlatformInfo.isIOS26OrHigher())
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: _MinimizableTabBar(
                            key: _tabBarKey,
                            selectedIndex: widget.selectedIndex!,
                            onTap: widget.onDestinationSelected!,
                            destinations: widget.destinations!,
                            minimizeBehavior: widget.minimizeBehavior,
                            enableBlur: widget.enableBlur,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              if (PlatformInfo.isIOS18OrLower())
                CupertinoTabBar(
                  currentIndex: widget.selectedIndex!,
                  onTap: widget.onDestinationSelected!,
                  items: widget.destinations!.map((dest) {
                    return BottomNavigationBarItem(
                      icon: Icon(dest.icon),
                      activeIcon: dest.selectedIcon != null
                          ? Icon(dest.selectedIcon!)
                          : Icon(dest.icon),
                      label: dest.label,
                    );
                  }).toList(),
                ),
            ],
          ),
        );
      }

      // Simple page without tabs

      // Determine which navigation bar to use
      ObstructingPreferredSizeWidget? navigationBar;

      // Priority 1: Custom CupertinoNavigationBar (if provided and useNativeToolbar is false)
      if (widget.appBar?.cupertinoNavigationBar != null) {
        navigationBar = widget.appBar!.cupertinoNavigationBar as ObstructingPreferredSizeWidget;
      }
      // Priority 2: Build from title, actions, leading (if appBar has content)
      else if (widget.appBar != null &&
          (widget.appBar!.title != null ||
              (widget.appBar!.actions != null && widget.appBar!.actions!.isNotEmpty) ||
              effectiveLeading != null)) {
        navigationBar = CupertinoNavigationBar(
          automaticallyImplyLeading: PlatformInfo.isIOS26OrHigher()
              ? false
              : true, // Let CupertinoNavigationBar handle back button for iOS < 26
          middle: widget.appBar!.title != null ? Text(widget.appBar!.title!) : null,
          trailing: widget.appBar!.actions != null && widget.appBar!.actions!.isNotEmpty
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: widget.appBar!.actions!.map((action) {
                    Widget actionChild;
                    if (action.title != null) {
                      actionChild = Text(action.title!);
                    } else if (action.iosSymbol != null) {
                      actionChild = Icon(
                        _sfSymbolToCupertinoIcon(action.iosSymbol!),
                      );
                    } else {
                      actionChild = const Icon(CupertinoIcons.circle);
                    }
                    return CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: action.onPressed,
                      child: actionChild,
                    );
                  }).toList(),
                )
              : null,
          leading: effectiveLeading,
        );
      }

      // If no navigation bar, just return body
      if (navigationBar == null) {
        return widget.body ?? const SizedBox.shrink();
      }

      return CupertinoPageScaffold(
        navigationBar: navigationBar,
        child: widget.body ?? const SizedBox.shrink(),
      );
    }

    // Android - Use NavigationBar if destinations provided
    if (widget.destinations != null &&
        widget.destinations!.isNotEmpty &&
        widget.selectedIndex != null &&
        widget.onDestinationSelected != null) {
      // Tab-based navigation

      // Determine which app bar to use
      PreferredSizeWidget? appBar;

      // Priority 1: Custom AppBar (if provided)
      if (widget.appBar?.appBar != null) {
        appBar = widget.appBar!.appBar;
      }
      // Priority 2: Build from title, actions, leading (if appBar has content)
      else if (widget.appBar != null &&
          (widget.appBar!.title != null ||
              (widget.appBar!.actions != null && widget.appBar!.actions!.isNotEmpty) ||
              widget.appBar!.leading != null)) {
        appBar = AppBar(
          title: widget.appBar!.title != null ? Text(widget.appBar!.title!) : null,
          actions: widget.appBar!.actions?.map((action) {
            if (action.title != null) {
              return TextButton(
                onPressed: action.onPressed,
                child: Text(action.title!),
              );
            }
            return IconButton(
              icon: action.androidIcon != null
                  ? Icon(action.androidIcon!)
                  : const Icon(Icons.circle),
              onPressed: action.onPressed,
            );
          }).toList(),
          leading: widget.appBar!.leading,
        );
      }

      return Scaffold(
        appBar: appBar,
        body: widget.body ?? const SizedBox.shrink(),
        bottomNavigationBar: NavigationBar(
          selectedIndex: widget.selectedIndex!,
          onDestinationSelected: widget.onDestinationSelected!,
          destinations: widget.destinations!.map((dest) {
            return NavigationDestination(
              icon: Icon(dest.icon),
              selectedIcon: dest.selectedIcon != null
                  ? Icon(dest.selectedIcon!)
                  : Icon(dest.icon),
              label: dest.label,
            );
          }).toList(),
        ),
        floatingActionButton: widget.floatingActionButton,
      );
    }

    // Simple page without tabs

    // Determine which app bar to use
    PreferredSizeWidget? appBar;

    // Priority 1: Custom AppBar (if provided)
    if (widget.appBar?.appBar != null) {
      appBar = widget.appBar!.appBar;
    }
    // Priority 2: Build from title, actions, leading (if appBar has content)
    else if (widget.appBar != null &&
        (widget.appBar!.title != null ||
            (widget.appBar!.actions != null && widget.appBar!.actions!.isNotEmpty) ||
            widget.appBar!.leading != null)) {
      appBar = AppBar(
        title: widget.appBar!.title != null ? Text(widget.appBar!.title!) : null,
        actions: widget.appBar!.actions?.map((action) {
          if (action.title != null) {
            return TextButton(
              onPressed: action.onPressed,
              child: Text(action.title!),
            );
          }
          return IconButton(
            icon: action.androidIcon != null
                ? Icon(action.androidIcon!)
                : const Icon(Icons.circle),
            onPressed: action.onPressed,
          );
        }).toList(),
        leading: widget.appBar!.leading,
      );
    }

    // If no app bar, just return body
    if (appBar == null) {
      return widget.body ?? const SizedBox.shrink();
    }

    return Scaffold(
      appBar: appBar,
      body: widget.body ?? const SizedBox.shrink(),
      floatingActionButton: widget.floatingActionButton,
    );
  }

  IconData _sfSymbolToCupertinoIcon(String sfSymbol) {
    const iconMap = {
      'house': CupertinoIcons.house,
      'house.fill': CupertinoIcons.house_fill,
      'magnifyingglass': CupertinoIcons.search,
      'heart': CupertinoIcons.heart,
      'heart.fill': CupertinoIcons.heart_fill,
      'person': CupertinoIcons.person,
      'person.fill': CupertinoIcons.person_fill,
      'gear': CupertinoIcons.settings,
      'star': CupertinoIcons.star,
      'star.fill': CupertinoIcons.star_fill,
      'bell': CupertinoIcons.bell,
      'bell.fill': CupertinoIcons.bell_fill,
      'bag': CupertinoIcons.bag,
      'bag.fill': CupertinoIcons.bag_fill,
      'bookmark': CupertinoIcons.bookmark,
      'bookmark.fill': CupertinoIcons.bookmark_fill,
      'info.circle': CupertinoIcons.info_circle,
      'plus.circle': CupertinoIcons.add_circled,
      'plus': CupertinoIcons.add,
      'checkmark.circle': CupertinoIcons.checkmark_circle,
    };
    return iconMap[sfSymbol] ?? CupertinoIcons.circle;
  }
}

/// Minimizable tab bar wrapper for iOS 26+ (used when useNativeToolbar: false)
/// Just handles animation, scroll notification is handled by parent
class _MinimizableTabBar extends StatefulWidget {
  const _MinimizableTabBar({
    super.key,
    required this.selectedIndex,
    required this.onTap,
    required this.destinations,
    required this.minimizeBehavior,
    required this.enableBlur,
  });

  final int selectedIndex;
  final ValueChanged<int> onTap;
  final List<AdaptiveNavigationDestination> destinations;
  final TabBarMinimizeBehavior minimizeBehavior;
  final bool enableBlur;

  @override
  State<_MinimizableTabBar> createState() => _MinimizableTabBarState();
}

class _MinimizableTabBarState extends State<_MinimizableTabBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isMinimized = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Called from parent's NotificationListener
  void handleScrollNotification(ScrollNotification notification) {
    if (widget.minimizeBehavior == TabBarMinimizeBehavior.never) {
      return;
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
  }

  void _minimizeTabBar() {
    if (!_isMinimized && mounted) {
      _isMinimized = true;
      _controller.forward();
    }
  }

  void _expandTabBar() {
    if (_isMinimized && mounted) {
      _isMinimized = false;
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        // Calculate minimized state
        // value: 0.0 = expanded (full size), 1.0 = minimized (70% size, 50% opacity)
        final minimizeProgress = _animation.value;
        final scale = 1.0 - (minimizeProgress * 0.3); // 1.0 → 0.7
        final opacity = 1.0 - (minimizeProgress * 0.5); // 1.0 → 0.5

        return Transform.scale(
          scale: scale,
          alignment: Alignment.bottomCenter,
          child: Opacity(
            opacity: opacity,
            child: child,
          ),
        );
      },
      child: IOS26NativeTabBar(
        destinations: widget.destinations,
        selectedIndex: widget.selectedIndex,
        onTap: widget.onTap,
        tint: CupertinoTheme.of(context).primaryColor,
        minimizeBehavior: widget.minimizeBehavior,
      ),
    );
  }
}

/// Animated back button for iOS 26+
/// Fades out when pressed
class _AnimatedBackButton extends StatefulWidget {
  const _AnimatedBackButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  State<_AnimatedBackButton> createState() => _AnimatedBackButtonState();
}

class _AnimatedBackButtonState extends State<_AnimatedBackButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  bool _isPopping = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _opacityAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handlePressed() {
    if (_isPopping) return;

    setState(() {
      _isPopping = true;
    });

    // Start animation and pop immediately (parallel)
    _controller.forward();
    widget.onPressed();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _opacityAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _isPopping ? 0.0 : _opacityAnimation.value,
          child: IgnorePointer(ignoring: _isPopping, child: child),
        );
      },
      child: SizedBox(
        height: 38,
        width: 38,
        child: AdaptiveButton.sfSymbol(
          onPressed: _handlePressed,
          sfSymbol: SFSymbol("chevron.left", size: 20),
        ),
      ),
    );
  }
}
