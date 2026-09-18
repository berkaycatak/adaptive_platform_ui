import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:adaptive_platform_ui/src/toolbar/duo_vertical_bar.dart';
import 'package:adaptive_platform_ui/src/toolbar/hosted_duo_bar.dart';
import 'package:adaptive_platform_ui/src/toolbar/toolbar_chrome_scope.dart';
import 'package:flutter/cupertino.dart' show CupertinoPageRoute;
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

/// The fixed chrome. It layers one [DuoVerticalBar] per page involved in a
/// transition, so position is asserted on the chrome and content inside it.
Finder get bar => find.byType(HostedDuoBar);
Finder inBar(Finder finder) => find.descendant(of: bar, matching: finder);

/// Opacity of the page layer (or shared back layer) [finder] is drawn in.
double opacityOf(WidgetTester tester, Finder finder) => tester
    .widget<FadeTransition>(
      find.ancestor(
        of: inBar(finder),
        // Layers are keyed; the buttons' own press feedback fades are not.
        matching: find.byWidgetPredicate(
          (w) => w is FadeTransition && w.key != null,
        ),
      ),
    )
    .opacity
    .value;

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

    // Mid-transition the chrome has not moved, and it is handing over from
    // the outgoing page's controls to the incoming page's.
    expect(bar, findsOneWidget);
    expect(tester.getRect(bar), barRect);
    expect(opacityOf(tester, find.byIcon(Icons.add)), lessThan(1));
    expect(opacityOf(tester, find.byIcon(Icons.share)), lessThan(1));

    await tester.pumpAndSettle();
    expect(tester.getRect(bar), barRect);
    expect(inBar(find.byIcon(Icons.add)), findsNothing);
    expect(opacityOf(tester, find.byIcon(Icons.share)), 1);
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

  group('item swap follows the route transition', () {
    testWidgets('push: driven by the incoming route, not by a timer', (
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

      // A deliberately slow route: a fixed-duration swap would be long over.
      final route = PageRouteBuilder<void>(
        transitionDuration: const Duration(seconds: 4),
        reverseTransitionDuration: const Duration(seconds: 4),
        pageBuilder: (_, _, _) => page('Detail', action: Icons.share),
      );
      nav.currentState!.push(route);
      await tester.pump();
      await tester.pump();

      await tester.pump(const Duration(seconds: 1));
      expect(route.animation!.value, closeTo(0.25, 0.05));
      expect(opacityOf(tester, find.byIcon(Icons.add)), inExclusiveRange(0, 1));
      expect(opacityOf(tester, find.byIcon(Icons.share)), 0);

      await tester.pump(const Duration(seconds: 2));
      expect(
        opacityOf(tester, find.byIcon(Icons.share)),
        inExclusiveRange(0, 1),
      );

      await tester.pumpAndSettle();
      expect(opacityOf(tester, find.byIcon(Icons.share)), 1);
      expect(inBar(find.byIcon(Icons.add)), findsNothing);

      // Pop: the same route drives it in reverse.
      nav.currentState!.pop();
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(
        opacityOf(tester, find.byIcon(Icons.share)),
        inExclusiveRange(0, 1),
      );
      await tester.pump(const Duration(seconds: 2));
      expect(opacityOf(tester, find.byIcon(Icons.add)), inExclusiveRange(0, 1));

      await tester.pumpAndSettle();
      expect(opacityOf(tester, find.byIcon(Icons.add)), 1);
      expect(inBar(find.byIcon(Icons.share)), findsNothing);
    });

    testWidgets('a back button both pages show stays put', (tester) async {
      useDuoLandscape(tester);
      final nav = GlobalKey<NavigatorState>();
      await tester.pumpWidget(hostedApp(navigatorKey: nav, home: page('A')));
      await tester.pump();
      nav.currentState!.push(
        MaterialPageRoute<void>(builder: (_) => page('B', action: Icons.add)),
      );
      await tester.pumpAndSettle();
      final backRect = tester.getRect(inBar(find.byType(AdaptiveButton)));

      nav.currentState!.push(
        MaterialPageRoute<void>(builder: (_) => page('C', action: Icons.share)),
      );
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));

      expect(inBar(find.byType(AdaptiveButton)), findsOneWidget);
      expect(opacityOf(tester, find.byType(AdaptiveButton)), 1);
      expect(tester.getRect(inBar(find.byType(AdaptiveButton))), backRect);
      expect(opacityOf(tester, find.byIcon(Icons.add)), lessThan(1));
      await tester.pumpAndSettle();
    });

    testWidgets('a back swipe is followed under the finger and can cancel', (
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
      nav.currentState!.push(
        CupertinoPageRoute<void>(
          builder: (_) => page('Detail', action: Icons.share),
        ),
      );
      await tester.pumpAndSettle();

      // Drag from the leading edge, 70% of the way across.
      final gesture = await tester.startGesture(const Offset(4, 300));
      await gesture.moveBy(const Offset(40, 0));
      await gesture.moveBy(Offset(duoLandscape.width * 0.7, 0));
      await tester.pump();
      expect(nav.currentState!.userGestureInProgress, isTrue);
      expect(find.text('body:Detail'), findsOneWidget);
      expect(opacityOf(tester, find.byIcon(Icons.share)), lessThan(1));
      expect(opacityOf(tester, find.byIcon(Icons.add)), greaterThan(0));

      // Drag back towards the start and let go: cancelled, Detail stays.
      await gesture.moveBy(Offset(-duoLandscape.width * 0.65, 0));
      await gesture.up();
      await tester.pumpAndSettle();
      expect(find.text('body:Detail'), findsOneWidget);
      expect(opacityOf(tester, find.byIcon(Icons.share)), 1);
      expect(inBar(find.byIcon(Icons.add)), findsNothing);

      // A full swipe pops and hands the chrome back.
      final swipe = await tester.startGesture(const Offset(4, 300));
      await swipe.moveBy(const Offset(40, 0));
      await swipe.moveBy(Offset(duoLandscape.width * 0.8, 0));
      await swipe.up();
      await tester.pumpAndSettle();
      expect(find.text('body:Detail'), findsNothing);
      expect(opacityOf(tester, find.byIcon(Icons.add)), 1);
      expect(inBar(find.byIcon(Icons.share)), findsNothing);
    });

    testWidgets('a tab switch has no route to follow and crossfades briefly', (
      tester,
    ) async {
      useDuoLandscape(tester);
      final index = ValueNotifier<int>(0);
      Widget tab(String title, IconData icon) => Navigator(
        onGenerateRoute: (_) =>
            MaterialPageRoute<void>(builder: (_) => page(title, action: icon)),
      );
      await tester.pumpWidget(
        hostedApp(
          home: AdaptiveScaffold(
            body: ValueListenableBuilder<int>(
              valueListenable: index,
              builder: (_, value, _) => IndexedStack(
                index: value,
                children: [tab('Home', Icons.add), tab('Info', Icons.share)],
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(opacityOf(tester, find.byIcon(Icons.add)), 1);

      index.value = 1;
      await tester.pump();
      await tester.pump();
      await tester.pump(kToolbarItemSwapDuration ~/ 2);
      expect(opacityOf(tester, find.byIcon(Icons.share)), lessThan(1));

      await tester.pump(kToolbarItemSwapDuration);
      await tester.pump();
      expect(opacityOf(tester, find.byIcon(Icons.share)), 1);
      expect(inBar(find.byIcon(Icons.add)), findsNothing);
    });
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
