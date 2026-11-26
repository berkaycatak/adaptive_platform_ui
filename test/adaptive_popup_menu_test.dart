import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
// Public barrel only — these are the symbols consumers actually import.
import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';

void main() {
  group('AdaptivePopupMenuItem.isDestructive', () {
    test('defaults to false', () {
      const item = AdaptivePopupMenuItem<String>(label: 'Edit');
      expect(item.isDestructive, isFalse);
    });

    test('stores true when set', () {
      const item = AdaptivePopupMenuItem<String>(
        label: 'Delete',
        isDestructive: true,
      );
      expect(item.isDestructive, isTrue);
    });
  });

  group('AdaptivePopupMenuItem subtitle/imageBytes', () {
    test('default to null', () {
      const item = AdaptivePopupMenuItem<String>(label: 'Edit');
      expect(item.subtitle, isNull);
      expect(item.imageBytes, isNull);
    });

    test('store subtitle and imageBytes when set', () {
      final bytes = Uint8List.fromList([1, 2, 3]);
      final item = AdaptivePopupMenuItem<String>(
        label: 'Jamie Doe',
        subtitle: 'Online',
        imageBytes: bytes,
      );
      expect(item.subtitle, 'Online');
      expect(item.imageBytes, same(bytes));
    });
  });

  group('AdaptivePopupMenuButton.widget onTap/triggerOnLongPress guard', () {
    // The assert lives at the public dispatch point (AdaptivePopupMenuButton.widget),
    // so the contract is enforced uniformly on every platform path — not just the
    // iOS-26 native path. This is the load-bearing case consumers actually touch.
    const items = <AdaptivePopupMenuEntry>[
      AdaptivePopupMenuItem<String>(label: 'One'),
    ];
    void onSelected(int index, AdaptivePopupMenuItem<String> entry) {}

    test('throws when onTap is set without triggerOnLongPress', () {
      expect(
        () => AdaptivePopupMenuButton.widget<String>(
          items: items,
          onSelected: onSelected,
          onTap: () {},
          child: const SizedBox(),
        ),
        throwsAssertionError,
      );
    });

    test('does not throw when onTap pairs with triggerOnLongPress: true', () {
      expect(
        () => AdaptivePopupMenuButton.widget<String>(
          items: items,
          onSelected: onSelected,
          triggerOnLongPress: true,
          onTap: () {},
          child: const SizedBox(),
        ),
        returnsNormally,
      );
    });

    test('does not throw when onTap is null', () {
      expect(
        () => AdaptivePopupMenuButton.widget<String>(
          items: items,
          onSelected: onSelected,
          child: const SizedBox(),
        ),
        returnsNormally,
      );
    });
  });

  group('AdaptivePopupMenuButton onOpened/onClosed', () {
    // A host test takes the iOS <26 path (an action sheet): PlatformInfo reads
    // the real OS. The iOS 26 native menu sends the same events over its
    // channel ("menuOpened", "menuClosed").
    const items = <AdaptivePopupMenuEntry>[
      AdaptivePopupMenuItem<String>(label: 'One', value: 'one'),
      AdaptivePopupMenuItem<String>(label: 'Two', value: 'two'),
    ];

    Future<List<String>> pumpButton(WidgetTester tester) async {
      final events = <String>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: AdaptivePopupMenuButton.text<String>(
              label: 'Menu',
              items: items,
              onSelected: (index, entry) => events.add('selected $index'),
              onOpened: () => events.add('opened'),
              onClosed: () => events.add('closed'),
            ),
          ),
        ),
      );
      return events;
    }

    testWidgets('report a cancelled menu', (tester) async {
      final events = await pumpButton(tester);

      await tester.tap(find.text('Menu'));
      await tester.pumpAndSettle();
      expect(events, ['opened']);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(events, ['opened', 'closed']);
    });

    testWidgets('report the close after the pick, as UIKit does', (
      tester,
    ) async {
      final events = await pumpButton(tester);

      await tester.tap(find.text('Menu'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Two'));
      await tester.pumpAndSettle();

      expect(events, ['opened', 'selected 1', 'closed']);
    });
  });

  // NOTE: the Material destructive-color fix (colorScheme.error) is intentionally
  // NOT covered here. That path lives in the private _MaterialPopupMenuButton and is
  // only selected when PlatformInfo.isAndroid — which reads the real host OS via
  // dart:io (ignores debugDefaultTargetPlatformOverride), so it's unreachable in a
  // host widget test. The color change is covered by code review + CHANGELOG.
}
