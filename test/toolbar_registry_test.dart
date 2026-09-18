import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The registry owned by the [AdaptiveToolbarHost] under test.
ToolbarRegistry registryOf(WidgetTester tester) => tester
    .widget<ToolbarRegistryScope>(find.byType(ToolbarRegistryScope))
    .notifier!;

Widget page(String? title) => AdaptiveScaffold(
  appBar: title == null ? null : AdaptiveAppBar(title: title),
  body: Center(child: Text('body:$title')),
);

/// Hosts the navigator the way an app `builder` does: the host sits above
/// the navigator, outside every route.
Widget hostedApp({
  required Widget home,
  GlobalKey<NavigatorState>? navigatorKey,
}) => MaterialApp(
  navigatorKey: navigatorKey,
  builder: (context, child) => AdaptiveToolbarHost(child: child!),
  home: home,
);

/// How a tab container keeps its non-selected pages alive but hidden.
typedef TabContainer = Widget Function(int index, List<Widget> children);

/// Flutter's own [IndexedStack]: hides children with [Visibility.maintain],
/// which keeps their tickers enabled.
Widget plainIndexedStack(int index, List<Widget> children) =>
    IndexedStack(index: index, children: children);

/// What GoRouter's `StatefulShellRoute.indexedStack` and
/// `CupertinoTabScaffold` do: [Offstage] plus a disabled [TickerMode].
Widget offstageWithTickerMode(int index, List<Widget> children) => Stack(
  children: [
    for (var i = 0; i < children.length; i++)
      Offstage(
        offstage: i != index,
        child: TickerMode(enabled: i == index, child: children[i]),
      ),
  ],
);

void main() {
  group('ToolbarRegistry: single navigator', () {
    testWidgets('the root page registers and owns the chrome', (tester) async {
      await tester.pumpWidget(hostedApp(home: page('Home')));
      await tester.pump();

      final registry = registryOf(tester);
      expect(registry.entries, hasLength(1));
      expect(registry.active?.appBar?.title, 'Home');
      expect(registry.active?.canPop, isFalse);
    });

    testWidgets('push hands the chrome to the new page, pop gives it back', (
      tester,
    ) async {
      final nav = GlobalKey<NavigatorState>();
      await tester.pumpWidget(hostedApp(navigatorKey: nav, home: page('Home')));
      await tester.pump();
      final registry = registryOf(tester);

      nav.currentState!.push(
        MaterialPageRoute<void>(builder: (_) => page('Detail')),
      );
      await tester.pumpAndSettle();

      // The page beneath stays mounted, but is no longer the current route.
      expect(registry.entries, hasLength(2));
      expect(registry.active?.appBar?.title, 'Detail');
      expect(registry.active?.canPop, isTrue);

      nav.currentState!.pop();
      await tester.pumpAndSettle();

      expect(registry.entries, hasLength(1));
      expect(registry.active?.appBar?.title, 'Home');
      expect(registry.active?.canPop, isFalse);
    });

    testWidgets('items never mix across a deep stack', (tester) async {
      final nav = GlobalKey<NavigatorState>();
      await tester.pumpWidget(hostedApp(navigatorKey: nav, home: page('A')));
      await tester.pump();
      final registry = registryOf(tester);

      for (final title in ['B', 'C', 'D']) {
        nav.currentState!.push(
          MaterialPageRoute<void>(builder: (_) => page(title)),
        );
        await tester.pumpAndSettle();
        expect(registry.active?.appBar?.title, title);
      }

      for (final title in ['C', 'B', 'A']) {
        nav.currentState!.pop();
        await tester.pumpAndSettle();
        expect(registry.active?.appBar?.title, title);
      }
      expect(registry.entries, hasLength(1));
    });

    testWidgets('a page without an app bar empties the chrome', (tester) async {
      final nav = GlobalKey<NavigatorState>();
      await tester.pumpWidget(hostedApp(navigatorKey: nav, home: page('Home')));
      await tester.pump();
      final registry = registryOf(tester);

      nav.currentState!.push(
        MaterialPageRoute<void>(builder: (_) => page(null)),
      );
      await tester.pumpAndSettle();

      // The bar-less page still owns the chrome, so the previous page's
      // items do not linger on it.
      expect(registry.active, isNotNull);
      expect(registry.active?.appBar, isNull);

      nav.currentState!.pop();
      await tester.pumpAndSettle();
      expect(registry.active?.appBar?.title, 'Home');
    });

    testWidgets('replacing the top route swaps the owner', (tester) async {
      final nav = GlobalKey<NavigatorState>();
      await tester.pumpWidget(hostedApp(navigatorKey: nav, home: page('Home')));
      await tester.pump();
      final registry = registryOf(tester);

      nav.currentState!.push(
        MaterialPageRoute<void>(builder: (_) => page('First')),
      );
      await tester.pumpAndSettle();
      nav.currentState!.pushReplacement(
        MaterialPageRoute<void>(builder: (_) => page('Second')),
      );
      await tester.pumpAndSettle();

      expect(registry.active?.appBar?.title, 'Second');
      expect(
        registry.entries.map((e) => e.appBar?.title),
        isNot(contains('First')),
      );
    });

    testWidgets('a changed app bar is republished', (tester) async {
      final title = ValueNotifier<String>('Draft');
      await tester.pumpWidget(
        hostedApp(
          home: ValueListenableBuilder<String>(
            valueListenable: title,
            builder: (_, value, _) => page(value),
          ),
        ),
      );
      await tester.pump();
      final registry = registryOf(tester);
      expect(registry.active?.appBar?.title, 'Draft');

      title.value = 'Saved';
      await tester.pump();
      await tester.pump();

      expect(registry.entries, hasLength(1));
      expect(registry.active?.appBar?.title, 'Saved');
    });
  });

  group('ToolbarRegistry: tabs with nested navigators', () {
    // A shell scaffold (no app bar) around per-tab navigators, the shape of
    // GoRouter's StatefulShellRoute, CupertinoTabScaffold and hand-rolled
    // bottom navigation alike. Containers differ only in how they hide the
    // non-selected tabs, and both ways must be understood.
    final containers = <String, TabContainer>{
      'IndexedStack (Visibility.maintain)': plainIndexedStack,
      'Offstage + TickerMode (GoRouter, CupertinoTabScaffold)':
          offstageWithTickerMode,
    };

    for (final MapEntry(key: name, value: container) in containers.entries) {
      testWidgets('only the visible tab owns the chrome: $name', (
        tester,
      ) async {
        final index = ValueNotifier<int>(0);
        final tabNavs = [
          GlobalKey<NavigatorState>(),
          GlobalKey<NavigatorState>(),
        ];

        Widget tab(int i, String title) => Navigator(
          key: tabNavs[i],
          onGenerateRoute: (_) =>
              MaterialPageRoute<void>(builder: (_) => page(title)),
        );

        await tester.pumpWidget(
          hostedApp(
            home: AdaptiveScaffold(
              body: ValueListenableBuilder<int>(
                valueListenable: index,
                builder: (_, value, _) =>
                    container(value, [tab(0, 'Home'), tab(1, 'Info')]),
              ),
            ),
          ),
        );
        await tester.pump();
        final registry = registryOf(tester);

        // Shell + both tab roots are mounted; the visible tab wins over the
        // shell (newest active) and over the hidden tab (not visible).
        expect(registry.active?.appBar?.title, 'Home');
        expect(registry.active?.canPop, isFalse);

        index.value = 1;
        await tester.pump();
        await tester.pump();
        expect(registry.active?.appBar?.title, 'Info');

        // Push inside the visible tab: its nested navigator can pop, the
        // root one is irrelevant.
        tabNavs[1].currentState!.push(
          MaterialPageRoute<void>(builder: (_) => page('Info detail')),
        );
        await tester.pumpAndSettle();
        expect(registry.active?.appBar?.title, 'Info detail');
        expect(registry.active?.canPop, isTrue);

        // Switching away hides the pushed page without disturbing its stack.
        index.value = 0;
        await tester.pump();
        await tester.pump();
        expect(registry.active?.appBar?.title, 'Home');
        expect(registry.active?.canPop, isFalse);

        // Coming back restores the pushed page as the owner.
        index.value = 1;
        await tester.pump();
        await tester.pump();
        expect(registry.active?.appBar?.title, 'Info detail');
        expect(registry.active?.canPop, isTrue);
      });
    }
  });

  group('ToolbarRegistry: notifications', () {
    ToolbarEntry entry(Object id) => ToolbarEntry(
      id: id,
      appBar: null,
      route: null,
      navigator: null,
      visible: true,
    );

    // Pages register while the framework is building, and an app's very first
    // build runs outside of a frame with the scheduler still idle, so a
    // synchronous notification would dirty the chrome mid-build. The state is
    // updated at once; only the notification waits for the frame to end.
    testWidgets('are never delivered synchronously', (tester) async {
      final registry = ToolbarRegistry();
      addTearDown(registry.dispose);
      var calls = 0;
      registry.addListener(() => calls++);

      final id = Object();
      registry.upsert(entry(id));
      expect(registry.entries, hasLength(1), reason: 'state updates at once');
      expect(calls, 0, reason: 'notification must wait for the frame to end');

      await tester.pump();
      expect(calls, 1);

      registry.remove(id);
      expect(registry.entries, isEmpty);
      expect(calls, 1);
      await tester.pump();
      expect(calls, 2);
    });

    testWidgets('a burst is coalesced into one notification', (tester) async {
      final registry = ToolbarRegistry();
      addTearDown(registry.dispose);
      var calls = 0;
      registry.addListener(() => calls++);

      registry
        ..upsert(entry(Object()))
        ..upsert(entry(Object()))
        ..upsert(entry(Object()));
      await tester.pump();

      expect(registry.entries, hasLength(3));
      expect(calls, 1);
    });

    testWidgets('nothing is delivered after dispose', (tester) async {
      final registry = ToolbarRegistry();
      var calls = 0;
      registry.addListener(() => calls++);

      registry.upsert(entry(Object()));
      registry.dispose();
      await tester.pump();

      expect(calls, 0);
      expect(tester.takeException(), isNull);
    });
  });

  group('ToolbarRegistry: no host installed', () {
    testWidgets('the scaffold still works and publishes nothing', (
      tester,
    ) async {
      await tester.pumpWidget(MaterialApp(home: page('Standalone')));
      await tester.pump();

      expect(find.byType(ToolbarRegistryScope), findsNothing);
      expect(find.text('body:Standalone'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
