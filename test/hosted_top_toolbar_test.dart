import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:adaptive_platform_ui/src/toolbar/hosted_duo_bar.dart';
import 'package:adaptive_platform_ui/src/toolbar/hosted_top_toolbar.dart';
import 'package:adaptive_platform_ui/src/toolbar/toolbar_chrome_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foldable/foldable.dart';

/// Forces the chrome on (there is no iOS 26 in a widget test); the insets
/// stay those of an ordinary iPhone, so this is not the Duo pose.
FoldableData forcedChrome() => FoldableData(
  capabilities: FoldableData.unsupported.capabilities,
  status: FoldableData.unsupported.status,
  angleDegrees: FoldableData.unsupported.angleDegrees,
  regions: const [],
  displayFeatures: const [],
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
      AdaptiveToolbarHost(debugFold: forcedChrome(), child: child!),
  home: home,
);

void usePhone(WidgetTester tester) {
  tester.view.physicalSize = const Size(402, 874);
  tester.view.devicePixelRatio = 1;
  tester.view.padding = const FakeViewPadding(top: 62, bottom: 34);
  tester.view.viewPadding = const FakeViewPadding(top: 62, bottom: 34);
  addTearDown(tester.view.reset);
}

Finder get bar => find.byType(HostedTopToolbar);
Finder inBar(Finder finder) => find.descendant(of: bar, matching: finder);

/// Opacity of the page layer (or shared back layer) [finder] is drawn in.
double opacityOf(WidgetTester tester, Finder finder) => tester
    .widget<FadeTransition>(
      find
          .ancestor(
            of: inBar(finder),
            // Layers are keyed; the buttons' own press feedback fades are not.
            matching: find.byWidgetPredicate(
              (w) => w is FadeTransition && w.key != null,
            ),
          )
          .first,
    )
    .opacity
    .value;

Finder get backButton => inBar(find.byType(AdaptiveButton));

void main() {
  group('HostedTopToolbar', () {
    testWidgets('one fixed bar at the top shows the page in front', (
      tester,
    ) async {
      usePhone(tester);
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
      expect(find.byType(HostedDuoBar), findsNothing);
      expect(inBar(find.text('Home')), findsOneWidget);
      expect(backButton, findsNothing);
      final rect = tester.getRect(
        find.descendant(of: bar, matching: find.byType(SizedBox)).first,
      );
      expect(rect.top, 0);
      expect(rect.height, kHostedToolbarHeight + 62);

      await tester.tap(inBar(find.byIcon(Icons.add)));
      expect(added, 1);

      nav.currentState!.push(
        MaterialPageRoute<void>(
          builder: (_) => page('Detail', action: Icons.share),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Mid-transition: the bar has not moved; it is handing over from the
      // outgoing page's items to the incoming page's.
      expect(
        tester.getRect(
          find.descendant(of: bar, matching: find.byType(SizedBox)).first,
        ),
        rect,
      );
      expect(opacityOf(tester, find.text('Home')), lessThan(1));
      expect(opacityOf(tester, find.text('Detail')), lessThan(1));
      await tester.pumpAndSettle();
      expect(inBar(find.text('Home')), findsNothing);
      expect(opacityOf(tester, find.text('Detail')), 1);

      // Back is performed on the owner's navigator.
      await tester.tap(backButton);
      await tester.pumpAndSettle();
      expect(find.text('body:Detail'), findsNothing);
      expect(inBar(find.text('Home')), findsOneWidget);
    });

    testWidgets('outgoing items leave before incoming ones arrive', (
      tester,
    ) async {
      usePhone(tester);
      final nav = GlobalKey<NavigatorState>();
      await tester.pumpWidget(hostedApp(navigatorKey: nav, home: page('Home')));
      await tester.pump();

      final route = PageRouteBuilder<void>(
        transitionDuration: const Duration(seconds: 4),
        reverseTransitionDuration: const Duration(seconds: 4),
        pageBuilder: (_, _, _) => page('Detail'),
      );
      nav.currentState!.push(route);
      await tester.pump();
      await tester.pump();

      // A quarter in: the old title is fading, the new one has not started.
      await tester.pump(const Duration(seconds: 1));
      expect(opacityOf(tester, find.text('Home')), inExclusiveRange(0, 1));
      expect(opacityOf(tester, find.text('Detail')), 0);

      // Three quarters in: the old one is gone, the new one is arriving.
      await tester.pump(const Duration(seconds: 2));
      expect(opacityOf(tester, find.text('Home')), 0);
      expect(opacityOf(tester, find.text('Detail')), inExclusiveRange(0, 1));
      await tester.pumpAndSettle();
    });

    testWidgets('a back button both pages show stays put', (tester) async {
      usePhone(tester);
      final nav = GlobalKey<NavigatorState>();
      await tester.pumpWidget(hostedApp(navigatorKey: nav, home: page('A')));
      await tester.pump();
      nav.currentState!.push(
        MaterialPageRoute<void>(builder: (_) => page('B')),
      );
      await tester.pumpAndSettle();
      final backRect = tester.getRect(backButton);

      nav.currentState!.push(
        MaterialPageRoute<void>(builder: (_) => page('C')),
      );
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));

      expect(backButton, findsOneWidget);
      expect(opacityOf(tester, find.byType(AdaptiveButton)), 1);
      expect(tester.getRect(backButton), backRect);
      expect(opacityOf(tester, find.text('B')), lessThan(1));
      await tester.pumpAndSettle();
    });

    testWidgets('pages are told the host draws their toolbar', (tester) async {
      usePhone(tester);
      ToolbarChromeScope? scope;
      await tester.pumpWidget(
        hostedApp(
          home: Builder(
            builder: (context) {
              scope = ToolbarChromeScope.maybeOf(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      expect(scope?.hostsToolbar, isTrue);
      expect(scope?.hostsDuoControls, isFalse);
    });

    testWidgets('a title with a subtitle is drawn by Flutter and blended', (
      tester,
    ) async {
      usePhone(tester);
      await tester.pumpWidget(
        hostedApp(
          home: const AdaptiveScaffold(
            appBar: AdaptiveAppBar(
              title: 'Inbox',
              subtitle: '3 unread',
              useNativeToolbar: true,
            ),
            body: SizedBox.shrink(),
          ),
        ),
      );
      await tester.pump();
      expect(inBar(find.text('3 unread')), findsOneWidget);
    });

    testWidgets('a page without a toolbar empties the bar', (tester) async {
      usePhone(tester);
      final nav = GlobalKey<NavigatorState>();
      await tester.pumpWidget(hostedApp(navigatorKey: nav, home: page('Home')));
      await tester.pump();

      nav.currentState!.push(
        MaterialPageRoute<void>(
          builder: (_) => const AdaptiveScaffold(body: SizedBox.shrink()),
        ),
      );
      await tester.pumpAndSettle();
      expect(bar, findsOneWidget);
      expect(inBar(find.text('Home')), findsNothing);

      nav.currentState!.pop();
      await tester.pumpAndSettle();
      expect(inBar(find.text('Home')), findsOneWidget);
    });

    testWidgets('on iPhone Duo the top bar keeps the title only', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(951, 669);
      tester.view.devicePixelRatio = 1;
      tester.view.padding = const FakeViewPadding(right: 84, bottom: 34);
      tester.view.viewPadding = const FakeViewPadding(right: 84, bottom: 34);
      addTearDown(tester.view.reset);

      await tester.pumpWidget(hostedApp(home: page('Home', action: Icons.add)));
      await tester.pump();

      expect(inBar(find.text('Home')), findsOneWidget);
      expect(inBar(find.byIcon(Icons.add)), findsNothing);
      expect(
        find.descendant(
          of: find.byType(HostedDuoBar),
          matching: find.byIcon(Icons.add),
        ),
        findsOneWidget,
      );
    });
  });
}
