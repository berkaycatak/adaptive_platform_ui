import 'package:adaptive_platform_ui/src/toolbar/duo_vertical_bar.dart';
import 'package:adaptive_platform_ui/src/widgets/adaptive_app_bar_action.dart';
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
    test('the inner display reserves a trailing strip', () {
      expect(DuoLayout.isVerticalBarPose(duoPadding), isTrue);
    });

    test('so does the cover display while folded', () {
      // Same insets as the inner display, measured folded at 466x678.
      expect(DuoLayout.isVerticalBarPose(duoPadding), isTrue);
    });

    test('an ordinary iPhone in portrait has a top inset', () {
      expect(
        DuoLayout.isVerticalBarPose(const EdgeInsets.only(top: 62, bottom: 34)),
        isFalse,
      );
    });

    test('an ordinary iPhone in landscape is inset on both sides', () {
      expect(
        DuoLayout.isVerticalBarPose(
          const EdgeInsets.only(left: 62, right: 62, bottom: 21),
        ),
        isFalse,
      );
    });

    test('an iPad has no trailing inset', () {
      expect(
        DuoLayout.isVerticalBarPose(const EdgeInsets.only(top: 24, bottom: 20)),
        isFalse,
      );
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

    testWidgets('a flexible spacer pushes the rest to the bottom edge', (
      tester,
    ) async {
      tester.view.physicalSize = duoLandscape;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await pumpBar(
        tester,
        DuoVerticalBar(
          actions: [
            AdaptiveAppBarAction(
              icon: Icons.add,
              onPressed: () {},
              spacerAfter: ToolbarSpacerType.flexible,
            ),
            AdaptiveAppBarAction(icon: Icons.share, onPressed: () {}),
          ],
        ),
      );

      final share = tester.getRect(find.byIcon(Icons.share));
      // Stays above the home indicator inset.
      expect(share.bottom, lessThanOrEqualTo(duoLandscape.height - 34));
      expect(share.top, greaterThan(duoLandscape.height / 2));
    });
  });
}
