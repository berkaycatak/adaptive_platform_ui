import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:adaptive_platform_ui/src/toolbar/hosted_duo_bar.dart';
import 'package:adaptive_platform_ui/src/toolbar/hosted_top_toolbar.dart';
import 'package:adaptive_platform_ui/src/toolbar/toolbar_chrome_scope.dart';
import 'package:flutter/cupertino.dart' show CupertinoIcons;
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

void main() {
  group('TopToolbarNativeSync', () {
    Map<String, dynamic> items(String title) => {'title': title};
    List<String> methods(List<TopToolbarNativeCall> calls) =>
        calls.map((c) => c.method).toList();

    TopToolbarNativeSync showing(String title) =>
        TopToolbarNativeSync()..created(items(title));

    test('nothing is sent while the bar already shows the content', () {
      final sync = showing('Home');
      expect(sync.update(owner: items('Home'), blendCount: null), isEmpty);
    });

    test('a page updating its own items is applied at once', () {
      final sync = showing('Home');
      final calls = sync.update(owner: items('Inbox (3)'), blendCount: null);
      expect(methods(calls), ['setItems']);
      expect(calls.single.arguments, items('Inbox (3)'));
    });

    test('a blend becomes one native transition into its target', () {
      final sync = showing('Home');

      final begin = sync.update(
        owner: items('Detail'),
        blendCount: 1,
        target: items('Detail'),
      );
      expect(methods(begin), ['beginItemTransition']);
      expect(begin.single.arguments, items('Detail'));
      expect(sync.isTransitioning, isTrue);

      // Further notifications of the same blend start nothing new.
      expect(
        sync.update(owner: items('Detail'), blendCount: 1, target: items('X')),
        isEmpty,
      );

      final end = sync.update(owner: items('Detail'), blendCount: null);
      expect(methods(end), ['endItemTransition']);
      expect(end.single.arguments, {'completed': true});
      expect(sync.isTransitioning, isFalse);
    });

    test('a cancelled back swipe settles back on the page it started on', () {
      final sync = showing('Detail');
      sync.update(owner: items('Detail'), blendCount: 1, target: items('Home'));

      final end = sync.update(
        owner: items('Detail'),
        blendCount: null,
        targetWon: false,
      );
      expect(methods(end), ['endItemTransition']);
      expect(end.single.arguments, {'completed': false});

      // The bar shows Detail again, so nothing more is needed.
      expect(sync.update(owner: items('Detail'), blendCount: null), isEmpty);
    });

    test('a completed back swipe needs no second transition', () {
      final sync = showing('Detail');
      sync.update(owner: items('Detail'), blendCount: 1, target: items('Home'));
      // The finger lifts, the route pops: same blend, new owner.
      expect(
        sync.update(owner: items('Home'), blendCount: 1, target: items('Home')),
        isEmpty,
      );
      final end = sync.update(owner: items('Home'), blendCount: null);
      expect(end.single.arguments, {'completed': true});
      expect(sync.update(owner: items('Home'), blendCount: null), isEmpty);
    });

    test('a navigation that overtakes another settles the first one', () {
      final sync = showing('A');
      sync.update(owner: items('B'), blendCount: 1, target: items('B'));
      final calls = sync.update(
        owner: items('C'),
        blendCount: 2,
        target: items('C'),
      );
      expect(methods(calls), ['endItemTransition', 'beginItemTransition']);
      expect(calls.last.arguments, items('C'));
    });

    test('pages with identical items do not transition', () {
      final sync = showing('Same');
      expect(
        sync.update(owner: items('Same'), blendCount: 1, target: items('Same')),
        isEmpty,
      );
      expect(sync.isTransitioning, isFalse);
      expect(sync.update(owner: items('Same'), blendCount: null), isEmpty);
    });

    test('items changed during a transition catch up when it ends', () {
      final sync = showing('Home');
      sync.update(
        owner: items('Detail'),
        blendCount: 1,
        target: items('Detail'),
      );
      final end = sync.update(owner: items('Detail (2)'), blendCount: null);
      expect(methods(end), ['endItemTransition', 'setItems']);
      expect(end.last.arguments, items('Detail (2)'));
    });
  });

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
      expect(inBar(find.byIcon(CupertinoIcons.chevron_left)), findsNothing);
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

      // Mid-transition: the bar has not moved and already belongs to the
      // incoming page (UIKit animates the item change itself).
      expect(
        tester.getRect(
          find.descendant(of: bar, matching: find.byType(SizedBox)).first,
        ),
        rect,
      );
      expect(inBar(find.text('Detail')), findsOneWidget);
      await tester.pumpAndSettle();

      // Back is performed on the owner's navigator.
      await tester.tap(inBar(find.byIcon(CupertinoIcons.chevron_left)));
      await tester.pumpAndSettle();
      expect(find.text('body:Detail'), findsNothing);
      expect(inBar(find.text('Home')), findsOneWidget);
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

    testWidgets('a page without a toolbar hides the bar but keeps it alive', (
      tester,
    ) async {
      usePhone(tester);
      final nav = GlobalKey<NavigatorState>();
      await tester.pumpWidget(hostedApp(navigatorKey: nav, home: page('Home')));
      await tester.pump();
      final element = tester.element(bar);

      nav.currentState!.push(
        MaterialPageRoute<void>(
          builder: (_) => const AdaptiveScaffold(body: SizedBox.shrink()),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.element(bar), same(element));
      expect(
        tester
            .widget<AnimatedOpacity>(
              find.descendant(of: bar, matching: find.byType(AnimatedOpacity)),
            )
            .opacity,
        0,
      );
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
