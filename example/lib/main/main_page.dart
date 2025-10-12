import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MainPage extends StatelessWidget {
  const MainPage({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return AdaptiveScaffold(
      body: navigationShell,
      selectedIndex: navigationShell.currentIndex,
      onDestinationSelected: (index) => navigationShell.goBranch(index),
      destinations: [
        AdaptiveNavigationDestination(
          icon: PlatformInfo.isIOS ? CupertinoIcons.home : Icons.home_outlined,
          selectedIcon: PlatformInfo.isIOS ? CupertinoIcons.home : Icons.home,
          label: 'Home',
        ),
        AdaptiveNavigationDestination(
          icon: PlatformInfo.isIOS ? CupertinoIcons.info : Icons.info_outline,
          selectedIcon: PlatformInfo.isIOS ? CupertinoIcons.info : Icons.info,
          label: 'Info',
        ),
        AdaptiveNavigationDestination(
          icon: PlatformInfo.isIOS ? CupertinoIcons.search : Icons.search,
          label: 'Search',
        ),
      ],
    );
  }
}
