import 'package:adaptive_platform_ui/src/platform/system_vertical_bar.dart';
import 'package:adaptive_platform_ui/src/toolbar/duo_vertical_bar.dart';
import 'package:adaptive_platform_ui/src/widgets/adaptive_app_bar_action.dart';
import 'package:adaptive_platform_ui/src/widgets/ios26/ios26_glass_capsule.dart';
import 'package:adaptive_platform_ui/src/widgets/ios26/ios26_popup_menu_button.dart';
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

/// Split View on the inner display, measured on the iOS 27.1 simulator.
const Size duoSplitPane = Size(469, 669);
const EdgeInsets duoLeftPanePadding = EdgeInsets.only(bottom: 34); // leading
const EdgeInsets duoRightPanePadding = EdgeInsets.only(
  right: 84,
  bottom: 34,
); // trailing

/// The pose the insets alone resolve to, which is what a window with no
/// system reading gets.
DuoPose poseOf(EdgeInsets padding) =>
    DuoLayout.resolvePose(padding, SystemVerticalBarEdge.unknown)!;

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

    test('a left inset is handled by the inset fallback', () {
      // Not a pose seen on hardware or in the simulator (both landscape
      // rotations put the strip on the right); kept as the fallback.
      const rotated = EdgeInsets.only(left: 84, bottom: 34);
      expect(DuoLayout.barSide(rotated), DuoBarSide.left);
      expect(poseOf(rotated).stripWidth, 84);
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

  group('DuoLayout.resolvePose', () {
    test(
      'leading Split View pane: the system edge alone puts the bar on the left',
      () {
        final pose = DuoLayout.resolvePose(
          duoLeftPanePadding,
          SystemVerticalBarEdge.left,
        )!;
        expect(pose.side, DuoBarSide.left);
        expect(pose.stripWidth, kDuoVerticalBarWidth);
        expect(pose.reservedBySystem, isFalse);
      },
    );

    test('the insets win over a stale edge after a pane move', () {
      // The edge arrives on its own channel and can still say "left" for a
      // frame after the window moved to the trailing pane.
      final pose = DuoLayout.resolvePose(
        duoRightPanePadding,
        SystemVerticalBarEdge.left,
      )!;
      expect(pose.side, DuoBarSide.right);
      expect(pose.stripWidth, 84);
      expect(pose.reservedBySystem, isTrue);
    });

    test('trailing Split View pane: the strip is the system inset', () {
      for (final edge in [
        SystemVerticalBarEdge.right,
        SystemVerticalBarEdge.unknown,
      ]) {
        final pose = DuoLayout.resolvePose(duoRightPanePadding, edge)!;
        expect(pose.side, DuoBarSide.right);
        expect(pose.stripWidth, 84);
        expect(pose.reservedBySystem, isTrue);
      }
    });

    test('without a system reading the insets still decide', () {
      expect(
        DuoLayout.resolvePose(duoPadding, SystemVerticalBarEdge.unknown)!.side,
        DuoBarSide.right,
      );
      expect(
        DuoLayout.resolvePose(
          duoLeftPanePadding,
          SystemVerticalBarEdge.unknown,
        ),
        isNull,
      );
    });

    test('"none" never removes a pose the insets find', () {
      expect(
        DuoLayout.resolvePose(duoPadding, SystemVerticalBarEdge.none),
        isNotNull,
      );
    });

    test('an ordinary iPhone or iPad stays horizontal', () {
      const iPhonePortrait = EdgeInsets.only(top: 62, bottom: 34);
      const iPhoneLandscape = EdgeInsets.only(left: 62, right: 62, bottom: 21);
      const iPad = EdgeInsets.only(top: 24, bottom: 20);
      for (final padding in [iPhonePortrait, iPhoneLandscape, iPad]) {
        for (final edge in [
          SystemVerticalBarEdge.none,
          SystemVerticalBarEdge.unknown,
        ]) {
          expect(DuoLayout.resolvePose(padding, edge), isNull);
        }
      }
    });

    test('the wire format maps to a physical edge, unknown otherwise', () {
      expect(
        SystemVerticalBarEdge.fromWire('left'),
        SystemVerticalBarEdge.left,
      );
      expect(
        SystemVerticalBarEdge.fromWire('right'),
        SystemVerticalBarEdge.right,
      );
      expect(
        SystemVerticalBarEdge.fromWire('none'),
        SystemVerticalBarEdge.none,
      );
      expect(
        SystemVerticalBarEdge.fromWire('unsupported'),
        SystemVerticalBarEdge.unknown,
      );
      expect(
        SystemVerticalBarEdge.fromWire(null),
        SystemVerticalBarEdge.unknown,
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
          pose: poseOf(duoPadding),
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

    test(
      'inset fallback, strip left: the camera is at the top of the strip',
      () {
        // The left-inset pose was not observed on hardware or in the simulator.
        final insets = DuoLayout.barInsets(
          size: coverLandscape,
          pose: poseOf(const EdgeInsets.only(left: 84, bottom: 34)),
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
      },
    );

    test('a bar-only strip keeps edge margins and ignores regions', () {
      final insets = DuoLayout.barInsets(
        size: duoSplitPane,
        pose: const DuoPose(
          side: DuoBarSide.left,
          stripWidth: 84,
          reservedBySystem: false,
        ),
        regions: const [],
      );
      // Not kDuoStatusClusterFallbackHeight: no region will ever arrive.
      expect(insets.top, kDuoBarOnlyTopMargin);
      expect(insets.bottom, kDuoBarEdgeMargin);

      // Even a region in the strip (a stale reading from another pose) does
      // not move the bar.
      final withRegion = DuoLayout.barInsets(
        size: duoSplitPane,
        pose: const DuoPose(
          side: DuoBarSide.left,
          stripWidth: 84,
          reservedBySystem: false,
        ),
        regions: const [
          ReservedRegion(
            kind: ReservedRegionKind.occlusion,
            bounds: Rect.fromLTRB(0, 0, 84, 120),
            isActive: true,
          ),
        ],
      );
      expect(withRegion, insets);
    });
  });

  group('DuoLayout: geometry', () {
    test('the bar takes the strip the system reserves', () {
      expect(poseOf(duoPadding).stripWidth, 84);
      expect(poseOf(duoPadding).bandWidth, 84 + kDuoVerticalBarBezelInset);
    });

    test('falls back when no inset is reported on the bar side', () {
      final pose = DuoLayout.resolvePose(
        EdgeInsets.zero,
        SystemVerticalBarEdge.right,
      )!;
      expect(pose.stripWidth, kDuoVerticalBarWidth);
      expect(kDuoVerticalBarWidth, 84);
    });

    test('controls start below the camera, not under it', () {
      expect(
        DuoLayout.topClearance(
          size: duoLandscape,
          pose: poseOf(duoPadding),
          regions: const [duoCamera, duoFlatFold],
        ),
        120,
      );
    });

    test('on the cover display too', () {
      expect(
        DuoLayout.topClearance(
          size: duoCover,
          pose: poseOf(duoPadding),
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
          pose: poseOf(duoPadding),
          regions: const [duoCamera],
        ),
        kDuoStatusClusterFallbackHeight,
      );
    });

    test('stays clear of the cluster until regions are reported', () {
      expect(
        DuoLayout.topClearance(
          size: duoLandscape,
          pose: poseOf(duoPadding),
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
          pose: poseOf(const EdgeInsets.only(right: 84)),
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
                width: poseOf(duoPadding).bandWidth,
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
                width: poseOf(duoPadding).bandWidth,
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

    testWidgets('an action\'s menu is a native menu in its capsule', (
      tester,
    ) async {
      final selected = <(String, int)>[];
      AdaptiveAppBarAction action(String name) => AdaptiveAppBarAction(
        iosSymbol: 'symbol.$name',
        menuItems: const [
          AdaptivePopupMenuItem(label: 'First', icon: 'eye'),
          AdaptivePopupMenuDivider(),
          AdaptivePopupMenuItem(label: 'Second'),
        ],
        onMenuItemSelected: (index, _) => selected.add((name, index)),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(951, 669),
              padding: duoPadding,
              viewPadding: duoPadding,
            ),
            child: Align(
              alignment: Alignment.topRight,
              child: SizedBox(
                width: DuoLayout.resolvePose(
                  duoPadding,
                  SystemVerticalBarEdge.unknown,
                )!.bandWidth,
                height: 669,
                child: DuoVerticalBar(
                  actions: [action('a'), action('b')],
                  regions: const [duoCamera],
                ),
              ),
            ),
          ),
        ),
      );

      final capsule = tester
          .widgetList<IOS26GlassCapsule>(find.byType(IOS26GlassCapsule))
          .firstWhere((c) => c.items.length == 2);
      expect(capsule.items.first.menu!.map((e) => e.title), [
        'First',
        'Second',
      ]);
      expect(capsule.items.first.menu!.first.symbol, 'eye');

      // Ids tell the actions apart and keep the index into menuItems.
      capsule.onMenuTap!(capsule.items.last.menu!.last.id);
      expect(selected, [('b', 2)]);
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
