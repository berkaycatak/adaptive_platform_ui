import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:adaptive_platform_ui/src/toolbar/duo_vertical_bar.dart';
import 'package:adaptive_platform_ui/src/toolbar/toolbar_chrome_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foldable/foldable.dart';

/// Geometry measured on the iPhone Duo inner display (iOS 27.1 simulator).
const Size duoLandscape = Size(951, 669);

FoldableData duoInnerDisplay() => FoldableData(
  capabilities: FoldableData.unsupported.capabilities,
  status: FoldableData.unsupported.status,
  angleDegrees: FoldableData.unsupported.angleDegrees,
  regions: const [
    ReservedRegion(
      kind: ReservedRegionKind.occlusion,
      bounds: Rect.fromLTRB(867, 0, 951, 120),
      isActive: true,
    ),
  ],
  displayFeatures: const [],
  horizontalSizeClass: SizeClass.regular,
  verticalSizeClass: SizeClass.regular,
);

Widget page(String title, {IconData? action, VoidCallback? onAction}) =>
    AdaptiveScaffold(
      appBar: AdaptiveAppBar(
        title: title,
        useNativeToolbar: true,
        actions: [
          if (action != null)
            AdaptiveAppBarAction(icon: action, onPressed: onAction ?? () {}),
        ],
      ),
      body: Center(child: Text('body:$title')),
    );

Widget hostedApp({
  required Widget home,
  GlobalKey<NavigatorState>? navigatorKey,
}) => MaterialApp(
  navigatorKey: navigatorKey,
  builder: (context, child) =>
      AdaptiveToolbarHost(debugFold: duoInnerDisplay(), child: child!),
  home: home,
);

void useDuoLandscape(WidgetTester tester) {
  tester.view.physicalSize = duoLandscape;
  tester.view.devicePixelRatio = 1;
  tester.view.padding = const FakeViewPadding(right: 84, bottom: 34);
  addTearDown(tester.view.reset);
}

Finder get bar => find.byType(DuoVerticalBar);
Finder inBar(Finder finder) => find.descendant(of: bar, matching: finder);

void main() {
  testWidgets('one fixed bar shows the controls of the page in front', (
    tester,
  ) async {
    useDuoLandscape(tester);
    final nav = GlobalKey<NavigatorState>();
    var added = 0;
    await tester.pumpWidget(
      hostedApp(
        navigatorKey: nav,
        home: page('Home', action: Icons.add, onAction: () => added++),
      ),
    );
    await tester.pump();

    expect(bar, findsOneWidget);
    expect(inBar(find.byIcon(Icons.add)), findsOneWidget);
    final barRect = tester.getRect(bar);
    expect(barRect.right, duoLandscape.width);

    await tester.tap(inBar(find.byIcon(Icons.add)));
    expect(added, 1);

    nav.currentState!.push(
      MaterialPageRoute<void>(
        builder: (_) => page('Detail', action: Icons.share),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Mid-transition: still exactly one bar, in exactly the same place, and
    // it already belongs to the incoming page alone.
    expect(bar, findsOneWidget);
    expect(tester.getRect(bar), barRect);
    expect(inBar(find.byIcon(Icons.share)), findsOneWidget);
    expect(inBar(find.byIcon(Icons.add)), findsNothing);

    await tester.pumpAndSettle();
    expect(tester.getRect(bar), barRect);
  });

  testWidgets('back appears for a pushed page and pops it', (tester) async {
    useDuoLandscape(tester);
    final nav = GlobalKey<NavigatorState>();
    await tester.pumpWidget(hostedApp(navigatorKey: nav, home: page('Home')));
    await tester.pump();
    expect(inBar(find.byType(AdaptiveButton)), findsNothing);

    nav.currentState!.push(
      MaterialPageRoute<void>(builder: (_) => page('Detail')),
    );
    await tester.pumpAndSettle();
    expect(inBar(find.byType(AdaptiveButton)), findsOneWidget);

    await tester.tap(inBar(find.byType(AdaptiveButton)));
    await tester.pumpAndSettle();

    expect(find.text('body:Detail'), findsNothing);
    expect(find.text('body:Home'), findsOneWidget);
    expect(inBar(find.byType(AdaptiveButton)), findsNothing);
  });

  testWidgets('back pops the nested navigator that owns the page', (
    tester,
  ) async {
    useDuoLandscape(tester);
    final tabNav = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      hostedApp(
        home: AdaptiveScaffold(
          body: Navigator(
            key: tabNav,
            onGenerateRoute: (_) =>
                MaterialPageRoute<void>(builder: (_) => page('Tab root')),
          ),
        ),
      ),
    );
    await tester.pump();

    tabNav.currentState!.push(
      MaterialPageRoute<void>(builder: (_) => page('Tab detail')),
    );
    await tester.pumpAndSettle();

    await tester.tap(inBar(find.byType(AdaptiveButton)));
    await tester.pumpAndSettle();
    expect(find.text('body:Tab root'), findsOneWidget);
    expect(find.text('body:Tab detail'), findsNothing);
  });

  testWidgets('a dialog on top empties the bar without moving it', (
    tester,
  ) async {
    useDuoLandscape(tester);
    final nav = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      hostedApp(
        navigatorKey: nav,
        home: page('Home', action: Icons.add),
      ),
    );
    await tester.pump();

    showDialog<void>(
      context: nav.currentContext!,
      builder: (_) => const AlertDialog(title: Text('Sure?')),
    );
    await tester.pumpAndSettle();
    expect(inBar(find.byIcon(Icons.add)), findsNothing);

    nav.currentState!.pop();
    await tester.pumpAndSettle();
    expect(inBar(find.byIcon(Icons.add)), findsOneWidget);
  });

  testWidgets('a custom leading widget replaces the automatic back button', (
    tester,
  ) async {
    useDuoLandscape(tester);
    final nav = GlobalKey<NavigatorState>();
    await tester.pumpWidget(hostedApp(navigatorKey: nav, home: page('Home')));
    await tester.pump();

    nav.currentState!.push(
      MaterialPageRoute<void>(
        builder: (_) => const AdaptiveScaffold(
          appBar: AdaptiveAppBar(
            title: 'Custom',
            useNativeToolbar: true,
            leading: Icon(Icons.close),
          ),
          body: SizedBox.shrink(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(inBar(find.byIcon(Icons.close)), findsOneWidget);
    expect(inBar(find.byType(AdaptiveButton)), findsNothing);
  });

  testWidgets('pages learn from the host that it draws their controls', (
    tester,
  ) async {
    useDuoLandscape(tester);
    bool? hosted;
    await tester.pumpWidget(
      hostedApp(
        home: Builder(
          builder: (context) {
            hosted = ToolbarChromeScope.maybeOf(context)?.hostsDuoControls;
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    expect(hosted, isTrue);

    // Portrait keeps horizontal bars, so the host hands the controls back.
    tester.view.physicalSize = duoLandscape.flipped;
    await tester.pump();
    expect(hosted, isFalse);
    expect(bar, findsNothing);
  });

  testWidgets('outside the Duo pose the host draws nothing', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => AdaptiveToolbarHost(child: child!),
        home: page('Home', action: Icons.add),
      ),
    );
    await tester.pump();
    expect(bar, findsNothing);
    expect(tester.takeException(), isNull);
  });
}
