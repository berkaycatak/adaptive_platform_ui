import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';

void main() {
  group('AdaptiveAppBarAction', () {
    test('creates action with iOS symbol', () {
      final action = AdaptiveAppBarAction(
        iosSymbol: 'info.circle',
        onPressed: () {},
      );

      expect(action.iosSymbol, 'info.circle');
      expect(action.androidIcon, isNull);
      expect(action.title, isNull);
    });

    test('creates action with Android icon', () {
      final action = AdaptiveAppBarAction(
        androidIcon: Icons.info,
        onPressed: () {},
      );

      expect(action.androidIcon, Icons.info);
      expect(action.iosSymbol, isNull);
      expect(action.title, isNull);
    });

    test('creates action with title', () {
      final action = AdaptiveAppBarAction(title: 'Info', onPressed: () {});

      expect(action.title, 'Info');
      expect(action.iosSymbol, isNull);
      expect(action.androidIcon, isNull);
    });

    test('creates action with all parameters', () {
      final action = AdaptiveAppBarAction(
        iosSymbol: 'info.circle',
        androidIcon: Icons.info,
        title: 'Info',
        onPressed: () {},
      );

      expect(action.iosSymbol, 'info.circle');
      expect(action.androidIcon, Icons.info);
      expect(action.title, 'Info');
    });

    test('throws assertion error when all parameters are null', () {
      expect(
        () => AdaptiveAppBarAction(onPressed: () {}),
        throwsAssertionError,
      );
    });

    test('calls onPressed when action is pressed', () {
      bool pressed = false;
      final action = AdaptiveAppBarAction(
        title: 'Test',
        onPressed: () {
          pressed = true;
        },
      );

      action.onPressed();
      expect(pressed, isTrue);
    });

    test('equality works correctly', () {
      final action1 = AdaptiveAppBarAction(
        iosSymbol: 'info.circle',
        androidIcon: Icons.info,
        title: 'Info',
        onPressed: () {},
      );

      final action2 = AdaptiveAppBarAction(
        iosSymbol: 'info.circle',
        androidIcon: Icons.info,
        title: 'Info',
        onPressed: () {},
      );

      final action3 = AdaptiveAppBarAction(
        iosSymbol: 'settings',
        androidIcon: Icons.settings,
        title: 'Settings',
        onPressed: () {},
      );

      expect(action1, equals(action2));
      expect(action1, isNot(equals(action3)));
    });

    test('identical instances are equal', () {
      final action = AdaptiveAppBarAction(title: 'Test', onPressed: () {});

      expect(action, equals(action));
    });

    test('hashCode is consistent with equality', () {
      final action1 = AdaptiveAppBarAction(
        iosSymbol: 'info.circle',
        androidIcon: Icons.info,
        title: 'Info',
        onPressed: () {},
      );

      final action2 = AdaptiveAppBarAction(
        iosSymbol: 'info.circle',
        androidIcon: Icons.info,
        title: 'Info',
        onPressed: () {},
      );

      expect(action1.hashCode, equals(action2.hashCode));
    });

    test('different actions have different hash codes', () {
      final action1 = AdaptiveAppBarAction(
        iosSymbol: 'info.circle',
        onPressed: () {},
      );

      final action2 = AdaptiveAppBarAction(
        iosSymbol: 'settings',
        onPressed: () {},
      );

      // Note: Different objects *can* have same hash code, but it's unlikely
      // This test may occasionally fail by chance, but that's acceptable
      expect(action1.hashCode, isNot(equals(action2.hashCode)));
    });

    test('toNativeMap includes iosSymbol when present', () {
      final action = AdaptiveAppBarAction(
        iosSymbol: 'info.circle',
        onPressed: () {},
      );

      final map = action.toNativeMap();

      expect(map['icon'], 'info.circle');
      expect(map.containsKey('title'), isFalse);
    });

    test('toNativeMap includes title when present', () {
      final action = AdaptiveAppBarAction(title: 'Info', onPressed: () {});

      final map = action.toNativeMap();

      expect(map['title'], 'Info');
      expect(map.containsKey('icon'), isFalse);
    });

    test('toNativeMap includes both iosSymbol and title', () {
      final action = AdaptiveAppBarAction(
        iosSymbol: 'info.circle',
        title: 'Info',
        onPressed: () {},
      );

      final map = action.toNativeMap();

      expect(map['icon'], 'info.circle');
      expect(map['title'], 'Info');
    });

    test('toNativeMap excludes androidIcon', () {
      final action = AdaptiveAppBarAction(
        androidIcon: Icons.info,
        iosSymbol: 'info.circle',
        onPressed: () {},
      );

      final map = action.toNativeMap();

      expect(map.containsKey('androidIcon'), isFalse);
      expect(map['icon'], 'info.circle');
    });

    test('toNativeMap returns empty map when only androidIcon is provided', () {
      final action = AdaptiveAppBarAction(
        androidIcon: Icons.info,
        onPressed: () {},
      );

      final map = action.toNativeMap();

      expect(map.isEmpty, isTrue);
    });

    test('equality ignores onPressed callback', () {
      final action1 = AdaptiveAppBarAction(title: 'Test', onPressed: () {});

      final action2 = AdaptiveAppBarAction(
        title: 'Test',
        onPressed: () {}, // Different callback instance
      );

      // Equality should only check iosSymbol, androidIcon, and title
      expect(action1, equals(action2));
    });
  });
}
