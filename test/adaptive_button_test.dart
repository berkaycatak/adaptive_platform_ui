import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';

void main() {
  group('AdaptiveButton', () {
    testWidgets('creates button with child', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdaptiveButton(
              onPressed: () {},
              child: const Text('Test Button'),
            ),
          ),
        ),
      );

      expect(find.text('Test Button'), findsOneWidget);
    });

    testWidgets('calls onPressed when tapped', (WidgetTester tester) async {
      bool pressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdaptiveButton(
              onPressed: () {
                pressed = true;
              },
              child: const Text('Test Button'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Test Button'));
      await tester.pump();

      expect(pressed, isTrue);
    });

    testWidgets('does not call onPressed when disabled',
        (WidgetTester tester) async {
      bool pressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdaptiveButton(
              onPressed: null, // Disabled
              child: const Text('Test Button'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Test Button'));
      await tester.pump();

      expect(pressed, isFalse);
    });

    testWidgets('renders with different styles', (WidgetTester tester) async {
      for (final style in AdaptiveButtonStyle.values) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AdaptiveButton(
                onPressed: () {},
                style: style,
                child: Text('$style Button'),
              ),
            ),
          ),
        );

        expect(find.text('$style Button'), findsOneWidget);
      }
    });

    testWidgets('renders with different sizes', (WidgetTester tester) async {
      for (final size in AdaptiveButtonSize.values) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AdaptiveButton(
                onPressed: () {},
                size: size,
                child: Text('$size Button'),
              ),
            ),
          ),
        );

        expect(find.text('$size Button'), findsOneWidget);
      }
    });

    testWidgets('respects custom color', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdaptiveButton(
              onPressed: () {},
              color: Colors.red,
              child: const Text('Red Button'),
            ),
          ),
        ),
      );

      expect(find.text('Red Button'), findsOneWidget);
    });

    testWidgets('respects custom padding', (WidgetTester tester) async {
      const customPadding = EdgeInsets.all(32.0);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdaptiveButton(
              onPressed: () {},
              padding: customPadding,
              child: const Text('Padded Button'),
            ),
          ),
        ),
      );

      expect(find.text('Padded Button'), findsOneWidget);
    });
  });

  group('iOS26Button', () {
    testWidgets('creates iOS 26 button', (WidgetTester tester) async {
      await tester.pumpWidget(
        const CupertinoApp(
          home: CupertinoPageScaffold(
            child: iOS26Button(
              onPressed: null,
              child: Text('iOS 26 Button'),
            ),
          ),
        ),
      );

      expect(find.text('iOS 26 Button'), findsOneWidget);
    });

    testWidgets('responds to tap with animation', (WidgetTester tester) async {
      bool pressed = false;

      await tester.pumpWidget(
        CupertinoApp(
          home: CupertinoPageScaffold(
            child: iOS26Button(
              onPressed: () {
                pressed = true;
              },
              child: const Text('iOS 26 Button'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('iOS 26 Button'));
      await tester.pump();

      expect(pressed, isTrue);
    });

    testWidgets('renders all iOS 26 button styles',
        (WidgetTester tester) async {
      for (final style in iOS26ButtonStyle.values) {
        await tester.pumpWidget(
          CupertinoApp(
            home: CupertinoPageScaffold(
              child: iOS26Button(
                onPressed: () {},
                style: style,
                child: Text('$style'),
              ),
            ),
          ),
        );

        expect(find.text('$style'), findsOneWidget);
        await tester.pumpAndSettle();
      }
    });

    testWidgets('renders all iOS 26 button sizes',
        (WidgetTester tester) async {
      for (final size in iOS26ButtonSize.values) {
        await tester.pumpWidget(
          CupertinoApp(
            home: CupertinoPageScaffold(
              child: iOS26Button(
                onPressed: () {},
                size: size,
                child: Text('$size'),
              ),
            ),
          ),
        );

        expect(find.text('$size'), findsOneWidget);
        await tester.pumpAndSettle();
      }
    });
  });
}
