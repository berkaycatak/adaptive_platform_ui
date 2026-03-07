import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';

void main() {
  group('AdaptiveScaffold tabBarHidden', () {
    testWidgets('accepts tabBarHidden prop and renders body', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AdaptiveScaffold(
            tabBarHidden: true,
            body: Text('Body Content'),
          ),
        ),
      );

      expect(find.text('Body Content'), findsOneWidget);
    });

    testWidgets('defaults tabBarHidden to false', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: AdaptiveScaffold(body: Text('Default'))),
      );

      expect(find.text('Default'), findsOneWidget);
    });

    testWidgets('renders with tabBarHidden and bottom navigation', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AdaptiveScaffold(
            tabBarHidden: true,
            body: const Text('Home'),
            bottomNavigationBar: AdaptiveBottomNavigationBar(
              selectedIndex: 0,
              onTap: (_) {},
              items: const [
                AdaptiveNavigationDestination(icon: Icons.home, label: 'Home'),
                AdaptiveNavigationDestination(
                  icon: Icons.settings,
                  label: 'Settings',
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Home'), findsWidgets);
      expect(find.text('Settings'), findsOneWidget);
    });

    testWidgets('rebuilds when tabBarHidden changes', (
      WidgetTester tester,
    ) async {
      bool hidden = false;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) => MaterialApp(
            home: AdaptiveScaffold(
              tabBarHidden: hidden,
              body: ElevatedButton(
                onPressed: () => setState(() => hidden = !hidden),
                child: Text('hidden=$hidden'),
              ),
              bottomNavigationBar: AdaptiveBottomNavigationBar(
                selectedIndex: 0,
                onTap: (_) {},
                items: const [
                  AdaptiveNavigationDestination(
                    icon: Icons.home,
                    label: 'Home',
                  ),
                  AdaptiveNavigationDestination(
                    icon: Icons.settings,
                    label: 'Settings',
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text('hidden=false'), findsOneWidget);

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      expect(find.text('hidden=true'), findsOneWidget);
    });
  });

  group('IOS26NativeTabBar hidden prop', () {
    testWidgets('accepts hidden prop', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: IOS26NativeTabBar(
              hidden: true,
              destinations: const [
                AdaptiveNavigationDestination(icon: Icons.home, label: 'Home'),
              ],
              selectedIndex: 0,
              onTap: (_) {},
            ),
          ),
        ),
      );

      // On non-iOS, renders the fallback widget
      expect(find.byType(IOS26NativeTabBar), findsOneWidget);
    });

    testWidgets('defaults hidden to false', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: IOS26NativeTabBar(
              destinations: const [
                AdaptiveNavigationDestination(icon: Icons.home, label: 'Home'),
              ],
              selectedIndex: 0,
              onTap: (_) {},
            ),
          ),
        ),
      );

      expect(find.byType(IOS26NativeTabBar), findsOneWidget);
    });
  });
}
