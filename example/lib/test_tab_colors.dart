import 'package:flutter/cupertino.dart';
import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AdaptiveApp(
      title: 'Tab Bar Color Test',
      home: const TestTabColors(),
    );
  }
}

class TestTabColors extends StatefulWidget {
  const TestTabColors({super.key});

  @override
  State<TestTabColors> createState() => _TestTabColorsState();
}

class _TestTabColorsState extends State<TestTabColors> {
  static const _selectedTint = CupertinoDynamicColor.withBrightnessAndContrast(
    color: Color(0xFF075293),
    darkColor: Color(0xFF0A95F0),
    highContrastColor: Color(0xFF003F73),
    darkHighContrastColor: Color(0xFF55B9FF),
  );

  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return AdaptiveScaffold(
      appBar: AdaptiveAppBar(title: 'Tab Bar Color Test'),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Selected Tab: $_selectedIndex',
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 20),
            const Text('Testing selectedItemColor: Dynamic blue'),
            const Text('Testing unselectedItemColor: Green'),
          ],
        ),
      ),
      bottomNavigationBar: AdaptiveBottomNavigationBar(
        items: [
          AdaptiveNavigationDestination(icon: 'house', label: 'Home'),
          AdaptiveNavigationDestination(
            icon: 'magnifyingglass',
            label: 'Search',
            isSearch: true,
          ),
          AdaptiveNavigationDestination(icon: 'person', label: 'Profile'),
          AdaptiveNavigationDestination(icon: 'gearshape', label: 'Settings'),
        ],
        selectedIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        selectedItemColor: _selectedTint,
        unselectedItemColor: CupertinoColors.systemGreen,
        useNativeBottomBar: true, // Test with native iOS 26 bar
      ),
    );
  }
}
