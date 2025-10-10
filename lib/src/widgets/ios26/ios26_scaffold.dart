import 'package:flutter/cupertino.dart';
import '../adaptive_scaffold.dart';
import 'ios26_native_tab_bar.dart';

/// Native iOS 26 scaffold with UITabBar
class iOS26Scaffold extends StatefulWidget {
  const iOS26Scaffold({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
    this.title,
    this.actions,
    this.leading,
    this.minimizeBehavior = TabBarMinimizeBehavior.automatic,
    required this.children,
  });

  final List<AdaptiveNavigationDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final String? title;
  final List<Widget>? actions;
  final Widget? leading;
  final TabBarMinimizeBehavior minimizeBehavior;
  final List<Widget> children;

  @override
  State<iOS26Scaffold> createState() => _iOS26ScaffoldState();
}

class _iOS26ScaffoldState extends State<iOS26Scaffold>
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
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: widget.title != null ? Text(widget.title!) : null,
        trailing: widget.actions != null && widget.actions!.isNotEmpty
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: widget.actions!,
              )
            : null,
        leading: widget.leading,
        backgroundColor: CupertinoColors.systemBackground.resolveFrom(context),
        border: Border(
          bottom: BorderSide(
            color: CupertinoColors.separator.resolveFrom(context),
            width: 0.0,
          ),
        ),
      ),
      child: NotificationListener<ScrollNotification>(
        onNotification: _handleScrollNotification,
        child: Stack(
          children: [
            // Content - full screen
            IndexedStack(
              index: widget.selectedIndex,
              children: widget.children,
            ),
            // Tab bar - overlay at bottom with transparent blur effect
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: AnimatedBuilder(
                animation: _tabBarAnimation,
                builder: (context, child) {
                  // Calculate minimized state
                  final minimizeProgress = _tabBarAnimation.value;
                  final scale = 1.0 - (minimizeProgress * 0.3); // Scale down to 70%
                  final opacity = 1.0 - (minimizeProgress * 0.5); // Fade to 50%

                  return Transform.scale(
                    scale: scale,
                    alignment: Alignment.bottomCenter,
                    child: Opacity(
                      opacity: opacity,
                      child: child,
                    ),
                  );
                },
                child: iOS26NativeTabBar(
                  destinations: widget.destinations,
                  selectedIndex: widget.selectedIndex,
                  onTap: widget.onDestinationSelected,
                  tint: CupertinoTheme.of(context).primaryColor,
                  minimizeBehavior: widget.minimizeBehavior,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
