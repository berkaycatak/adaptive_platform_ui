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

/// Clearance used below the top edge until the system has reported where the
/// camera and status cluster are. It covers the taller of the two displays, so
/// controls never start out underneath the cluster.
const double kDuoStatusClusterFallbackHeight = 170.0;

/// Layout decisions for iPhone Duo.
abstract final class DuoLayout {
  /// Whether toolbar controls belong in a trailing vertical bar right now.
  ///
  /// Decided from what the system actually reserves rather than from a device
  /// or size class: on iPhone Duo the status cluster lives in a strip on the
  /// trailing edge, so the window has a trailing inset while its leading and
  /// top insets are zero. That holds on the inner display (regular/regular)
  /// and on the cover display while folded (compact/regular), which size
  /// classes cannot tell apart from an ordinary iPhone. It is false where the
  /// system keeps horizontal bars:
  ///
  /// * any other iPhone in portrait has a top inset, and in landscape has
  ///   equal leading and trailing insets;
  /// * an iPad has no trailing inset;
  /// * a Duo pose that puts the status bar back on top has a top inset.
  ///
  /// Pass the *view* padding: it is known on the very first frame, and unlike
  /// `padding` it is not consumed by a `SafeArea` further up the tree.
  static bool isVerticalBarPose(EdgeInsets viewPadding) =>
      viewPadding.right > 0 && viewPadding.left == 0 && viewPadding.top == 0;

  /// Width of the trailing strip the system reserves (its status cluster
  /// lives there, so the trailing inset is non-zero while the top one is 0). The vertical bar sits inside that strip, which is
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
    var found = false;
    for (final region in regions) {
      // Only regions that really lie in this window's trailing strip count.
      // While the device folds or unfolds, a reading taken on the other
      // display can still be around for a moment; its region sits outside
      // this window and would put the bar at that display's height.
      final inStrip =
          region.kind == ReservedRegionKind.occlusion &&
          region.isActive &&
          region.bounds.right > stripLeft &&
          region.bounds.left < size.width &&
          region.bounds.right <= size.width + 1;
      if (!inStrip) continue;
      found = true;
      if (region.bounds.bottom > clearance) clearance = region.bounds.bottom;
    }
    // Regions arrive a moment after launch; until then stay clear of where
    // the cluster can be instead of starting underneath it.
    if (!found && clearance < kDuoStatusClusterFallbackHeight) {
      return kDuoStatusClusterFallbackHeight;
    }
    return clearance;
  }
}

/// The trailing vertical bar used on iPhone Duo. It holds
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
    final padding = MediaQuery.viewPaddingOf(context);

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
