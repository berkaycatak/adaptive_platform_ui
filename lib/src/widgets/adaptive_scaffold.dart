import 'package:adaptive_platform_ui/src/widgets/ios26/ios26_native_tab_bar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../platform/platform_info.dart';
import '../style/sf_symbol.dart';
import 'adaptive_app_bar_action.dart';
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
class AdaptiveScaffold extends StatelessWidget {
  const AdaptiveScaffold({
    super.key,
    this.destinations,
    this.selectedIndex,
    this.onDestinationSelected,
    this.body,
    this.title,
    this.actions,
    this.leading,
    this.floatingActionButton,
    this.minimizeBehavior = TabBarMinimizeBehavior.automatic,
    this.enableBlur = true,
    this.useNativeToolbar = true,
  });

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

  /// Title for the navigation bar
  final String? title;

  /// Action buttons in the navigation bar
  /// - iOS 26+: Rendered as native UIBarButtonItem in UIToolbar
  /// - iOS < 26: Rendered as buttons in CupertinoNavigationBar
  /// - Android: Rendered as IconButtons in Material AppBar
  final List<AdaptiveAppBarAction>? actions;

  /// Leading widget in the navigation bar (e.g., back button)
  final Widget? leading;

  /// Floating action button (Material only)
  final Widget? floatingActionButton;

  /// Tab bar minimize behavior (iOS 26+ only)
  /// Controls how the tab bar minimizes when scrolling
  final TabBarMinimizeBehavior minimizeBehavior;

  /// Enable Liquid Glass blur effect behind tab bar (iOS 26+ only)
  /// When enabled, content behind the tab bar will be blurred
  final bool enableBlur;

  /// Use native iOS 26 toolbar (iOS 26+ only)
  /// When false (default), uses CupertinoNavigationBar for better compatibility
  /// When true, uses native iOS 26 UIToolbar with Liquid Glass effect
  final bool useNativeToolbar;

  @override
  Widget build(BuildContext context) {
    // iOS 26+ with native toolbar enabled - Use IOS26Scaffold
    if (PlatformInfo.isIOS26OrHigher() && useNativeToolbar) {
      // For GoRouter compatibility: Use body directly if it's StatefulNavigationShell
      // Otherwise replicate body for each destination
      List<Widget> childrenList;
      final bodyType = body?.runtimeType.toString() ?? '';
      final isNavigationShell = bodyType.contains('StatefulNavigationShell');

      if (isNavigationShell) {
        // GoRouter's StatefulNavigationShell already manages children
        // Don't replicate, just use it directly
        childrenList = [body ?? const SizedBox.shrink()];
      } else if (destinations != null && destinations!.isNotEmpty) {
        // Tab-based navigation: replicate single body for all tabs with unique keys
        childrenList = List.generate(
          destinations!.length,
          (index) => KeyedSubtree(
            key: ValueKey('tab_$index'),
            child: body ?? const SizedBox.shrink(),
          ),
        );
      } else {
        // Single page: just one body
        childrenList = [body ?? const SizedBox.shrink()];
      }

      return IOS26Scaffold(
        key: ValueKey(
          'ios26_scaffold_${selectedIndex ?? 0}_${body?.runtimeType.toString() ?? "empty"}',
        ),
        destinations: destinations ?? [],
        selectedIndex: selectedIndex ?? 0,
        onDestinationSelected: onDestinationSelected ?? (_) {},
        title: title,
        actions: actions,
        leading: leading,
        minimizeBehavior: minimizeBehavior,
        enableBlur: enableBlur,
        children: childrenList,
      );
    }

    // iOS <26 (iOS 18 and below) OR iOS 26+ with useNativeToolbar: false
    // Use CupertinoPageScaffold with CupertinoTabBar if destinations provided
    if (PlatformInfo.isIOS) {
      // Auto back button for iOS 26+ when useNativeToolbar is false
      Widget? effectiveLeading = leading;
      if (PlatformInfo.isIOS26OrHigher() &&
          !useNativeToolbar &&
          leading == null &&
          (destinations == null || destinations!.isEmpty)) {
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

      if (destinations != null &&
          destinations!.isNotEmpty &&
          selectedIndex != null &&
          onDestinationSelected != null) {
        // Tab-based navigation
        // If no title, actions, or leading, skip navigationBar to avoid nested CupertinoPageScaffold issues
        final hasNavigationBar =
            title != null ||
            (actions != null && actions!.isNotEmpty) ||
            effectiveLeading != null;

        return CupertinoPageScaffold(
          navigationBar: hasNavigationBar
              ? CupertinoNavigationBar(
                  automaticallyImplyLeading: PlatformInfo.isIOS26OrHigher()
                      ? false
                      : true, // Let CupertinoNavigationBar handle back button for iOS < 26
                  middle: title != null ? Text(title!) : null,
                  trailing: actions != null && actions!.isNotEmpty
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: actions!.map((action) {
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
                )
              : null,
          child: Column(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    body ?? const SizedBox.shrink(),
                    if (PlatformInfo.isIOS26OrHigher())
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: IOS26NativeTabBar(
                          selectedIndex: selectedIndex!,
                          onTap: onDestinationSelected!,
                          destinations: destinations!,
                        ),
                      ),
                  ],
                ),
              ),
              if (PlatformInfo.isIOS18OrLower())
                CupertinoTabBar(
                  currentIndex: selectedIndex!,
                  onTap: onDestinationSelected!,
                  items: destinations!.map((dest) {
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
      // If no title, actions, or leading, just return body to avoid nested CupertinoPageScaffold
      if (title == null &&
          (actions == null || actions!.isEmpty) &&
          effectiveLeading == null) {
        return body ?? const SizedBox.shrink();
      }

      return CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          automaticallyImplyLeading: PlatformInfo.isIOS26OrHigher()
              ? false
              : true, // Let CupertinoNavigationBar handle back button for iOS < 26,
          middle: title != null ? Text(title!) : null,
          trailing: actions != null && actions!.isNotEmpty
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: actions!.map((action) {
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
        ),
        child: body ?? const SizedBox.shrink(),
      );
    }

    // Android - Use NavigationBar if destinations provided
    if (destinations != null &&
        destinations!.isNotEmpty &&
        selectedIndex != null &&
        onDestinationSelected != null) {
      // Tab-based navigation
      final hasAppBar =
          title != null ||
          (actions != null && actions!.isNotEmpty) ||
          leading != null;

      return Scaffold(
        appBar: hasAppBar
            ? AppBar(
                title: title != null ? Text(title!) : null,
                actions: actions?.map((action) {
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
                leading: leading,
              )
            : null,
        body: body ?? const SizedBox.shrink(),
        bottomNavigationBar: NavigationBar(
          selectedIndex: selectedIndex!,
          onDestinationSelected: onDestinationSelected!,
          destinations: destinations!.map((dest) {
            return NavigationDestination(
              icon: Icon(dest.icon),
              selectedIcon: dest.selectedIcon != null
                  ? Icon(dest.selectedIcon!)
                  : Icon(dest.icon),
              label: dest.label,
            );
          }).toList(),
        ),
        floatingActionButton: floatingActionButton,
      );
    }

    // Simple page without tabs
    // If no title, actions, or leading, just return body to avoid nested Scaffold
    if (title == null &&
        (actions == null || actions!.isEmpty) &&
        leading == null) {
      return body ?? const SizedBox.shrink();
    }

    return Scaffold(
      appBar: AppBar(
        title: title != null ? Text(title!) : null,
        actions: actions?.map((action) {
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
        leading: leading,
      ),
      body: body ?? const SizedBox.shrink(),
      floatingActionButton: floatingActionButton,
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
