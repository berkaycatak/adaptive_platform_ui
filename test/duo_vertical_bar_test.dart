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

FoldableData fold(SizeClass horizontal, SizeClass vertical) => FoldableData(
  capabilities: FoldableData.unsupported.capabilities,
  status: FoldableData.unsupported.status,
  angleDegrees: FoldableData.unsupported.angleDegrees,
  regions: const [duoCamera, duoFlatFold],
  displayFeatures: const [],
  horizontalSizeClass: horizontal,
  verticalSizeClass: vertical,
);

void main() {
  group('DuoLayout: detection', () {
    test('no snapshot yet means not the inner display', () {
      expect(DuoLayout.isInnerDisplay(null), isFalse);
      expect(DuoLayout.isVerticalBarPose(null, duoLandscape), isFalse);
    });

    test('regular/regular is the inner display, before the hinge reports', () {
      final data = fold(SizeClass.regular, SizeClass.regular);
      expect(data.status, FoldableData.unsupported.status);
      expect(DuoLayout.isInnerDisplay(data), isTrue);
    });

    test('a Plus/Max in landscape (regular/compact) is not', () {
      expect(
        DuoLayout.isInnerDisplay(fold(SizeClass.regular, SizeClass.compact)),
        isFalse,
      );
    });

    test('the cover display (compact/regular) is not', () {
      expect(
        DuoLayout.isInnerDisplay(fold(SizeClass.compact, SizeClass.regular)),
        isFalse,
      );
    });

    test('the inner display keeps horizontal bars in portrait', () {
      final data = fold(SizeClass.regular, SizeClass.regular);
      expect(DuoLayout.isVerticalBarPose(data, duoLandscape), isTrue);
      expect(DuoLayout.isVerticalBarPose(data, duoLandscape.flipped), isFalse);
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
          padding: const EdgeInsets.only(top: 20, right: 84),
          regions: const [inactive, leftSide, duoFlatFold],
        ),
        20,
      );
    });
  });

  group('DuoVerticalBar', () {
    Future<void> pumpBar(WidgetTester tester, DuoVerticalBar bar) {
      return tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: duoLandscape, padding: duoPadding),
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
