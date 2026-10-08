import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:adaptive_platform_ui/src/widgets/ios26/ios26_native_toolbar.dart';
import 'package:adaptive_platform_ui/src/widgets/ios26/ios26_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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
