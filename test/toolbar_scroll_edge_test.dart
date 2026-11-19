import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:adaptive_platform_ui/src/toolbar/toolbar_backdrop.dart';
import 'package:flutter/cupertino.dart'
    show
        CupertinoColors,
        CupertinoDynamicColor,
        CupertinoPageRoute,
        CupertinoTheme,
        CupertinoThemeData;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'hosted_top_toolbar_test.dart' show hostedApp, inBar, usePhone;

typedef _ReadPixel = int Function(int x, int y, [int channel]);

Future<_ReadPixel> _capturePixels(
  WidgetTester tester,
  Key boundary, {
  int scale = 1,
}) async {
  final readPixel = await tester.runAsync<_ReadPixel>(() async {
    final image = await tester
        .renderObject<RenderRepaintBoundary>(find.byKey(boundary))
        .toImage(pixelRatio: scale.toDouble());
    try {
      final bytes = (await image.toByteData())!;
      final width = image.width;
      return (int x, int y, [int channel = 0]) =>
          bytes.getUint8(4 * (y * width + x) + channel);
    } finally {
      image.dispose();
    }
  });
  return readPixel!;
}

Future<_ReadPixel> _renderStripes(
  WidgetTester tester,
  Brightness appearance,
  AdaptiveScrollEdgeEffectStyle style, {
  required int scale,
  int stripeWidth = 4,
  double barHeight = 106,
}) async {
  final ink = appearance == Brightness.light ? Colors.black : Colors.white;
  final paper = appearance == Brightness.light ? Colors.white : Colors.black;
  const boundary = Key('scrolling detail');
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(brightness: appearance, scaffoldBackgroundColor: paper),
      home: Align(
        alignment: Alignment.topLeft,
        child: RepaintBoundary(
          key: boundary,
          child: SizedBox(
            width: 120,
            height: barHeight + 52,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(width: 24, child: ColoredBox(color: ink)),
                    for (var i = 0; i < 64 ~/ stripeWidth; i++)
                      SizedBox(
                        width: stripeWidth.toDouble(),
                        child: ColoredBox(color: i.isEven ? paper : ink),
                      ),
                    Expanded(child: ColoredBox(color: paper)),
                  ],
                ),
                // A 12-point cap height and 2-point stems approximate a
                // 17-point label without depending on the test runner's font.
                if (style == AdaptiveScrollEdgeEffectStyle.soft)
                  for (final offset in [-22, 4, 32])
                    Positioned(
                      left: 94,
                      top: barHeight + offset - 6,
                      child: Column(
                        children: [
                          ColoredBox(
                            color: ink,
                            child: const SizedBox(width: 10, height: 2),
                          ),
                          ColoredBox(
                            color: ink,
                            child: const SizedBox(width: 2, height: 10),
                          ),
                        ],
                      ),
                    ),
                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  height: barHeight,
                  child: ToolbarBackdrop(style: style, titleOnly: false),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return _capturePixels(tester, boundary, scale: scale);
}

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
      'soft edge gradually blurs fine detail below the controls in ${appearance.name}',
      (tester) async {
        final scale = pixelRatios.currentValue!;
        tester.view.devicePixelRatio = scale.toDouble();
        tester.platformDispatcher.platformBrightnessTestValue = appearance;
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
        // An inline toolbar below the status bar, and a compact horizontal bar.
        for (final height in [106, 44]) {
          final pixel = await _renderStripes(
            tester,
            appearance,
            soft,
            scale: scale,
            stripeWidth: 2,
            barHeight: height.toDouble(),
          );
          int contrast(int x1, int x2, int offset) {
            final row = (height + offset) * scale;
            return (pixel(x1 * scale, row) - pixel(x2 * scale, row)).abs();
          }

          // Normalize out the tint: tint alone leaves this ratio at one.
          double detail(int offset) =>
              contrast(45, 47, offset) / contrast(12, 108, offset);
          expect(detail(-22), lessThan(0.18));
          expect(detail(0), closeTo(0.50, 0.12));
          expect(detail(10), closeTo(0.84, 0.10));
          expect(detail(18), closeTo(1, 0.025));
          // Absolute contrast through the glyph's stem catches a material
          // that blurs thin stripes but still leaves list labels readable.
          double stemContrast(int offset) => contrast(99, 115, offset) / 255;
          expect(stemContrast(-22), inExclusiveRange(0.03, 0.20));
          expect(stemContrast(4), inExclusiveRange(0.38, 0.72));
          expect(stemContrast(32), greaterThan(0.93));
          expect(contrast(12, 108, 22), lessThan(255));
          expect(contrast(12, 108, 45), 255);
        }
      },
      variant: pixelRatios,
    );

    testWidgets(
      'hard edge progressively obscures detail in ${appearance.name}',
      (tester) async {
        final scale = pixelRatios.currentValue!;
        tester.view.devicePixelRatio = scale.toDouble();
        addTearDown(tester.view.resetDevicePixelRatio);
        final pixel = await _renderStripes(
          tester,
          appearance,
          hard,
          scale: scale,
        );
        int level(int x, int y) => pixel(x * scale, y * scale);
        int toneRange(int y) => (level(12, y) - level(108, y)).abs();
        int stripeDetail(int row) =>
            (pixel(46 * scale, row) - pixel(50 * scale, row)).abs();
        int detail(int y) => stripeDetail(y * scale);
        // The solid fields measure tint. Normalizing the fine stripes by
        // that contrast measures the blur independently of the tint.
        expect(toneRange(60), closeTo(25.5, 2));
        expect(detail(60), greaterThan(1));
        expect(toneRange(108), greaterThan(toneRange(60) + 12));
        expect(toneRange(115), greaterThan(toneRange(108)));
        // Two points above the separator, less of the bright page shows
        // through in dark mode. The title contrast is checked above.
        final expectedLowerContrast = appearance == Brightness.dark ? 140 : 162;
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
            reason: 'Stroke contrast jumped at row $row on a ${scale}x display',
          );
        }
        // The crisp separator occupies only the last physical row.
        final bottom = 118 * scale;
        final line = pixel(12 * scale, bottom - 1);
        if (appearance == Brightness.dark) {
          expect(pixel(108 * scale, bottom - 1), 26);
          expect(line, inExclusiveRange(pixel(12 * scale, bottom - 2), 255));
        } else {
          expect(pixel(108 * scale, bottom - 1), line);
          expect((line - level(108, 122)).abs(), greaterThan(40));
        }
        expect(pixel(108 * scale, bottom - 2), level(108, 122));
        expect(pixel(12 * scale, bottom), level(12, 122));
      },
      variant: pixelRatios,
    );
  }

  testWidgets('the dark hairline blends with the filtered backdrop', (
    tester,
  ) async {
    const key = Key('blank dark surface');
    const surface = Color(0xff403060);
    final scale = pixelRatios.currentValue!;
    tester.view.devicePixelRatio = scale.toDouble();
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark().copyWith(scaffoldBackgroundColor: surface),
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
                      Expanded(child: ColoredBox(color: surface)),
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
    final pixel = await _capturePixels(tester, key, scale: scale);
    int channel(int x, int row, int c) => pixel(x * scale, row, c);
    final edge = 118 * scale - 1;
    for (final x in [25, 80, 135]) {
      for (var c = 0; c < 3; c++) {
        final page = channel(x, edge + 2, c);
        final surfaceChannel = channel(25, edge + 2, c);
        final title = channel(x, 60 * scale, c);
        expect(title, closeTo(0.90 * surfaceChannel + 0.10 * page, 2));
        if (x == 25) {
          // A patch of bare scaffold keeps its color through the falloff.
          for (var row = 76 * scale; row < edge; row++) {
            expect(channel(x, row, c), closeTo(surfaceChannel, 2));
          }
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
      await tester.tapAt(band.bottomCenter + const Offset(0, 10));
      await tester.tapAt(band.bottomCenter + const Offset(0, 32));
      expect(listTaps, 3);
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

  final tintedStyles = ValueVariant<AdaptiveScrollEdgeEffectStyle>({
    soft,
    hard,
  });
  testWidgets('a back swipe blends the two scaffold colors', (tester) async {
    usePhone(tester);
    final style = tintedStyles.currentValue!;
    const first = Color(0xff602040);
    const second = Color(0xff204060);
    final nav = GlobalKey<NavigatorState>();
    final rootScroll = ScrollController(initialScrollOffset: 80);
    final detailScroll = ScrollController(initialScrollOffset: 80);
    addTearDown(rootScroll.dispose);
    addTearDown(detailScroll.dispose);
    Widget page(Color surface, ScrollController scroll) => AdaptiveScaffold(
      backgroundColor: surface,
      appBar: AdaptiveAppBar(title: 'Page', scrollEdgeEffectStyle: style),
      body: ListView(
        controller: scroll,
        children: const [SizedBox(height: 3000)],
      ),
    );
    Color? color() {
      final widget = tester.widget<ToolbarBackdrop>(backdrop);
      return style == soft ? widget.softEdgeSurface : widget.hardEdge?.surface;
    }

    await tester.pumpWidget(
      hostedApp(navigatorKey: nav, home: page(first, rootScroll)),
    );
    await tester.pumpAndSettle();
    expect(color(), first);
    final route = CupertinoPageRoute<void>(
      builder: (_) => page(second, detailScroll),
    );
    nav.currentState!.push(route);
    await tester.pumpAndSettle();
    expect(color(), second);
    final gesture = await tester.startGesture(const Offset(4, 300));
    await gesture.moveBy(const Offset(45, 0));
    await tester.pump();
    await gesture.moveBy(const Offset(200, 0));
    await tester.pump();
    final progress = route.animation!.value;
    expect(progress, inExclusiveRange(0, 1));
    expect(color(), Color.lerp(first, second, progress));
    await gesture.moveBy(const Offset(-200, 0));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();
    expect(color(), second);
    nav.currentState!.pop();
    await tester.pumpAndSettle();
    expect(color(), first);
  }, variant: tintedStyles);

  for (final hosted in [false, true]) {
    testWidgets(
      'toolbar edge renders the page surface (hosted: $hosted)',
      (tester) async {
        usePhone(tester);
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform_views,
          (_) async => null,
        );
        const boundary = Key('page surface');
        const content = Color(0xff566376);
        const darkPage = Color(0xff602040);
        const lightPage = Color(0xffd6e8fc);
        const dynamicSurface = CupertinoDynamicColor.withBrightness(
          color: Color(0xffcce0dd),
          darkColor: Color(0xff304650),
        );
        final scroll = ScrollController(initialScrollOffset: 180);
        addTearDown(scroll.dispose);
        Future<void> check(
          CupertinoThemeData theme,
          Color expected, {
          Color? override,
          AdaptiveScrollEdgeEffectStyle style = hard,
        }) async {
          final page = CupertinoTheme(
            data: theme,
            child: AdaptiveScaffold(
              backgroundColor: override,
              appBar: AdaptiveAppBar(
                title: 'Page',
                scrollEdgeEffectStyle: style,
              ),
              body: ListView(
                padding: EdgeInsets.zero,
                controller: scroll,
                children: const [
                  ColoredBox(color: content, child: SizedBox(height: 3000)),
                ],
              ),
            ),
          );
          await tester.pumpWidget(
            RepaintBoundary(
              key: boundary,
              child: hosted ? hostedApp(home: page) : MaterialApp(home: page),
            ),
          );
          await tester.pumpAndSettle();
          expect(backdrop, findsOneWidget);
          final pixel = await _capturePixels(tester, boundary);
          final tint = Color.alphaBlend(
            expected.withValues(
              alpha: expected.a * (style == soft ? 0.87 : 0.90),
            ),
            content,
          );
          for (final (i, value) in [tint.r, tint.g, tint.b].indexed) {
            expect(pixel(290, 60, i), closeTo(value * 255, 2));
          }
          if (style == soft) return;
          final separator = CupertinoColors.opaqueSeparator.color;
          for (final (i, lightChannel) in [
            separator.r,
            separator.g,
            separator.b,
          ].indexed) {
            final filtered = pixel(290, 116, i);
            final lineChannel = theme.brightness == Brightness.dark
                ? filtered + (255 - filtered) * 0.10
                : lightChannel * 255;
            expect(pixel(290, 117, i), closeTo(lineChannel, 6));
          }
        }

        const dark = CupertinoThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: darkPage,
        );
        const light = CupertinoThemeData(
          brightness: Brightness.light,
          scaffoldBackgroundColor: lightPage,
        );
        await check(dark, darkPage);
        await check(dark, dynamicSurface.darkColor, override: dynamicSurface);
        await check(light, dynamicSurface.color, override: dynamicSurface);
        const translucent = Color(0x80604080);
        await check(light, translucent, override: translucent);
        await check(light, Colors.transparent, override: Colors.transparent);
        await check(light, lightPage);
        await check(dark, darkPage, style: soft);
        await check(
          light,
          dynamicSurface.color,
          override: dynamicSurface,
          style: soft,
        );
        await check(
          light,
          Colors.transparent,
          override: Colors.transparent,
          style: soft,
        );
      },
      variant: TargetPlatformVariant.only(TargetPlatform.iOS),
    );

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
