import 'package:flutter/cupertino.dart';
import '../adaptive_app_bar_action.dart';
import '../adaptive_scaffold.dart';
import 'ios26_native_tab_bar.dart';
import 'ios26_native_toolbar.dart';

/// Native iOS 26 scaffold with UITabBar
class IOS26Scaffold extends StatefulWidget {
  const IOS26Scaffold({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
    this.title,
    this.actions,
    this.leading,
    this.minimizeBehavior = TabBarMinimizeBehavior.automatic,
    this.enableBlur = true,
    required this.children,
  });

  final List<AdaptiveNavigationDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final String? title;
  final List<AdaptiveAppBarAction>? actions;
  final Widget? leading;
  final TabBarMinimizeBehavior minimizeBehavior;
  final bool enableBlur;
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
    // Priority: custom leading widget > auto back button
    String? leadingText;
    VoidCallback? leadingCallback;

    final canPop = Navigator.of(context).canPop();

    // Only show auto back button if no custom leading widget
    if (widget.leading == null &&
        widget.destinations.isEmpty &&
        canPop) {
      leadingText = ''; // Empty string = native chevron
      leadingCallback = () {
        Navigator.of(context).pop();
      };
    }

    // Build the stack content
    final stackContent = Stack(
      children: [
        // Content - full screen - use KeepAlive to prevent rebuild
        // If only one child, use it directly (e.g., StatefulNavigationShell from GoRouter)
        // Otherwise use IndexedStack for tab switching
        if (widget.children.length == 1)
          widget.children.first
        else
          IndexedStack(
            index: widget.selectedIndex,
            sizing: StackFit.expand,
            children: widget.children,
          ),
        // Top toolbar - iOS 26 Liquid Glass style
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          child: IOS26NativeToolbar(
            title: widget.title,
            leading: widget.leading, // Custom leading widget has priority
            leadingText: leadingText,
            actions: widget.actions,
            onLeadingTap: leadingCallback,
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
        if (widget.destinations.isNotEmpty)
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
                      destinations: widget.destinations,
                      selectedIndex: widget.selectedIndex,
                      onTap: widget.onDestinationSelected,
                      tint: CupertinoTheme.of(context).primaryColor,
                      minimizeBehavior: widget.minimizeBehavior,
                    )
                  : IOS26NativeTabBar(
                      destinations: widget.destinations,
                      selectedIndex: widget.selectedIndex,
                      onTap: widget.onDestinationSelected,
                      tint: CupertinoTheme.of(context).primaryColor,
                      minimizeBehavior: widget.minimizeBehavior,
                    ),
            ),
          ),
      ],
    );

    // Only use NotificationListener if tab bar exists (destinations not empty)
    // This allows scroll notifications to bubble up in single-page scenarios
    return CupertinoPageScaffold(
      child: widget.destinations.isNotEmpty
          ? NotificationListener<ScrollNotification>(
              onNotification: _handleScrollNotification,
              child: stackContent,
            )
          : stackContent,
    );
  }
}
