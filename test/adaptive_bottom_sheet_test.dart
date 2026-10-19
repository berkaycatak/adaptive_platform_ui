import 'package:flutter/cupertino.dart'
    show CupertinoColors, CupertinoSheetRoute;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:adaptive_platform_ui/src/toolbar/toolbar_blend.dart';
import 'package:adaptive_platform_ui/src/toolbar/toolbar_chrome_scope.dart';
import 'package:adaptive_platform_ui/src/widgets/detent_sheet.dart'
    show SheetGrabber;

const _contentKey = ValueKey('sheet-content');

Widget _app(
  Future<Object?> Function(BuildContext context) open, {
  void Function(Object? result)? onResult,
  Brightness brightness = Brightness.light,
}) {
  return MaterialApp(
    theme: ThemeData(brightness: brightness),
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

void _pretendIOS(int version) {
  PlatformInfo.debugIsIOSOverride = true;
  PlatformInfo.debugIOSVersionOverride = version;
  addTearDown(() {
    PlatformInfo.debugIsIOSOverride = null;
    PlatformInfo.debugIOSVersionOverride = null;
  });
}

final _grabberBar = find.descendant(
  of: find.byType(SheetGrabber),
  matching: find.byType(Container),
);

ModalRoute<Object?>? _sheetRoute(WidgetTester tester) =>
    ModalRoute.of(tester.element(find.byKey(_contentKey)));

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

    testWidgets('gives scrollableBuilder a controller for its scroll view', (
      tester,
    ) async {
      ScrollController? given;
      await tester.pumpWidget(
        _app(
          (context) => AdaptiveBottomSheet.show<void>(
            context: context,
            scrollableBuilder: (context, controller) {
              given = controller;
              return ListView(
                key: _contentKey,
                controller: controller,
                children: const [Text('Row')],
              );
            },
          ),
        ),
      );
      await _open(tester);

      expect(find.byKey(_contentKey), findsOneWidget);
      expect(given?.hasClients, isTrue);
    });

    testWidgets('asks for exactly one of builder and scrollableBuilder', (
      tester,
    ) async {
      await tester.pumpWidget(_app((context) async => null));
      final context = tester.element(find.text('Open'));

      expect(
        () => AdaptiveBottomSheet.show<void>(context: context),
        throwsAssertionError,
      );
      expect(
        () => AdaptiveBottomSheet.show<void>(
          context: context,
          builder: _content,
          scrollableBuilder: (context, controller) => _content(context),
        ),
        throwsAssertionError,
      );
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

  group('AdaptiveBottomSheet (iOS)', () {
    testWidgets('a full-height sheet is the system page sheet', (tester) async {
      _pretendIOS(26);
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

      expect(_sheetRoute(tester), isA<CupertinoSheetRoute<String>>());
      expect(find.byType(SheetGrabber), findsOneWidget);

      await tester.tap(find.text('Pick'));
      await tester.pumpAndSettle();
      expect(find.byKey(_contentKey), findsNothing);
      expect(result, 'picked');
    });

    testWidgets('the page sheet takes backgroundColor and hides the grabber', (
      tester,
    ) async {
      _pretendIOS(18);
      const color = Color(0xFF123456);
      await tester.pumpWidget(
        _app(
          (context) => AdaptiveBottomSheet.show<void>(
            context: context,
            showDragHandle: false,
            backgroundColor: color,
            builder: _content,
          ),
        ),
      );
      await _open(tester);

      expect(_sheetRoute(tester), isA<CupertinoSheetRoute<void>>());
      expect(find.byType(SheetGrabber), findsNothing);
      expect(
        find.ancestor(
          of: find.byKey(_contentKey),
          matching: find.byWidgetPredicate(
            (widget) => widget is ColoredBox && widget.color == color,
          ),
        ),
        findsOneWidget,
      );
    });

    testWidgets('iOS 26 shows other detents as a Liquid Glass sheet', (
      tester,
    ) async {
      _pretendIOS(26);
      await tester.pumpWidget(
        _app(
          (context) => AdaptiveBottomSheet.show<void>(
            context: context,
            detents: const [AdaptiveSheetDetent.medium],
            backgroundColor: const Color(0xFFFFFFFF),
            builder: _content,
          ),
        ),
      );
      await _open(tester);

      final route = _sheetRoute(tester);
      expect(route, isA<IOSBottomSheetRoute<void>>());
      expect((route! as IOSBottomSheetRoute<void>).liquidGlass, isTrue);
      expect(route.barrierLabel, 'Dismiss');
    });

    for (final detent in [
      AdaptiveSheetDetent.large,
      AdaptiveSheetDetent.medium,
    ]) {
      testWidgets('the iOS 18 $detent is elevated in dark mode', (
        tester,
      ) async {
        _pretendIOS(18);
        await tester.pumpWidget(
          _app(
            (context) => AdaptiveBottomSheet.show<void>(
              context: context,
              detents: [detent],
              builder: _content,
            ),
            brightness: Brightness.dark,
          ),
        );
        await _open(tester);

        final elevated = CupertinoColors.systemBackground.darkElevatedColor;
        expect(
          find.ancestor(
            of: find.byKey(_contentKey),
            matching: find.byWidgetPredicate(
              (widget) =>
                  widget is ColoredBox &&
                  widget.color.toARGB32() == elevated.toARGB32(),
            ),
          ),
          findsOneWidget,
        );
      });
    }

    testWidgets('iOS 18 shows other detents as the opaque sheet', (
      tester,
    ) async {
      _pretendIOS(18);
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

      final route = _sheetRoute(tester);
      expect(route, isA<IOSBottomSheetRoute<void>>());
      expect((route! as IOSBottomSheetRoute<void>).liquidGlass, isFalse);
    });
  });

  group('IOSBottomSheetRoute', () {
    Future<Object?> push(
      BuildContext context, {
      List<AdaptiveSheetDetent> detents = const [AdaptiveSheetDetent.medium],
      AdaptiveSheetDetent? initialDetent,
      bool isDismissible = true,
      bool liquidGlass = true,
    }) {
      return Navigator.of(context).push(
        IOSBottomSheetRoute<String>(
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

      await tester.drag(_grabberBar, const Offset(0, 300));
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

      await tester.drag(_grabberBar, const Offset(0, 300));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(20, 20));
      await tester.pumpAndSettle();

      expect(find.byKey(_contentKey), findsOneWidget);
    });

    testWidgets('sits above the keyboard and hides its inset from the '
        'contents', (tester) async {
      tester.view
        ..devicePixelRatio = 1
        ..physicalSize = const Size(400, 800)
        ..padding = const FakeViewPadding(top: 50, bottom: 34)
        ..viewInsets = const FakeViewPadding(bottom: 300);
      addTearDown(tester.view.reset);
      MediaQueryData? seen;
      await tester.pumpWidget(
        _app(
          (context) => Navigator.of(context).push(
            IOSBottomSheetRoute<String>(
              detents: const [AdaptiveSheetDetent.medium],
              builder: (context) {
                seen = MediaQuery.of(context);
                return _content(context);
              },
            ),
          ),
        ),
      );
      await _open(tester);

      expect(seen!.viewInsets.bottom, 0);
      expect(seen!.padding.top, 0);
      expect(tester.getRect(find.byKey(_contentKey)).bottom, 800 - 300 - 8);
    });
  });

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
        IOSBottomSheetRoute<String>(
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

    testWidgets('the iOS page sheet covers the toolbar until it closes', (
      tester,
    ) async {
      _pretendIOS(26);
      final reports = <double>[];
      await tester.pumpWidget(
        hostApp(
          reports,
          (c) => AdaptiveBottomSheet.show<void>(context: c, builder: _content),
        ),
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
