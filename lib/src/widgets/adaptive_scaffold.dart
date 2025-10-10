import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../platform/platform_info.dart';
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
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.children,
    this.title,
    this.actions,
    this.leading,
    this.floatingActionButton,
    this.minimizeBehavior = TabBarMinimizeBehavior.automatic,
  });

  /// Navigation destinations for bottom navigation bar
  final List<AdaptiveNavigationDestination> destinations;

  /// Currently selected destination index
  final int selectedIndex;

  /// Called when a destination is selected
  final ValueChanged<int> onDestinationSelected;

  /// Child widgets for each destination (indexed by selectedIndex)
  final List<Widget> children;

  /// Title for the navigation bar
  final String? title;

  /// Action buttons in the navigation bar
  final List<Widget>? actions;

  /// Leading widget in the navigation bar (e.g., back button)
  final Widget? leading;

  /// Floating action button (Material only)
  final Widget? floatingActionButton;

  /// Tab bar minimize behavior (iOS 26+ only)
  /// Controls how the tab bar minimizes when scrolling
  final TabBarMinimizeBehavior minimizeBehavior;

  @override
  Widget build(BuildContext context) {
    // iOS 26+ - Use native iOS 26 tab bar and navigation bar
    if (PlatformInfo.isIOS26OrHigher()) {
      return iOS26Scaffold(
        destinations: destinations,
        selectedIndex: selectedIndex,
        onDestinationSelected: onDestinationSelected,
        title: title,
        actions: actions,
        leading: leading,
        minimizeBehavior: minimizeBehavior,
        children: children,
      );
    }

    // iOS <26 - Use CupertinoTabScaffold
    if (PlatformInfo.isIOS) {
      return _CupertinoScaffold(
        destinations: destinations,
        selectedIndex: selectedIndex,
        onDestinationSelected: onDestinationSelected,
        title: title,
        actions: actions,
        leading: leading,
        children: children,
      );
    }

    // Android - Use Material Scaffold with NavigationBar
    return _MaterialScaffold(
      destinations: destinations,
      selectedIndex: selectedIndex,
      onDestinationSelected: onDestinationSelected,
      title: title,
      actions: actions,
      leading: leading,
      floatingActionButton: floatingActionButton,
      children: children,
    );
  }
}

/// Cupertino implementation for iOS <26
class _CupertinoScaffold extends StatelessWidget {
  const _CupertinoScaffold({
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
    this.title,
    this.actions,
    this.leading,
    required this.children,
  });

  final List<AdaptiveNavigationDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final String? title;
  final List<Widget>? actions;
  final Widget? leading;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return CupertinoTabScaffold(
      tabBar: CupertinoTabBar(
        currentIndex: selectedIndex,
        onTap: onDestinationSelected,
        items: destinations.map((dest) {
          return BottomNavigationBarItem(
            icon: _getIcon(dest.icon),
            activeIcon: dest.selectedIcon != null
                ? _getIcon(dest.selectedIcon!)
                : _getIcon(dest.icon),
            label: dest.label,
          );
        }).toList(),
      ),
      tabBuilder: (context, index) {
        return CupertinoTabView(
          builder: (context) {
            return CupertinoPageScaffold(
              navigationBar: CupertinoNavigationBar(
                middle: title != null ? Text(title!) : null,
                trailing: actions != null && actions!.isNotEmpty
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: actions!,
                      )
                    : null,
                leading: leading,
              ),
              child: SafeArea(child: children[index]),
            );
          },
        );
      },
    );
  }

  Widget _getIcon(dynamic icon) {
    if (icon is IconData) {
      return Icon(icon);
    } else if (icon is String) {
      // Try to map SF Symbol to Cupertino icon
      return Icon(_sfSymbolToCupertinoIcon(icon));
    }
    return Icon(CupertinoIcons.circle);
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
    };
    return iconMap[sfSymbol] ?? CupertinoIcons.circle;
  }
}

/// Material implementation for Android
class _MaterialScaffold extends StatelessWidget {
  const _MaterialScaffold({
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
    this.title,
    this.actions,
    this.leading,
    this.floatingActionButton,
    required this.children,
  });

  final List<AdaptiveNavigationDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final String? title;
  final List<Widget>? actions;
  final Widget? leading;
  final Widget? floatingActionButton;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: title != null ? Text(title!) : null,
        actions: actions,
        leading: leading,
      ),
      body: IndexedStack(
        index: selectedIndex,
        children: children,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: onDestinationSelected,
        destinations: destinations.map((dest) {
          return NavigationDestination(
            icon: _getIcon(dest.icon),
            selectedIcon: dest.selectedIcon != null
                ? _getIcon(dest.selectedIcon!)
                : _getIcon(dest.icon),
            label: dest.label,
          );
        }).toList(),
      ),
      floatingActionButton: floatingActionButton,
    );
  }

  Widget _getIcon(dynamic icon) {
    if (icon is IconData) {
      return Icon(icon);
    } else if (icon is String) {
      // Try to map SF Symbol to Material icon
      return Icon(_sfSymbolToMaterialIcon(icon));
    }
    return const Icon(Icons.circle);
  }

  IconData _sfSymbolToMaterialIcon(String sfSymbol) {
    const iconMap = {
      'house': Icons.home_outlined,
      'house.fill': Icons.home,
      'magnifyingglass': Icons.search,
      'heart': Icons.favorite_border,
      'heart.fill': Icons.favorite,
      'person': Icons.person_outline,
      'person.fill': Icons.person,
      'gear': Icons.settings_outlined,
      'star': Icons.star_border,
      'star.fill': Icons.star,
      'bell': Icons.notifications_outlined,
      'bell.fill': Icons.notifications,
      'bag': Icons.shopping_bag_outlined,
      'bag.fill': Icons.shopping_bag,
      'bookmark': Icons.bookmark_border,
      'bookmark.fill': Icons.bookmark,
    };
    return iconMap[sfSymbol] ?? Icons.circle;
  }
}
