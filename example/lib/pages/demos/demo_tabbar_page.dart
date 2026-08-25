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

  /// Flipped by the detached bubble, which is an action rather than a tab.
  bool _gridView = false;

  Widget _buildCurrentScreen() {
    switch (_selectedIndex) {
      case 0:
        return const HomeScreen();
      case 1:
        return const ProfileScreen();
      default:
        return const HomeScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (PlatformInfo.isAndroid) {
      return Scaffold(
        appBar: AppBar(title: const Text('Tabbar Demos')),
        bottomNavigationBar: BottomNavigationBar(
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
            BottomNavigationBarItem(
              icon: Icon(_gridView ? Icons.list : Icons.grid_view),
              label: 'View',
            ),
          ],
          currentIndex: _selectedIndex,
          onTap: (index) {
            setState(() {
              if (kDebugMode) {
                print('Index selected: $index');
              }
              // addSpacerAfter is iOS 26+ only, so on Android this is just a
              // third item - but it stays an action, not a destination.
              if (index == 2) {
                _gridView = !_gridView;
              } else {
                _selectedIndex = index;
              }
            });
          },
        ),
        body: _buildCurrentScreen(),
      );
    }

    return AdaptiveScaffold(
      appBar: AdaptiveAppBar(
        title: 'Tabbar Demos',
        actions: [
          AdaptiveAppBarAction(onPressed: () {}, title: "Title"),
          AdaptiveAppBarAction(
            onPressed: () {},
            icon: Icons.info,
            iosSymbol: "info.circle",
          ),
        ],
      ),
      bottomNavigationBar: AdaptiveBottomNavigationBar(
        selectedIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            if (kDebugMode) {
              print('Index selected: $index');
            }
            if (index == 2) {
              _gridView = !_gridView;
            } else {
              _selectedIndex = index;
            }
          });
        },

        items: [
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
            // Ends the tab group: everything after this is drawn beside the
            // pill as a separate circular button on iOS 26+.
            addSpacerAfter: true,
          ),
          // Not a tab - tapping it flips the view mode and leaves
          // selectedIndex alone, so the highlight stays on Home/Profile.
          // (isSearch is demonstrated in main/main_page.dart instead; it claims
          // the same single detached slot, so the two cannot share a bar.)
          AdaptiveNavigationDestination(
            icon: PlatformInfo.isIOS26OrHigher()
                ? (_gridView ? "list.bullet" : "square.grid.2x2")
                : PlatformInfo.isIOS
                ? (_gridView
                      ? CupertinoIcons.list_bullet
                      : CupertinoIcons.square_grid_2x2)
                : (_gridView ? Icons.list : Icons.grid_view),
            label: 'View',
          ),
        ],
      ),

      // body is automatically wrapped into a single-item children list for iOS26Scaffold
      // The scaffold handles showing the content based on selectedIndex
      body: _buildCurrentScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    if (kDebugMode) {
      print("Home Screen initState called");
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return const Text("Home Screen");
  }
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    if (kDebugMode) {
      print("Profile Screen initState called");
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return const Text("Profile Screen");
  }
}
