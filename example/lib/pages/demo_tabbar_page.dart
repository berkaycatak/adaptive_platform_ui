import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';

/// Demo page showcasing AdaptiveButton features
class DemoTabbarPage extends StatefulWidget {
  const DemoTabbarPage({super.key});

  @override
  State<DemoTabbarPage> createState() => _DemoTabbarPageState();
}

class _DemoTabbarPageState extends State<DemoTabbarPage> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return AdaptiveScaffold(
      title: 'Tabbar Demos',
      selectedIndex: _selectedIndex,
      onDestinationSelected: (index) {
        setState(() {
          if (kDebugMode) {
            print('Index selected: $index');
          }
          _selectedIndex = index;
        });
      },
      actions: [
        AdaptiveAppBarAction(onPressed: () {}, title: "Title"),
        AdaptiveAppBarAction(
          onPressed: () {},
          androidIcon: Icons.info,
          iosSymbol: "info.circle",
        ),
      ],
      destinations: [
        AdaptiveNavigationDestination(
          icon: PlatformInfo.isIOS26OrHigher()
              ? "house.fill"
              : PlatformInfo.isIOS
              ? CupertinoIcons.home
              : Icons.home_outlined,
          selectedIcon: PlatformInfo.isIOS26OrHigher()
              ? "house.fill"
              : PlatformInfo.isIOS
              ? CupertinoIcons.home
              : Icons.home,
          label: 'Home',
        ),
        AdaptiveNavigationDestination(
          icon: PlatformInfo.isIOS26OrHigher()
              ? "person.fill"
              : PlatformInfo.isIOS
              ? CupertinoIcons.person
              : Icons.person_outline,
          selectedIcon: PlatformInfo.isIOS26OrHigher()
              ? "person.fill"
              : PlatformInfo.isIOS
              ? CupertinoIcons.person_fill
              : Icons.person,
          label: 'Profile',
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
      // body is automatically wrapped into a single-item children list for iOS26Scaffold
      // The scaffold handles showing the content based on selectedIndex
      body: _buildPageForIndex(_selectedIndex),
    );
  }

  Widget _buildPageForIndex(int index) {
    String title;
    IconData icon;

    switch (index) {
      case 0:
        title = 'Home Page';
        icon = PlatformInfo.isIOS ? CupertinoIcons.home : Icons.home;
        break;
      case 1:
        title = 'Profile Page';
        icon = PlatformInfo.isIOS ? CupertinoIcons.person : Icons.person;
        break;
      case 2:
        title = 'Search Page';
        icon = PlatformInfo.isIOS ? CupertinoIcons.search : Icons.search;
        break;
      default:
        title = 'Unknown Page';
        icon = Icons.error;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: CupertinoColors.systemBlue),
          const SizedBox(height: 24),
          Text(
            title,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(
            'This is tab $index',
            style: const TextStyle(
              fontSize: 16,
              color: CupertinoColors.systemGrey,
            ),
          ),
        ],
      ),
    );
  }
}
