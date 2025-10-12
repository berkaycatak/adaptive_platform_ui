import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:adaptive_platform_ui_example/service/router/router_service.dart';
import 'package:adaptive_platform_ui_example/utils/global_variables.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MainPage extends StatelessWidget {
  const MainPage({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        AdaptiveScaffold(
          body: navigationShell,
          selectedIndex: navigationShell.currentIndex,
          onDestinationSelected: onDestinationSelected,
          destinations: [
            AdaptiveNavigationDestination(
              icon: PlatformInfo.isIOS26OrHigher()
                  ? "house.fill"
                  : PlatformInfo.isIOS
                  ? CupertinoIcons.home
                  : Icons.home_outlined,
              selectedIcon: PlatformInfo.isIOS
                  ? CupertinoIcons.home
                  : Icons.home,
              label: 'Home',
            ),
            AdaptiveNavigationDestination(
              icon: PlatformInfo.isIOS26OrHigher()
                  ? "info.circle"
                  : PlatformInfo.isIOS
                  ? CupertinoIcons.info
                  : Icons.info_outline,
              selectedIcon: PlatformInfo.isIOS
                  ? CupertinoIcons.info
                  : Icons.info,
              label: 'Info',
            ),
            AdaptiveNavigationDestination(
              icon: PlatformInfo.isIOS26OrHigher()
                  ? "magnifyingglass"
                  : PlatformInfo.isIOS
                  ? CupertinoIcons.search
                  : Icons.search,
              label: 'Search',
              isSearch: true,
            ),
          ],
        ),
      ],
    );
  }

  void onDestinationSelected(tappedIndex) {
    // scroll to top if the user taps the current tab
    var matchedLocation = GoRouter.of(
      navigatorKey.currentContext!,
    ).routerDelegate.currentConfiguration.last.matchedLocation;

    if (navigationShell.currentIndex == tappedIndex) {
      String routePath = "";
      switch (tappedIndex) {
        case 0:
          if (matchedLocation != RouterService.routes.home) {
            routePath = RouterService.routes.home;
          } else {
            homeScrollController.animateTo(
              0,
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut,
            );
          }
          break;
        case 1:
          if (matchedLocation != RouterService.routes.info) {
            routePath = RouterService.routes.info;
          } else {
            infoScrollController.animateTo(
              0,
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut,
            );
          }
          break;
        case 2:
          if (matchedLocation != RouterService.routes.search) {
            routePath = RouterService.routes.search;
          } else {
            // searchScrollController.animateTo(
            //   0,
            //   duration: const Duration(milliseconds: 500),
            //   curve: Curves.easeInOut,
            // );
          }
          break;
      }

      if (routePath.isEmpty) {
        return;
      }

      RouterService.goNamed(
        context: navigatorKey.currentContext!,
        route: routePath,
      );
    }

    navigationShell.goBranch(tappedIndex);
  }
}
