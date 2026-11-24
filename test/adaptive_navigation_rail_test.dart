import 'dart:convert';

import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:adaptive_platform_ui/src/widgets/ios26/ios26_glass_capsule.dart';
import 'package:flutter/cupertino.dart' show CupertinoColors;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// A 1x1 PNG.
final _png = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR4nGP4z8DwHwAFAA'
  'H/q842iQAAAABJRU5ErkJggg==',
);

const _destinations = [
  AdaptiveNavigationDestination(icon: 'house', label: 'Home'),
  AdaptiveNavigationDestination(icon: 'bubble.left', label: 'Chat'),
  AdaptiveNavigationDestination(icon: 'clock', label: 'History'),
];

void main() {
  group('GlassCapsuleItem picture', () {
    test('an action carries its iconImage as image bytes', () {
      final item = GlassCapsuleItem.fromAction(
        AdaptiveAppBarAction(
          iconImage: _png,
          label: 'My profile',
          onPressed: () {},
        ),
      );

      expect(item.toNativeMap()['image'], _png);
      expect(item.canShowNatively, isTrue);
    });
  });

  group('IOS26GlassCapsule labels', () {
    Widget capsule({bool showLabels = false}) => MaterialApp(
      home: Center(
        child: SizedBox(
          width: IOS26GlassCapsule.labeledWidth,
          height: 300,
          child: IOS26GlassCapsule(
            items: const [
              GlassCapsuleItem(symbol: 'house', label: 'Home'),
              GlassCapsuleItem(symbol: 'bubble.left', label: 'Chat'),
            ],
            selectedIndex: 0,
            showLabels: showLabels,
            onTap: (_) {},
          ),
        ),
      ),
    );

    testWidgets('asks the native view to show them', (tester) async {
      await tester.pumpWidget(capsule(showLabels: true));

      final view = tester.widget<UiKitView>(find.byType(UiKitView));
      expect((view.creationParams as Map)['showLabels'], isTrue);
    }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

    testWidgets('are left out unless asked for', (tester) async {
      await tester.pumpWidget(capsule());

      final view = tester.widget<UiKitView>(find.byType(UiKitView));
      expect((view.creationParams as Map).containsKey('showLabels'), isFalse);
    }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

    testWidgets('are drawn under the icons where there is no UIKit', (
      tester,
    ) async {
      await tester.pumpWidget(capsule(showLabels: true));

      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Chat'), findsOneWidget);
    });

    test('a labeled tab capsule is taller than an icon-only one', () {
      expect(
        IOS26GlassCapsule.labeledTabsHeight(5),
        greaterThan(IOS26GlassCapsule.tabsHeight(5)),
      );
    });
  });

  group('AdaptiveNavigationRail', () {
    Future<void> pumpRail(
      WidgetTester tester, {
      int selectedIndex = 0,
      ValueChanged<int>? onDestinationSelected,
      List<AdaptiveAppBarAction> actions = const [],
    }) => tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Row(
            children: [
              AdaptiveNavigationRail(
                destinations: _destinations,
                selectedIndex: selectedIndex,
                onDestinationSelected: onDestinationSelected ?? (_) {},
                actions: actions,
              ),
              const Expanded(child: SizedBox.expand()),
            ],
          ),
        ),
      ),
    );

    testWidgets('off iOS 26 it is a Material rail with every label', (
      tester,
    ) async {
      await pumpRail(tester, selectedIndex: 1);

      final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
      expect(rail.selectedIndex, 1);
      expect(rail.labelType, NavigationRailLabelType.all);
      for (final label in ['Home', 'Chat', 'History']) {
        expect(find.text(label), findsOneWidget);
      }
    });

    testWidgets('reports the destination tapped', (tester) async {
      final tapped = <int>[];
      await pumpRail(tester, onDestinationSelected: tapped.add);

      await tester.tap(find.text('History'));
      await tester.pump();

      expect(tapped, [2]);
    });

    testWidgets('puts the actions under the destinations, with their count', (
      tester,
    ) async {
      var opened = 0;
      await pumpRail(
        tester,
        actions: [
          AdaptiveAppBarAction(
            iosSymbol: 'bell',
            icon: Icons.notifications_outlined,
            label: 'Notifications',
            badgeCount: 4,
            onPressed: () => opened++,
          ),
        ],
      );

      expect(find.text('4'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.notifications_outlined));
      await tester.pump();
      expect(opened, 1);
    });
  });

  group('AdaptiveNavigationRail.planFor', () {
    RailPlan plan(double height, {int actions = 2}) =>
        AdaptiveNavigationRail.planFor(
          height: height,
          destinationCount: 5,
          actionCount: actions,
          showLabels: true,
        );

    test('keeps the labels and every action when they fit (an iPad)', () {
      final it = plan(900);
      expect(it.showLabels, isTrue);
      expect(it.foldActions, isFalse);
    });

    test('drops the labels before the actions', () {
      // Labeled tabs and two actions do not fit; icon-only tabs do.
      final it = plan(380);
      expect(it.showLabels, isFalse);
      expect(it.foldActions, isFalse);
    });

    test('folds the actions into one menu when even that does not fit '
        '(a phone turned sideways)', () {
      final it = plan(345);
      expect(it.showLabels, isFalse);
      expect(it.foldActions, isTrue);
    });

    test('has nothing to fold with a single action', () {
      expect(plan(200, actions: 1).foldActions, isFalse);
    });

    test('never shows labels that were not asked for', () {
      final it = AdaptiveNavigationRail.planFor(
        height: 900,
        destinationCount: 5,
        actionCount: 2,
        showLabels: false,
      );
      expect(it.showLabels, isFalse);
    });
  });

  group('AdaptiveNavigationRail leading, footer and anchors', () {
    final destinationKeys = [for (var i = 0; i < 3; i++) GlobalKey()];
    final actionKeys = [GlobalKey(), GlobalKey()];
    final actions = [
      AdaptiveAppBarAction(
        iosSymbol: 'bell',
        icon: Icons.notifications_outlined,
        label: 'Notifications',
        onPressed: () {},
      ),
      AdaptiveAppBarAction(
        iosSymbol: 'person.crop.circle',
        icon: Icons.person_outline,
        label: 'My profile',
        onPressed: () {},
      ),
    ];

    Future<void> pumpRail(WidgetTester tester, {double height = 900}) {
      tester.view.physicalSize = Size(800, height);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      return tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Row(
              children: [
                AdaptiveNavigationRail(
                  destinations: _destinations,
                  selectedIndex: 0,
                  onDestinationSelected: (_) {},
                  actions: actions,
                  margin: 4,
                  leading: const Text('Logo'),
                  leadingExtent: 40,
                  footer: const Text('Share'),
                  footerExtent: 48,
                  destinationKeys: destinationKeys,
                  actionKeys: actionKeys,
                ),
                const Expanded(child: SizedBox.expand()),
              ],
            ),
          ),
        ),
      );
    }

    testWidgets('off iOS 26 the Material rail shows them and carries the '
        'keys', (tester) async {
      await pumpRail(tester);

      expect(find.text('Logo'), findsOneWidget);
      expect(find.text('Share'), findsOneWidget);
      for (final key in [...destinationKeys, ...actionKeys]) {
        expect(find.byKey(key), findsOneWidget);
      }
    });

    group('on the glass rail', () {
      setUp(() => AdaptiveNavigationRail.debugForceGlass = true);
      tearDown(() => AdaptiveNavigationRail.debugForceGlass = null);

      testWidgets('the logo sits above the destinations and the footer '
          'above the actions', (tester) async {
        await pumpRail(tester);

        final logo = tester.getRect(find.text('Logo'));
        final share = tester.getRect(find.text('Share'));
        final firstDestination = tester.getRect(find.byKey(destinationKeys[0]));
        final firstAction = tester.getRect(find.byKey(actionKeys[0]));
        expect(logo.bottom, lessThanOrEqualTo(firstDestination.top));
        expect(share.bottom, lessThanOrEqualTo(firstAction.top));
      }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

      testWidgets('each destination and action has an anchor over its cell, '
          'in order', (tester) async {
        await pumpRail(tester);

        final rects = [
          for (final key in destinationKeys) tester.getRect(find.byKey(key)),
        ];
        for (var i = 1; i < rects.length; i++) {
          expect(rects[i].top, greaterThanOrEqualTo(rects[i - 1].bottom));
          expect(rects[i].height, rects[0].height);
        }
        expect(
          tester.getRect(find.byKey(actionKeys[1])).top,
          greaterThanOrEqualTo(
            tester.getRect(find.byKey(actionKeys[0])).bottom,
          ),
        );
      }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

      testWidgets('the rail is the capsule plus the margins wide', (
        tester,
      ) async {
        await pumpRail(tester);

        expect(
          tester.getSize(find.byType(AdaptiveNavigationRail)).width,
          IOS26GlassCapsule.labeledWidth + 4 * 2,
        );
      }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

      testWidgets('with the actions folded, their anchors are gone', (
        tester,
      ) async {
        // With three destinations, the logo and the footer, 330 of column
        // (338 less the margins) only fits the folded actions.
        await pumpRail(tester, height: 338);

        expect(find.byKey(actionKeys[0]), findsNothing);
        expect(find.byKey(actionKeys[1]), findsNothing);
        expect(find.byKey(destinationKeys[0]), findsOneWidget);
      }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

      testWidgets('the folded actions are one round button, as wide as tall', (
        tester,
      ) async {
        await pumpRail(tester, height: 360);

        final size = tester.getSize(
          find.byWidgetPredicate(
            (w) => w is IOS26GlassCapsule && w.items.length == 1,
          ),
        );
        expect(size.width, size.height);
      }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));
    });
  });

  test('planFor counts the leading and the footer', () {
    RailPlan plan(double fixed) => AdaptiveNavigationRail.planFor(
      height: 500,
      destinationCount: 5,
      actionCount: 2,
      showLabels: true,
      fixedExtent: fixed,
    );
    // 312 of labeled tabs, 8 of gap and 100 of actions: 420.
    expect(plan(80).showLabels, isTrue);
    expect(plan(81).showLabels, isFalse);
  });

  group('drawn by Flutter (native: false)', () {
    testWidgets('a capsule keeps its layout without the native view', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: SizedBox(
              width: IOS26GlassCapsule.width,
              height: 300,
              child: IOS26GlassCapsule(
                items: const [
                  GlassCapsuleItem(symbol: 'house', label: 'Home'),
                  GlassCapsuleItem(symbol: 'bubble.left', label: 'Chat'),
                ],
                selectedIndex: 1,
                native: false,
                onTap: (_) {},
              ),
            ),
          ),
        ),
      );

      expect(find.byType(UiKitView), findsNothing);
      expect(
        find.byKey(IOS26GlassCapsule.fallbackSelectionKey),
        findsOneWidget,
      );
    }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

    testWidgets('the tab capsule shows the fallback icons it is given, with '
        'an anchor per tab, at the size of the native one', (tester) async {
      final keys = [for (var i = 0; i < 3; i++) GlobalKey()];
      final tapped = <int>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: AdaptiveTabCapsule(
              destinations: _destinations,
              selectedIndex: 0,
              onDestinationSelected: tapped.add,
              native: false,
              destinationKeys: keys,
              fallbackIcons: const [
                Icon(Icons.home, key: ValueKey('home')),
                Icon(Icons.chat, key: ValueKey('chat')),
                Icon(Icons.history, key: ValueKey('history')),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(UiKitView), findsNothing);
      expect(find.byKey(const ValueKey('chat')), findsOneWidget);
      for (final key in keys) {
        expect(find.byKey(key), findsOneWidget);
      }
      expect(
        tester.getSize(find.byType(AdaptiveTabCapsule)),
        Size(AdaptiveTabCapsule.widthFor(), AdaptiveTabCapsule.heightFor(3)),
      );

      await tester.tap(find.byKey(const ValueKey('history')));
      expect(tapped, [2]);
    }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

    testWidgets('the action capsule runs the action tapped', (tester) async {
      var pressed = 0;
      final key = GlobalKey();
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: AdaptiveActionCapsule(
              actions: [
                AdaptiveAppBarAction(
                  iosSymbol: 'bell',
                  icon: Icons.notifications_outlined,
                  label: 'Notifications',
                  onPressed: () => pressed++,
                ),
              ],
              actionKeys: [key],
              native: false,
            ),
          ),
        ),
      );

      expect(
        tester.getSize(find.byType(AdaptiveActionCapsule)).height,
        AdaptiveActionCapsule.heightFor(1),
      );
      await tester.tap(find.byIcon(Icons.notifications_outlined));
      expect(pressed, 1);
      expect(find.byKey(key), findsOneWidget);
    }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

    testWidgets('the rail keeps its capsules, drawn by Flutter', (
      tester,
    ) async {
      AdaptiveNavigationRail.debugForceGlass = true;
      addTearDown(() => AdaptiveNavigationRail.debugForceGlass = null);
      final keys = [for (var i = 0; i < 3; i++) GlobalKey()];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Row(
              children: [
                AdaptiveNavigationRail(
                  destinations: _destinations,
                  selectedIndex: 0,
                  onDestinationSelected: (_) {},
                  native: false,
                  destinationKeys: keys,
                ),
                const Expanded(child: SizedBox.expand()),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(UiKitView), findsNothing);
      expect(find.byType(NavigationRail), findsNothing);
      expect(find.byType(AdaptiveTabCapsule), findsOneWidget);
      expect(find.byKey(keys[0]), findsOneWidget);
    }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));
  });

  group('itemExtent', () {
    test('sizes the tab capsule by the cell, between its insets', () {
      expect(
        AdaptiveTabCapsule.heightFor(5, itemExtent: 44),
        5 * 44 + 2 * IOS26GlassCapsule.tabsInset,
      );
      expect(AdaptiveTabCapsule.heightFor(5), IOS26GlassCapsule.tabsHeight(5));
    });

    test('sizes the action capsule by the cell', () {
      expect(AdaptiveActionCapsule.heightFor(2, itemExtent: 44), 88);
      expect(
        AdaptiveActionCapsule.heightFor(2),
        IOS26GlassCapsule.actionsHeight(2),
      );
    });

    testWidgets('the capsules take that height', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Column(
            children: [
              AdaptiveTabCapsule(
                destinations: _destinations,
                selectedIndex: 0,
                onDestinationSelected: (_) {},
                itemExtent: 44,
              ),
              AdaptiveActionCapsule(
                actions: [
                  AdaptiveAppBarAction(
                    iosSymbol: 'bell',
                    icon: Icons.notifications_outlined,
                    onPressed: () {},
                  ),
                ],
                itemExtent: 44,
              ),
            ],
          ),
        ),
      );

      expect(
        tester.getSize(find.byType(AdaptiveTabCapsule)).height,
        3 * 44 + 2 * IOS26GlassCapsule.tabsInset,
      );
      expect(tester.getSize(find.byType(AdaptiveActionCapsule)).height, 44);
    });
  });

  group('the capsule drawn by Flutter looks like the native one', () {
    Future<void> pumpCapsule(
      WidgetTester tester, {
      Color? tint,
      int? selectedIndex = 0,
    }) => tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: SizedBox(
            width: IOS26GlassCapsule.width,
            height: 200,
            child: IOS26GlassCapsule(
              items: const [
                GlassCapsuleItem(
                  symbol: 'house',
                  label: 'Home',
                  fallback: Icon(Icons.home, key: ValueKey('home')),
                ),
                GlassCapsuleItem(
                  symbol: 'list',
                  label: 'History',
                  badge: 3,
                  fallback: Icon(Icons.list, key: ValueKey('history')),
                ),
              ],
              selectedIndex: selectedIndex,
              tint: tint,
              native: false,
              onTap: (_) {},
            ),
          ),
        ),
      ),
    );

    testWidgets('draws the count of an item as a red badge', (tester) async {
      await pumpCapsule(tester);

      expect(find.text('3'), findsOneWidget);
      final badge = tester.widget<DecoratedBox>(
        find
            .ancestor(of: find.text('3'), matching: find.byType(DecoratedBox))
            .first,
      );
      expect(
        (badge.decoration as BoxDecoration).color,
        CupertinoColors.systemRed,
      );
    }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

    testWidgets('is a pill about 18 tall, not as tall as its cell', (
      tester,
    ) async {
      await pumpCapsule(tester);

      final badge = find
          .ancestor(of: find.text('3'), matching: find.byType(DecoratedBox))
          .first;
      // 18 with the system font; the test font's glyphs are a little larger.
      expect(tester.getSize(badge).height, inInclusiveRange(18, 22));
      expect(tester.getSize(badge).width, inInclusiveRange(18, 22));
    }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

    testWidgets('caps a large count at 99+, as the native one does', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            width: IOS26GlassCapsule.width,
            height: 100,
            child: IOS26GlassCapsule(
              items: const [
                GlassCapsuleItem(
                  symbol: 'bell',
                  badge: 150,
                  fallback: Icon(Icons.notifications),
                ),
              ],
              native: false,
              onTap: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('99+'), findsOneWidget);
    }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

    testWidgets('tints the selected item system blue unless told otherwise', (
      tester,
    ) async {
      await pumpCapsule(tester);

      final home = tester.widget<IconTheme>(
        find
            .ancestor(
              of: find.byKey(const ValueKey('home')),
              matching: find.byType(IconTheme),
            )
            .first,
      );
      expect(home.data.color, CupertinoColors.systemBlue);
    }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

    testWidgets('leaves the controls of a capsule without a selection in the '
        'label color, not blue', (tester) async {
      await pumpCapsule(tester, selectedIndex: null);

      final home = tester.widget<IconTheme>(
        find
            .ancestor(
              of: find.byKey(const ValueKey('home')),
              matching: find.byType(IconTheme),
            )
            .first,
      );
      expect(home.data.color, isNot(CupertinoColors.systemBlue));
    }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

    testWidgets('and with the tint it is given', (tester) async {
      await pumpCapsule(tester, tint: const Color(0xFF123456));

      final home = tester.widget<IconTheme>(
        find
            .ancestor(
              of: find.byKey(const ValueKey('home')),
              matching: find.byType(IconTheme),
            )
            .first,
      );
      expect(home.data.color, const Color(0xFF123456));
    }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));
  });
}
