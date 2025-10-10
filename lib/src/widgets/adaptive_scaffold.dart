import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../platform/platform_info.dart';
import 'adaptive_app_bar_action.dart';
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
    this.child,
    this.title,
    this.actions,
    this.leading,
    this.floatingActionButton,
    this.minimizeBehavior = TabBarMinimizeBehavior.automatic,
    this.enableBlur = true,
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

  /// Child widget
  final Widget? child;

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

  @override
  Widget build(BuildContext context) {
    // iOS 26+ - Always use native iOS 26 toolbar
    if (PlatformInfo.isIOS26OrHigher()) {
      // If destinations are provided but only one child, replicate child for each destination
      List<Widget> childrenList;
      if (destinations != null && destinations!.isNotEmpty) {
        // Tab-based navigation: replicate single child for all tabs
        childrenList = List.generate(
          destinations!.length,
          (index) => child ?? const SizedBox.shrink(),
        );
      } else {
        // Single page: just one child
        childrenList = [child ?? const SizedBox.shrink()];
      }

      return iOS26Scaffold(
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

    // iOS <26 - Use CupertinoPageScaffold
    if (PlatformInfo.isIOS) {
      return CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
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
          leading: leading,
        ),
        child: child ?? const SizedBox.shrink(),
      );
    }

    // Android/Material platform
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
      body: child ?? const SizedBox.shrink(),
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
