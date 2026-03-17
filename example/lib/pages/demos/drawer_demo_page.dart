import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';

class DrawerDemoPage extends StatefulWidget {
  const DrawerDemoPage({super.key});

  @override
  State<DrawerDemoPage> createState() => _DrawerDemoPageState();
}

class _DrawerDemoPageState extends State<DrawerDemoPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return AdaptiveScaffold(
      scaffoldKey: _scaffoldKey,
      appBar: AdaptiveAppBar(title: 'Drawer Demo'),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: PlatformInfo.isIOS
                    ? CupertinoColors.systemBlue
                    : Theme.of(context).colorScheme.primary,
              ),
              child: const Text(
                'Adaptive Drawer',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Home'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text('About'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  PlatformInfo.isIOS ? CupertinoIcons.sidebar_left : Icons.menu,
                  size: 64,
                  color: PlatformInfo.isIOS
                      ? CupertinoColors.systemBlue
                      : Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Drawer Support',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Swipe from the left edge or tap the button below to open the drawer.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 32),
                AdaptiveButton(
                  onPressed: () {
                    _scaffoldKey.currentState?.openDrawer();
                  },
                  label: 'Open Drawer',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
