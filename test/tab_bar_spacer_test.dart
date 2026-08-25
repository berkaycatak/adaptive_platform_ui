import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// `addSpacerAfter` only does anything on the iOS 26+ native tab bar, which is a
/// UIKit platform view and so cannot run under `flutter test` — on the host
/// `Platform.isIOS` is false, so the platform view is never instantiated and
/// every `AdaptiveScaffold` falls through to the Material path regardless of the
/// enclosing app widget. These tests therefore cover only what is reachable from
/// the host: the flag's default, that it round-trips, and that setting it leaves
/// the non-iOS tab bar untouched.
void main() {
  group('AdaptiveNavigationDestination.addSpacerAfter', () {
    test('defaults to false', () {
      const destination = AdaptiveNavigationDestination(
        icon: Icons.home,
        label: 'Home',
      );

      expect(destination.addSpacerAfter, isFalse);
    });

    test('is kept as given', () {
      const destination = AdaptiveNavigationDestination(
        icon: Icons.grid_view,
        label: 'View',
        addSpacerAfter: true,
      );

      expect(destination.addSpacerAfter, isTrue);
    });

    testWidgets('does not disturb the Material bottom navigation', (
      WidgetTester tester,
    ) async {
      var tapped = -1;

      await tester.pumpWidget(
        MaterialApp(
          home: AdaptiveScaffold(
            body: const Text('Body'),
            bottomNavigationBar: AdaptiveBottomNavigationBar(
              selectedIndex: 0,
              onTap: (index) => tapped = index,
              items: const [
                AdaptiveNavigationDestination(icon: Icons.home, label: 'Home'),
                AdaptiveNavigationDestination(
                  icon: Icons.person,
                  label: 'Profile',
                  addSpacerAfter: true,
                ),
                AdaptiveNavigationDestination(
                  icon: Icons.grid_view,
                  label: 'View',
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Body'), findsOneWidget);
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);
      expect(find.text('View'), findsOneWidget);

      await tester.tap(find.text('View'));
      expect(tapped, 2);
    });
  });
}
