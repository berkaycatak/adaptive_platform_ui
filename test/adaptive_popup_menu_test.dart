import 'package:flutter/widgets.dart';
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

  // NOTE: the Material destructive-color fix (colorScheme.error) is intentionally
  // NOT covered here. That path lives in the private _MaterialPopupMenuButton and is
  // only selected when PlatformInfo.isAndroid — which reads the real host OS via
  // dart:io (ignores debugDefaultTargetPlatformOverride), so it's unreachable in a
  // host widget test. The color change is covered by code review + CHANGELOG.
}
