import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:adaptive_platform_ui/src/widgets/ios26/ios26_native_toolbar.dart';
import 'package:adaptive_platform_ui/src/widgets/ios26/ios26_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void usePhone(WidgetTester tester) {
  tester.view.physicalSize = const Size(390 * 3, 844 * 3); // iPhone 12 @3x
  tester.view.devicePixelRatio = 3;
  tester.view.padding = const FakeViewPadding(top: 141, bottom: 102);
  tester.view.viewPadding = const FakeViewPadding(top: 141, bottom: 102);
  addTearDown(tester.view.reset);
}

void main() {
  testWidgets(
    'back button has no extra left margin on iPhone with Display Zoom '
    '(display size differs from physical viewport)',
    (tester) async {
      usePhone(tester);
      // Simulate Display Zoom: native display bounds differ from the app's
      // physical viewport — exactly what caused the 62 px shift on iPhone.
      tester.view.display.size = const Size(
        1284,
        2778,
      ); // iPad Pro physical size
      addTearDown(tester.view.display.resetSize);

      final nav = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: nav,
          home: const IOS26Scaffold(
            title: 'Home',
            useHeroBackButton: false,
            children: [SafeArea(child: Text('body:Home'))],
          ),
        ),
      );
      nav.currentState!.push(
        MaterialPageRoute<void>(
          builder: (_) => const IOS26Scaffold(
            title: 'Detail',
            useHeroBackButton: false,
            children: [SafeArea(child: Text('body:Detail'))],
          ),
        ),
      );
      await tester.pumpAndSettle();

      final back = find.byType(AdaptiveButton);
      expect(back, findsOneWidget);
      // Margin must be 0, not 62.
      final container = tester.widget<Container>(
        find.ancestor(of: back, matching: find.byType(Container)).first,
      );
      expect((container.margin as EdgeInsets?)?.left ?? 0, 0);
    },
  );

  testWidgets('page-owned toolbar uses a circular automatic back button', (
    tester,
  ) async {
    final nav = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: nav,
        home: const IOS26Scaffold(
          title: 'Home',
          useHeroBackButton: false,
          children: [SafeArea(child: Text('body:Home'))],
        ),
      ),
    );
    nav.currentState!.push(
      MaterialPageRoute<void>(
        builder: (_) => const IOS26Scaffold(
          title: 'Detail',
          useHeroBackButton: false,
          children: [SafeArea(child: Text('body:Detail'))],
        ),
      ),
    );
    await tester.pumpAndSettle();

    final toolbar = tester.widget<IOS26NativeToolbar>(
      find.byType(IOS26NativeToolbar),
    );
    expect(toolbar.leading, isNotNull);
    final back = find.byType(AdaptiveButton);
    expect(back, findsOneWidget);
    expect(
      tester.widget<AdaptiveButton>(back).useSmoothRectangleBorder,
      isFalse,
    );

    await tester.tap(back);
    await tester.pumpAndSettle();
    expect(find.text('body:Detail'), findsNothing);
    expect(find.text('body:Home'), findsOneWidget);
  });
}
