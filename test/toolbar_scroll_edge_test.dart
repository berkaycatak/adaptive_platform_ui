import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:adaptive_platform_ui/src/toolbar/toolbar_backdrop.dart';
import 'package:flutter/cupertino.dart' show CupertinoPageRoute;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'hosted_top_toolbar_test.dart' show hostedApp, inBar, usePhone;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    PlatformInfo.debugIOS26OrHigher = true;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('adaptive_platform_ui/vertical_bar_edge'),
          (_) async => null,
        );
  });
  tearDown(() => PlatformInfo.debugIOS26OrHigher = null);

  const none = AdaptiveScrollEdgeEffectStyle.none;
  const hard = AdaptiveScrollEdgeEffectStyle.hard;
  const soft = AdaptiveScrollEdgeEffectStyle.soft;
  final backdrop = find.byType(ToolbarBackdrop);
  final hardEdge = find.descendant(
    of: backdrop,
    matching: find.byWidgetPredicate((w) {
      if (w is! DecoratedBox || w.decoration is! BoxDecoration) return false;
      final border = (w.decoration as BoxDecoration).border;
      return border is Border && border.bottom.style == BorderStyle.solid;
    }),
  );

  test('the default is soft and copyWith preserves an explicit style', () {
    const bar = AdaptiveAppBar();
    expect(bar.scrollEdgeEffectStyle, soft);
    final clear = bar.copyWith(scrollEdgeEffectStyle: none);
    expect(clear.copyWith(title: 'Title').scrollEdgeEffectStyle, none);
    expect(
      clear.copyWith(scrollEdgeEffectStyle: hard).scrollEdgeEffectStyle,
      hard,
    );
  });

  final pixelRatios = ValueVariant<int>({2, 3});
  for (final appearance in Brightness.values) {
    testWidgets(
      'hard edge progressively obscures detail in ${appearance.name}',
      (tester) async {
        final scale = pixelRatios.currentValue!;
        tester.view.devicePixelRatio = scale.toDouble();
        addTearDown(tester.view.resetDevicePixelRatio);
        final ink = appearance == Brightness.light
            ? Colors.black
            : Colors.white;
        final paper = appearance == Brightness.light
            ? Colors.white
            : Colors.black;
        const boundary = Key('scrolling detail');
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(brightness: appearance),
            home: Align(
              alignment: Alignment.topLeft,
              child: RepaintBoundary(
                key: boundary,
                child: SizedBox(
                  width: 120,
                  height: 140,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(width: 24, child: ColoredBox(color: ink)),
                          for (var i = 0; i < 16; i++)
                            SizedBox(
                              width: 4,
                              child: ColoredBox(color: i.isEven ? paper : ink),
                            ),
                          Expanded(child: ColoredBox(color: paper)),
                        ],
                      ),
                      const Positioned(
                        left: 0,
                        right: 0,
                        top: 0,
                        height: 106,
                        child: ToolbarBackdrop(style: hard, titleOnly: false),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.runAsync(() async {
          final image = await tester
              .renderObject<RenderRepaintBoundary>(find.byKey(boundary))
              .toImage(pixelRatio: scale.toDouble());
          try {
            final pixels = (await image.toByteData())!;
            int pixel(int x, int y) =>
                pixels.getUint8(4 * (y * image.width + x));
            int level(int x, int y) => pixel(x * scale, y * scale);
            int toneRange(int y) => (level(12, y) - level(108, y)).abs();
            int stripeDetail(int row) =>
                (pixel(46 * scale, row) - pixel(50 * scale, row)).abs();
            int detail(int y) => stripeDetail(y * scale);
            // The solid fields measure tint. Normalizing the fine stripes by
            // that contrast measures the blur independently of the tint.
            expect(toneRange(60), inInclusiveRange(45, 57));
            expect(detail(60), greaterThan(4));
            expect(toneRange(108), greaterThan(toneRange(60) + 12));
            expect(toneRange(115), greaterThan(toneRange(108)));
            // Two points above the separator, less of the bright page shows
            // through in dark mode. The title contrast is checked above.
            final expectedLowerContrast = appearance == Brightness.dark
                ? 137
                : 158;
            expect(toneRange(116), closeTo(expectedLowerContrast, 5));
            double strokeContrast(int y) => detail(y) / toneRange(y);
            expect(strokeContrast(98), greaterThan(strokeContrast(60) + 0.10));
            expect(strokeContrast(98), lessThan(strokeContrast(115) - 0.15));
            expect(detail(115), greaterThan(40));
            expect(detail(122), 255);
            // Crossing the controls' lower edge (12 pt above the separator)
            // should change neither the tint slope nor the blur abruptly.
            final above = toneRange(106) - toneRange(103);
            final below = toneRange(109) - toneRange(106);
            expect((above - below).abs(), lessThanOrEqualTo(8));
            for (var row = 86 * scale + 1; row < 118 * scale - 1; row++) {
              expect(
                (stripeDetail(row) - stripeDetail(row - 1)).abs(),
                lessThanOrEqualTo(8),
                reason:
                    'Stroke contrast jumped at row $row on a ${scale}x display',
              );
            }
            // The crisp separator occupies only the last physical row.
            final bottom = 118 * scale;
            final line = pixel(12 * scale, bottom - 1);
            if (appearance == Brightness.dark) {
              expect(pixel(108 * scale, bottom - 1), 26);
              expect(
                line,
                inExclusiveRange(pixel(12 * scale, bottom - 2), 255),
              );
            } else {
              expect(pixel(108 * scale, bottom - 1), line);
              expect((line - level(108, 122)).abs(), greaterThan(40));
            }
            expect(pixel(108 * scale, bottom - 2), level(108, 122));
            expect(pixel(12 * scale, bottom), level(12, 122));
          } finally {
            image.dispose();
          }
        });
      },
      variant: pixelRatios,
    );
  }

  testWidgets('the dark hairline blends with the filtered backdrop', (
    tester,
  ) async {
    const key = Key('blank dark surface');
    final scale = pixelRatios.currentValue!;
    tester.view.devicePixelRatio = scale.toDouble();
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: Align(
          alignment: Alignment.topLeft,
          child: RepaintBoundary(
            key: key,
            child: SizedBox(
              width: 160,
              height: 140,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  const Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: ColoredBox(color: Colors.black)),
                      Expanded(child: ColoredBox(color: Color(0xff404040))),
                      Expanded(child: ColoredBox(color: Color(0xff204060))),
                    ],
                  ),
                  const Positioned(
                    left: 0,
                    right: 0,
                    top: 0,
                    height: 106,
                    child: ToolbarBackdrop(style: hard, titleOnly: false),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      final image = await tester
          .renderObject<RenderRepaintBoundary>(find.byKey(key))
          .toImage(pixelRatio: scale.toDouble());
      try {
        final pixels = (await image.toByteData())!;
        int channel(int x, int row, int c) =>
            pixels.getUint8(4 * (row * image.width + x * scale) + c);
        final edge = 118 * scale - 1;
        for (final x in [25, 80, 135]) {
          for (var c = 0; c < 3; c++) {
            final page = channel(x, edge + 2, c);
            // A flat dark field keeps its tone as the blur clears.
            final dimmed = 0.2 * page;
            for (var row = 76 * scale; row < edge; row++) {
              expect(
                channel(x, row, c),
                closeTo(dimmed, 2),
                reason:
                    'A blank surface changed brightness at physical row $row',
              );
            }
            final backdrop = channel(x, edge - 1, c);
            expect(
              channel(x, edge, c),
              closeTo(backdrop + 0.10 * (255 - backdrop), 2),
            );
            expect(channel(x, edge + 1, c), page);
          }
          expect(channel(x, edge - 1, 3), 255);
        }
      } finally {
        image.dispose();
      }
    });
  }, variant: pixelRatios);

  for (final duo in [false, true]) {
    testWidgets('hosted toolbar follows the page scroll position (Duo: $duo)', (
      tester,
    ) async {
      usePhone(tester);
      if (duo) {
        tester.view.physicalSize = const Size(951, 669);
        tester.view.padding = tester.view.viewPadding = const FakeViewPadding(
          right: 84,
          bottom: 34,
        );
      }
      final style = ValueNotifier(none);
      final scroll = ScrollController();
      addTearDown(style.dispose);
      addTearDown(scroll.dispose);
      var taps = 0;
      var listTaps = 0;
      await tester.pumpWidget(
        hostedApp(
          home: ValueListenableBuilder(
            valueListenable: style,
            builder: (_, value, _) => AdaptiveScaffold(
              appBar: AdaptiveAppBar(
                title: 'Title',
                scrollEdgeEffectStyle: value,
                actions: [
                  AdaptiveAppBarAction(
                    icon: Icons.add,
                    onPressed: () => taps++,
                  ),
                ],
              ),
              body: ListView(
                controller: scroll,
                children: [
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => listTaps++,
                    child: const SizedBox(height: 3000),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      // The Material widget-test fallback also builds a page-local app bar.
      final action = find.byIcon(Icons.add).hitTestable();
      expect(backdrop, findsNothing);
      await tester.tap(action);
      scroll.jumpTo(140);
      await tester.pumpAndSettle();
      expect(backdrop, findsNothing);
      await tester.tap(action);
      expect(taps, 2);

      style.value = hard;
      await tester.pumpAndSettle();
      expect(tester.widget<ToolbarBackdrop>(backdrop).style, hard);
      expect(tester.widget<ToolbarBackdrop>(backdrop).titleOnly, duo);
      final band = tester.getRect(backdrop);
      expect(band.bottom, duo ? 70 : 106);
      expect(
        tester.getRect(hardEdge),
        Rect.fromLTRB(band.left, band.top, band.right, band.bottom + 12),
      );
      await tester.tapAt(band.bottomCenter + const Offset(0, 6));
      expect(listTaps, 1);
      expect(scroll.offset, 140);
      scroll.jumpTo(0);
      await tester.pumpAndSettle();
      expect(backdrop, findsNothing);
      scroll.jumpTo(10);
      await tester.pumpAndSettle();
      expect(backdrop, findsOneWidget);
      style.value = soft;
      await tester.pumpAndSettle();
      expect(tester.widget<ToolbarBackdrop>(backdrop).style, soft);
      style.value = none;
      await tester.pumpAndSettle();
      expect(backdrop, findsNothing);
    });
  }

  testWidgets('cancelling a back swipe restores the clear toolbar', (
    tester,
  ) async {
    usePhone(tester);
    final nav = GlobalKey<NavigatorState>();
    final scroll = ScrollController(initialScrollOffset: 80);
    addTearDown(scroll.dispose);
    await tester.pumpWidget(
      hostedApp(
        navigatorKey: nav,
        home: AdaptiveScaffold(
          appBar: const AdaptiveAppBar(
            title: 'List',
            scrollEdgeEffectStyle: hard,
          ),
          body: ListView(
            controller: scroll,
            children: const [SizedBox(height: 3000)],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(backdrop, findsOneWidget);
    nav.currentState!.push(
      CupertinoPageRoute<void>(
        builder: (_) => const AdaptiveScaffold(
          appBar: AdaptiveAppBar(title: 'Detail', scrollEdgeEffectStyle: none),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(backdrop, findsNothing);
    final gesture = await tester.startGesture(const Offset(4, 300));
    await gesture.moveBy(const Offset(45, 0));
    await tester.pump();
    await gesture.moveBy(const Offset(245, 0));
    await tester.pump();
    final fade = find
        .ancestor(of: backdrop, matching: find.byType(FadeTransition))
        .first;
    expect(
      tester.widget<FadeTransition>(fade).opacity.value,
      inExclusiveRange(0, 1),
    );
    await gesture.moveBy(const Offset(-245, 0));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();
    expect(inBar(find.text('Detail')), findsOneWidget);
    expect(backdrop, findsNothing);
    nav.currentState!.pop();
    await tester.pumpAndSettle();
    expect(backdrop, findsOneWidget);
    expect(scroll.offset, 80);
  });

  for (final hosted in [false, true]) {
    testWidgets(
      'style changes preserve the native view and action channel (hosted: $hosted)',
      (tester) async {
        usePhone(tester);
        final messenger = tester.binding.defaultBinaryMessenger;
        final created = <int>[];
        messenger.setMockMethodCallHandler(SystemChannels.platform_views, (
          call,
        ) async {
          final args = call.arguments;
          if (call.method == 'create' &&
              args['viewType'] == 'adaptive_platform_ui/ios26_toolbar') {
            created.add(args['id'] as int);
          }
          return null;
        });
        final style = ValueNotifier(none);
        final scroll = ScrollController();
        addTearDown(style.dispose);
        addTearDown(scroll.dispose);
        var taps = 0;
        final page = ValueListenableBuilder(
          valueListenable: style,
          builder: (_, value, _) {
            final list = ListView(
              controller: scroll,
              children: const [SizedBox(height: 3000)],
            );
            final actions = [
              AdaptiveAppBarAction(iosSymbol: 'plus', onPressed: () => taps++),
            ];
            return AdaptiveScaffold(
              appBar: AdaptiveAppBar(
                title: 'Title',
                actions: actions,
                scrollEdgeEffectStyle: value,
              ),
              body: list,
            );
          },
        );
        await tester.pumpWidget(
          hosted ? hostedApp(home: page) : MaterialApp(home: page),
        );
        await tester.pumpAndSettle();
        final native = find.byWidgetPredicate(
          (w) =>
              w is UiKitView &&
              w.viewType == 'adaptive_platform_ui/ios26_toolbar',
        );
        final view = tester.element(native);
        final controls = tester.getRect(native);
        expect(
          (tester.widget<UiKitView>(native).creationParams
              as Map)['showsGradient'],
          false,
        );
        Future<void> tapAction() => messenger.handlePlatformMessage(
          'adaptive_platform_ui/ios26_toolbar_${created.single}',
          const StandardMethodCodec().encodeMethodCall(
            const MethodCall('onActionTapped', {'index': 0}),
          ),
          (_) {},
        );
        await tapAction();
        scroll.jumpTo(100);
        await tester.pumpAndSettle();
        expect(backdrop, findsNothing);
        await tapAction();
        style.value = hard;
        await tester.pumpAndSettle();
        expect(backdrop, findsOneWidget);
        expect(tester.getRect(native), controls);
        expect(tester.getRect(hardEdge).bottom, controls.bottom + 12);
        expect(tester.element(native), same(view));
        style.value = none;
        await tester.pumpAndSettle();
        expect(backdrop, findsNothing);
        await tapAction();
        expect(taps, 3);
        expect(created, hasLength(1));
      },
      variant: TargetPlatformVariant.only(TargetPlatform.iOS),
    );
  }
}
