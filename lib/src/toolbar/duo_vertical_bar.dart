import 'package:flutter/cupertino.dart';
import 'package:foldable/foldable.dart';

import '../style/sf_symbol.dart';
import '../widgets/adaptive_app_bar_action.dart';
import '../widgets/adaptive_button.dart';

/// Fallback width of the trailing vertical control bar on the iPhone Duo inner
/// display, used only if the system reports no trailing safe-area inset. The
/// bar normally takes the width of that inset (`padding.right`), which is the
/// strip iOS reserves for its own vertical bars and status cluster.
const double kDuoVerticalBarWidth = 60.0;

/// How far the control band extends inward beyond the system strip, so the
/// centred controls sit a few points off the bezel instead of hugging the
/// display edge.
const double kDuoVerticalBarBezelInset = 12.0;

/// Layout decisions for the iPhone Duo inner display.
abstract final class DuoLayout {
  /// True on the inner display of an iPhone Duo.
  ///
  /// Branches on the size classes iOS itself lays out from: a regular
  /// horizontal *and* vertical size class is unique to the Duo inner display
  /// among iPhones (the cover display is compact width; a Plus/Max in
  /// landscape is regular width but compact height). This mirrors how the
  /// system moves its own bars to the side there.
  ///
  /// `isFoldable` is deliberately not required: it is derived from the hinge
  /// API, whose status arrives asynchronously after the first snapshot (the
  /// initial value is `unknown`, then the stream reports e.g. `fullyOpen`).
  /// Requiring it would lay controls out at the top on the first frames and
  /// jump them to the side a moment later; the size classes are correct at
  /// once.
  ///
  /// Known gap: an iPad is also regular/regular and cannot be told apart by
  /// size class alone; exposing the interface idiom from `foldable` would
  /// close this.
  static bool isInnerDisplay(FoldableData? fold) {
    if (fold == null) return false;
    return fold.horizontalSizeClass == SizeClass.regular &&
        fold.verticalSizeClass == SizeClass.regular;
  }

  /// Whether toolbar controls belong in the trailing vertical bar right now.
  ///
  /// iOS keeps horizontal bars on the inner display in portrait and only
  /// moves controls to the side while the display is wider than tall, so the
  /// decision depends on the pose, not just on the display.
  static bool isVerticalBarPose(FoldableData? fold, Size size) =>
      isInnerDisplay(fold) && size.width > size.height;

  /// Width of the trailing strip the system reserves on the inner display
  /// (its status cluster lives there, so `padding.right` is non-zero while
  /// `padding.top` is 0). The vertical bar sits inside that strip, which is
  /// also where iOS places its own vertical bars. Falls back to
  /// [kDuoVerticalBarWidth] if the inset is ever reported as 0.
  static double stripWidth(EdgeInsets padding) =>
      padding.right > 0 ? padding.right : kDuoVerticalBarWidth;

  /// Width of the band the bar is laid out in: the system strip plus
  /// [kDuoVerticalBarBezelInset].
  static double bandWidth(EdgeInsets padding) =>
      stripWidth(padding) + kDuoVerticalBarBezelInset;

  /// Top clearance for the vertical bar: below any active occlusion region
  /// (the under-display camera / status cluster) that overlaps the trailing
  /// strip, so controls never sit under the camera the way they would under
  /// the plain top safe-area inset (which is 0 on this display).
  static double topClearance({
    required Size size,
    required EdgeInsets padding,
    required List<ReservedRegion> regions,
  }) {
    final stripLeft = size.width - stripWidth(padding);
    var clearance = padding.top;
    for (final region in regions) {
      if (region.kind == ReservedRegionKind.occlusion &&
          region.isActive &&
          region.bounds.right > stripLeft &&
          region.bounds.bottom > clearance) {
        clearance = region.bounds.bottom;
      }
    }
    return clearance;
  }
}

/// The trailing vertical bar used on the iPhone Duo inner display. It holds
/// the controls a top toolbar would otherwise show, ordered top to bottom the
/// way the system orders its own vertical bar: primary navigation (back)
/// first, then the actions in their original grouping.
///
/// This is a Flutter-composed bar rather than a native one: iOS only lays out
/// container-managed bars vertically, never a hand-built UINavigationBar. The
/// controls themselves are still native glass buttons.
class DuoVerticalBar extends StatelessWidget {
  const DuoVerticalBar({
    super.key,
    this.leading,
    this.actions = const <AdaptiveAppBarAction>[],
    this.regions = const <ReservedRegion>[],
  });

  /// Primary navigation control (back, close), placed first.
  final Widget? leading;

  /// The page's toolbar actions, in order.
  final List<AdaptiveAppBarAction> actions;

  /// Reserved regions reported by the system, used to clear the camera.
  final List<ReservedRegion> regions;

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.paddingOf(context);

    final children = <Widget>[];
    if (leading != null) {
      children.add(leading!);
      children.add(const SizedBox(height: 12));
    }
    for (final action in actions) {
      children.add(_DuoBarAction(action: action));
      switch (action.spacerAfter) {
        case ToolbarSpacerType.flexible:
          children.add(const Spacer());
        case ToolbarSpacerType.fixed:
          children.add(const SizedBox(height: 12));
        case ToolbarSpacerType.none:
          children.add(const SizedBox(height: 8));
      }
    }

    return Padding(
      // Safe areas are asymmetric on iPhone Duo; read each edge on its own.
      padding: EdgeInsets.only(
        top:
            DuoLayout.topClearance(
              size: MediaQuery.sizeOf(context),
              padding: padding,
              regions: regions,
            ) +
            8,
        bottom: padding.bottom + 8,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: children,
      ),
    );
  }
}

/// One control in the Duo vertical bar. A narrow, tall bar favours the
/// icon-only representation, so prefer the SF Symbol (the iOS 26 form), then
/// a custom icon widget or IconData, and fall back to the title text.
class _DuoBarAction extends StatelessWidget {
  const _DuoBarAction({required this.action});

  final AdaptiveAppBarAction action;

  @override
  Widget build(BuildContext context) {
    final Widget child;
    if (action.iosSymbol != null) {
      child = AdaptiveButton.sfSymbol(
        onPressed: action.onPressed,
        sfSymbol: SFSymbol(action.iosSymbol!, size: 20),
      );
    } else if (action.iconWidget != null) {
      child = CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: action.onPressed,
        child: action.iconWidget!,
      );
    } else if (action.icon != null) {
      child = CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: action.onPressed,
        child: Icon(action.icon, size: 22),
      );
    } else {
      child = CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: action.onPressed,
        child: Text(action.title ?? '', style: const TextStyle(fontSize: 12)),
      );
    }
    return SizedBox(height: 38, width: 38, child: child);
  }
}
