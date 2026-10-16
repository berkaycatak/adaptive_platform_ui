import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:adaptive_platform_ui/src/toolbar/toolbar_blend.dart';
import 'package:adaptive_platform_ui/src/toolbar/toolbar_chrome_scope.dart';
import 'package:adaptive_platform_ui/src/widgets/detent_sheet.dart'
    show SheetGrabber;

const _contentKey = ValueKey('sheet-content');

/// An app whose button runs [open] and stores what the sheet returned.
Widget _app(
  Future<Object?> Function(BuildContext context) open, {
  void Function(Object? result)? onResult,
}) {
  return MaterialApp(
    home: Scaffold(
      body: Builder(
        builder: (context) => Center(
          child: ElevatedButton(
            onPressed: () async {
              final result = await open(context);
              onResult?.call(result);
            },
            child: const Text('Open'),
          ),
        ),
      ),
    ),
  );
}

Widget _content(BuildContext context) => SizedBox.expand(
  key: _contentKey,
  child: Center(
    child: TextButton(
      onPressed: () => Navigator.of(context).pop('picked'),
      child: const Text('Pick'),
    ),
  ),
);

Future<void> _open(WidgetTester tester) async {
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
}

void main() {
  group('AdaptiveSheetDetent', () {
    test('medium and large are half and full height', () {
      expect(AdaptiveSheetDetent.medium.fraction, 0.5);
      expect(AdaptiveSheetDetent.large.fraction, 1.0);
      expect(
        AdaptiveSheetDetent.medium,
        const AdaptiveSheetDetent.fraction(0.5),
      );
    });

    test('rejects fractions outside (0, 1]', () {
      expect(() => AdaptiveSheetDetent.fraction(0), throwsAssertionError);
      expect(() => AdaptiveSheetDetent.fraction(1.2), throwsAssertionError);
    });
  });

  // Tests run on the host, so AdaptiveBottomSheet.show takes the Material
  // path; the iOS sheet is tested through its route below.
  group('AdaptiveBottomSheet (Material)', () {
    testWidgets('shows the contents and returns the popped value', (
      tester,
    ) async {
      Object? result;
      await tester.pumpWidget(
        _app(
          (context) => AdaptiveBottomSheet.show<String>(
            context: context,
            builder: _content,
          ),
          onResult: (value) => result = value,
        ),
      );
      await _open(tester);

      expect(find.byKey(_contentKey), findsOneWidget);
      await tester.tap(find.text('Pick'));
      await tester.pumpAndSettle();

      expect(find.byKey(_contentKey), findsNothing);
      expect(result, 'picked');
    });

    testWidgets('opens at the smallest detent', (tester) async {
      await tester.pumpWidget(
        _app(
          (context) => AdaptiveBottomSheet.show<void>(
            context: context,
            detents: const [
              AdaptiveSheetDetent.large,
              AdaptiveSheetDetent.medium,
            ],
            showDragHandle: false,
            builder: _content,
          ),
        ),
      );
      await _open(tester);

      final screen =
          tester.view.physicalSize.height / tester.view.devicePixelRatio;
      final height = tester.getSize(find.byKey(_contentKey)).height;
      expect(height, moreOrLessEquals(screen / 2, epsilon: 1));
    });

    testWidgets('opens at initialDetent', (tester) async {
      await tester.pumpWidget(
        _app(
          (context) => AdaptiveBottomSheet.show<void>(
            context: context,
            detents: const [
              AdaptiveSheetDetent.medium,
              AdaptiveSheetDetent.large,
            ],
            initialDetent: AdaptiveSheetDetent.large,
            showDragHandle: false,
            builder: _content,
          ),
        ),
      );
      await _open(tester);

      final screen =
          tester.view.physicalSize.height / tester.view.devicePixelRatio;
      final height = tester.getSize(find.byKey(_contentKey)).height;
      expect(height, moreOrLessEquals(screen, epsilon: 1));
    });

    testWidgets('dragging the handle up snaps to the next detent', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          (context) => AdaptiveBottomSheet.show<void>(
            context: context,
            detents: const [
              AdaptiveSheetDetent.medium,
              AdaptiveSheetDetent.large,
            ],
            builder: _content,
          ),
        ),
      );
      await _open(tester);
      final top = tester.getTopLeft(find.byKey(_contentKey)).dy;

      await tester.dragFrom(Offset(400, top - 20), const Offset(0, -150));
      await tester.pumpAndSettle();

      // At full height the handle is at the top of the screen.
      expect(tester.getTopLeft(find.byKey(_contentKey)).dy, lessThan(100));
    });

    testWidgets('dragging down past the smallest detent dismisses it', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          (context) => AdaptiveBottomSheet.show<void>(
            context: context,
            detents: const [AdaptiveSheetDetent.medium],
            builder: _content,
          ),
        ),
      );
      await _open(tester);
      final top = tester.getTopLeft(find.byKey(_contentKey)).dy;

      await tester.dragFrom(Offset(400, top - 20), const Offset(0, 250));
      await tester.pumpAndSettle();

      expect(find.byKey(_contentKey), findsNothing);
    });

    testWidgets('a non-dismissible sheet stays on drag and barrier tap', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          (context) => AdaptiveBottomSheet.show<void>(
            context: context,
            detents: const [AdaptiveSheetDetent.medium],
            isDismissible: false,
            builder: _content,
          ),
        ),
      );
      await _open(tester);
      final top = tester.getTopLeft(find.byKey(_contentKey)).dy;

      await tester.dragFrom(Offset(400, top - 20), const Offset(0, 250));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(20, 20));
      await tester.pumpAndSettle();

      expect(find.byKey(_contentKey), findsOneWidget);
    });

    testWidgets('tapping the barrier dismisses it', (tester) async {
      await tester.pumpWidget(
        _app(
          (context) => AdaptiveBottomSheet.show<void>(
            context: context,
            detents: const [AdaptiveSheetDetent.medium],
            builder: _content,
          ),
        ),
      );
      await _open(tester);

      await tester.tapAt(const Offset(20, 20));
      await tester.pumpAndSettle();

      expect(find.byKey(_contentKey), findsNothing);
    });
  });

  group('IOS26BottomSheetRoute', () {
    Future<Object?> push(
      BuildContext context, {
      List<AdaptiveSheetDetent> detents = const [AdaptiveSheetDetent.medium],
      AdaptiveSheetDetent? initialDetent,
      bool isDismissible = true,
      bool liquidGlass = true,
    }) {
      return Navigator.of(context).push(
        IOS26BottomSheetRoute<String>(
          builder: _content,
          detents: detents,
          initialDetent: initialDetent,
          isDismissible: isDismissible,
          liquidGlass: liquidGlass,
        ),
      );
    }

    testWidgets('shows the contents with a grabber and returns the value', (
      tester,
    ) async {
      Object? result;
      await tester.pumpWidget(_app(push, onResult: (value) => result = value));
      await _open(tester);

      expect(find.byKey(_contentKey), findsOneWidget);
      expect(find.byType(SheetGrabber), findsOneWidget);

      await tester.tap(find.text('Pick'));
      await tester.pumpAndSettle();
      expect(result, 'picked');
    });

    testWidgets('floats off the screen edges below full height', (
      tester,
    ) async {
      await tester.pumpWidget(_app(push));
      await _open(tester);

      final rect = tester.getRect(find.byKey(_contentKey));
      final screen = tester.view.physicalSize / tester.view.devicePixelRatio;
      expect(rect.left, 8);
      expect(rect.right, screen.width - 8);
      expect(rect.bottom, screen.height - 8);
    });

    testWidgets('meets the screen edges at full height', (tester) async {
      await tester.pumpWidget(
        _app(
          (context) => push(
            context,
            detents: const [
              AdaptiveSheetDetent.medium,
              AdaptiveSheetDetent.large,
            ],
            initialDetent: AdaptiveSheetDetent.large,
          ),
        ),
      );
      await _open(tester);

      final rect = tester.getRect(find.byKey(_contentKey));
      final screen = tester.view.physicalSize / tester.view.devicePixelRatio;
      expect(rect.left, moreOrLessEquals(0));
      expect(rect.bottom, moreOrLessEquals(screen.height));
    });

    testWidgets('the pre-iOS 26 sheet is edge to edge at every detent', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app((context) => push(context, liquidGlass: false)),
      );
      await _open(tester);

      final rect = tester.getRect(find.byKey(_contentKey));
      expect(rect.left, moreOrLessEquals(0));
    });

    testWidgets('dragging the grabber down dismisses it', (tester) async {
      await tester.pumpWidget(_app(push));
      await _open(tester);

      await tester.drag(find.byType(SheetGrabber), const Offset(0, 300));
      await tester.pumpAndSettle();

      expect(find.byKey(_contentKey), findsNothing);
    });

    testWidgets('a non-dismissible sheet ignores the barrier and drags', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app((context) => push(context, isDismissible: false)),
      );
      await _open(tester);

      await tester.drag(find.byType(SheetGrabber), const Offset(0, 300));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(20, 20));
      await tester.pumpAndSettle();

      expect(find.byKey(_contentKey), findsOneWidget);
    });
  });

  // The fixed toolbar is drawn above every route, so a sheet must tell the
  // host to fade it out as the sheet rises over it.
  group('toolbar cover', () {
    Widget hostApp(
      List<double> reports,
      Future<Object?> Function(BuildContext context) open,
    ) {
      return MaterialApp(
        builder: (context, child) => ToolbarChromeScope(
          hostsToolbar: true,
          hostsDuoControls: false,
          onSheetCover: reports.add,
          child: child!,
        ),
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                onPressed: () => open(context),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
    }

    Future<Object?> push(
      BuildContext context,
      AdaptiveSheetDetent initialDetent,
    ) {
      return Navigator.of(context).push(
        IOS26BottomSheetRoute<String>(
          builder: _content,
          detents: const [
            AdaptiveSheetDetent.medium,
            AdaptiveSheetDetent.large,
          ],
          initialDetent: initialDetent,
        ),
      );
    }

    testWidgets('a half-height sheet leaves the toolbar alone', (tester) async {
      final reports = <double>[];
      await tester.pumpWidget(
        hostApp(reports, (c) => push(c, AdaptiveSheetDetent.medium)),
      );
      await _open(tester);

      expect(reports, isNotEmpty);
      expect(reports.last, 0);
    });

    testWidgets('a full-height sheet covers the toolbar until it closes', (
      tester,
    ) async {
      final reports = <double>[];
      await tester.pumpWidget(
        hostApp(reports, (c) => push(c, AdaptiveSheetDetent.large)),
      );
      await _open(tester);
      expect(reports.last, 1);

      await tester.tap(find.text('Pick'));
      await tester.pumpAndSettle();
      expect(reports.last, 0);
    });

    testWidgets('the blend fades the chrome out under a sheet', (tester) async {
      final blend = ToolbarBlend(registry: ToolbarRegistry(), vsync: tester);
      addTearDown(blend.dispose);
      expect(blend.chromeOpacity.value, 1);

      blend.setSheetCover(1);
      expect(blend.chromeOpacity.value, 0);

      blend.setSheetCover(0.5);
      expect(blend.chromeOpacity.value, 0.5);

      blend.setSheetCover(0);
      expect(blend.chromeOpacity.value, 1);
    });
  });
}
