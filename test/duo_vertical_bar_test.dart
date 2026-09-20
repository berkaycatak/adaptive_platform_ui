import 'package:adaptive_platform_ui/src/toolbar/duo_vertical_bar.dart';
import 'package:adaptive_platform_ui/src/widgets/adaptive_app_bar_action.dart';
import 'package:adaptive_platform_ui/src/widgets/ios26/ios26_glass_capsule.dart';
import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foldable/foldable.dart';

/// Geometry measured on the iPhone Duo inner display (iOS 27.1 simulator).
const Size duoLandscape = Size(951, 669);
const EdgeInsets duoPadding = EdgeInsets.only(right: 84, bottom: 34);
const ReservedRegion duoCamera = ReservedRegion(
  kind: ReservedRegionKind.occlusion,
  bounds: Rect.fromLTRB(867, 0, 951, 120),
  isActive: true,
);
const ReservedRegion duoFlatFold = ReservedRegion(
  kind: ReservedRegionKind.division,
  bounds: Rect.fromLTRB(455.5, 0, 495.5, 669),
  isActive: false,
);

/// The cover display while folded.
const Size duoCover = Size(466, 678);
const ReservedRegion duoCoverCluster = ReservedRegion(
  kind: ReservedRegionKind.occlusion,
  bounds: Rect.fromLTRB(382, 0, 466, 170),
  isActive: true,
);

void main() {
  group('DuoLayout: detection', () {
    test(
      'the inner display and the folded cover display: strip on the right',
      () {
        // Both measured with the same insets.
        expect(DuoLayout.barSide(duoPadding), DuoBarSide.right);
        expect(DuoLayout.isVerticalBarPose(duoPadding), isTrue);
      },
    );

    test('one landscape rotation moves the strip to the left', () {
      // Measured on the cover display: 678x466, left 84, bottom 34.
      const rotated = EdgeInsets.only(left: 84, bottom: 34);
      expect(DuoLayout.barSide(rotated), DuoBarSide.left);
      expect(DuoLayout.stripWidth(rotated), 84);
    });

    test('an ordinary iPhone in portrait has a top inset', () {
      expect(
        DuoLayout.barSide(const EdgeInsets.only(top: 62, bottom: 34)),
        isNull,
      );
    });

    test('an ordinary iPhone in landscape is inset on both sides', () {
      expect(
        DuoLayout.barSide(
          const EdgeInsets.only(left: 62, right: 62, bottom: 21),
        ),
        isNull,
      );
    });

    test('an iPad has no side inset', () {
      expect(
        DuoLayout.barSide(const EdgeInsets.only(top: 24, bottom: 20)),
        isNull,
      );
    });
  });

  group('DuoLayout: clearance follows the camera through rotations', () {
    const coverLandscape = Size(678, 466);

    test(
      'landscape, strip right: the camera is at the bottom of the strip',
      () {
        final insets = DuoLayout.barInsets(
          size: coverLandscape,
          padding: duoPadding,
          regions: const [
            ReservedRegion(
              kind: ReservedRegionKind.occlusion,
              bounds: Rect.fromLTWH(594, 384, 84, 82),
              isActive: true,
            ),
          ],
        );
        expect(insets.top, kDuoBarEdgeMargin);
        expect(insets.bottom, 466 - 384 + kDuoBarRegionGap);
      },
    );

    test('landscape, strip left: the camera is at the top of the strip', () {
      final insets = DuoLayout.barInsets(
        size: coverLandscape,
        padding: const EdgeInsets.only(left: 84, bottom: 34),
        regions: const [
          ReservedRegion(
            kind: ReservedRegionKind.occlusion,
            bounds: Rect.fromLTWH(0, 0, 84, 82),
            isActive: true,
          ),
        ],
      );
      expect(insets.top, 82);
      expect(insets.bottom, kDuoBarEdgeMargin);
    });
  });

  group('DuoLayout: geometry', () {
    test('the bar takes the strip the system reserves', () {
      expect(DuoLayout.stripWidth(duoPadding), 84);
      expect(DuoLayout.bandWidth(duoPadding), 84 + kDuoVerticalBarBezelInset);
    });

    test('falls back when no trailing inset is reported', () {
      expect(DuoLayout.stripWidth(EdgeInsets.zero), kDuoVerticalBarWidth);
    });

    test('controls start below the camera, not under it', () {
      expect(
        DuoLayout.topClearance(
          size: duoLandscape,
          padding: duoPadding,
          regions: const [duoCamera, duoFlatFold],
        ),
        120,
      );
    });

    test('on the cover display too', () {
      expect(
        DuoLayout.topClearance(
          size: duoCover,
          padding: duoPadding,
          regions: const [duoCoverCluster],
        ),
        170,
      );
    });

    test('a stale region from the other display is ignored while folding', () {
      // Just folded: the window is the cover display, the regions are still
      // the inner display's. Using them would park the bar 50pt too high.
      expect(
        DuoLayout.topClearance(
          size: duoCover,
          padding: duoPadding,
          regions: const [duoCamera],
        ),
        kDuoStatusClusterFallbackHeight,
      );
    });

    test('stays clear of the cluster until regions are reported', () {
      expect(
        DuoLayout.topClearance(
          size: duoLandscape,
          padding: duoPadding,
          regions: const [],
        ),
        kDuoStatusClusterFallbackHeight,
      );
    });

    test('inactive or non-overlapping occlusions are ignored', () {
      const inactive = ReservedRegion(
        kind: ReservedRegionKind.occlusion,
        bounds: Rect.fromLTRB(867, 0, 951, 120),
        isActive: false,
      );
      const leftSide = ReservedRegion(
        kind: ReservedRegionKind.occlusion,
        bounds: Rect.fromLTRB(0, 0, 80, 120),
        isActive: true,
      );
      expect(
        DuoLayout.topClearance(
          size: duoLandscape,
          padding: const EdgeInsets.only(right: 84),
          regions: const [inactive, leftSide, duoFlatFold],
        ),
        kDuoStatusClusterFallbackHeight,
      );
    });
  });

  group('DuoVerticalBar', () {
    Future<void> pumpBar(WidgetTester tester, DuoVerticalBar bar) {
      return tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: duoLandscape,
              padding: duoPadding,
              viewPadding: duoPadding,
            ),
            child: Align(
              alignment: Alignment.topRight,
              child: SizedBox(
                width: DuoLayout.bandWidth(duoPadding),
                height: duoLandscape.height,
                child: bar,
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('orders back first, then actions, clear of the camera', (
      tester,
    ) async {
      tester.view.physicalSize = duoLandscape;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      var tapped = 0;
      await pumpBar(
        tester,
        DuoVerticalBar(
          leading: const SizedBox(key: Key('back'), width: 38, height: 38),
          actions: [
            AdaptiveAppBarAction(icon: Icons.add, onPressed: () => tapped++),
            AdaptiveAppBarAction(title: 'Edit', onPressed: () {}),
          ],
          regions: const [duoCamera],
        ),
      );

      final back = tester.getRect(find.byKey(const Key('back')));
      final add = tester.getRect(find.byIcon(Icons.add));
      final edit = tester.getRect(find.text('Edit'));
      expect(back.top, greaterThanOrEqualTo(duoCamera.bounds.bottom));
      expect(add.top, greaterThan(back.bottom));
      expect(edit.top, greaterThan(add.bottom));

      await tester.tap(find.byIcon(Icons.add));
      expect(tapped, 1);
    });

    test('spacers split the actions into the groups that share a capsule', () {
      AdaptiveAppBarAction action(String t, ToolbarSpacerType spacer) =>
          AdaptiveAppBarAction(title: t, onPressed: () {}, spacerAfter: spacer);
      final groups = DuoVerticalBar.groupsOf([
        action('undo', ToolbarSpacerType.none),
        action('redo', ToolbarSpacerType.flexible),
        action('draw', ToolbarSpacerType.none),
        action('more', ToolbarSpacerType.none),
      ]);
      expect(groups.map((g) => g.map((a) => a.title).toList()).toList(), [
        ['undo', 'redo'],
        ['draw', 'more'],
      ]);
    });

    testWidgets('items that do not fit move into one overflow menu', (
      tester,
    ) async {
      // A short window: the status cluster, four single-item groups and the
      // tab bar cannot all fit.
      tester.view.physicalSize = const Size(951, 330);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(951, 330),
              padding: duoPadding,
              viewPadding: duoPadding,
            ),
            child: Align(
              alignment: Alignment.topRight,
              child: SizedBox(
                width: DuoLayout.bandWidth(duoPadding),
                height: 330,
                child: DuoVerticalBar(
                  actions: [
                    for (final icon in [
                      Icons.add,
                      Icons.share,
                      Icons.edit,
                      Icons.delete,
                    ])
                      AdaptiveAppBarAction(
                        icon: icon,
                        iosSymbol: 'symbol.$icon',
                        label: icon == Icons.delete ? 'Delete' : null,
                        onPressed: () {},
                        spacerAfter: ToolbarSpacerType.fixed,
                      ),
                  ],
                  regions: const [duoCamera],
                ),
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.byIcon(Icons.add), findsOneWidget);
      expect(find.byIcon(Icons.delete), findsNothing);
      expect(find.byIcon(CupertinoIcons.ellipsis), findsOneWidget);

      // The menu names an item by its label; an item without one shows its
      // symbol alone rather than the symbol's identifier.
      final overflow = tester
          .widgetList<IOS26GlassCapsule>(find.byType(IOS26GlassCapsule))
          .firstWhere((c) => c.items.single.menu != null);
      expect(overflow.items.single.menu!.map((e) => e.title), ['', 'Delete']);
      expect(overflow.items.single.menu!.last.symbol, isNotNull);
    });

    testWidgets('the title sits at the leading edge', (tester) async {
      tester.view.physicalSize = duoLandscape;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(
              size: duoLandscape,
              padding: duoPadding,
              viewPadding: duoPadding,
            ),
            child: Align(
              alignment: Alignment.topCenter,
              child: SizedBox(
                height: kDuoTitleBandHeight,
                child: DuoToolbarTitle(title: 'Inbox'),
              ),
            ),
          ),
        ),
      );
      final rect = tester.getRect(find.text('Inbox'));
      expect(rect.left, 20);
      expect(rect.center.dy, closeTo(48, 0.5));
    });
  });
}
