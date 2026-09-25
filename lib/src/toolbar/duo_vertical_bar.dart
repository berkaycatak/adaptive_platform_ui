import 'dart:ui' show ImageFilter;

import 'package:flutter/cupertino.dart';
import 'package:foldable/foldable.dart';

import '../widgets/adaptive_app_bar_action.dart';
import '../widgets/adaptive_bottom_navigation_bar.dart';
import '../widgets/adaptive_scaffold.dart';
import '../widgets/ios26/ios26_glass_capsule.dart';

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

/// The edge of the window the system reserves for vertical controls.
enum DuoBarSide { left, right }

/// Layout decisions for iPhone Duo.
abstract final class DuoLayout {
  /// The edge toolbar controls and the tab bar belong on right now, or null
  /// where the system keeps horizontal bars.
  ///
  /// Decided from what the system actually reserves rather than from a device
  /// or size class. On iPhone Duo the controls stay aligned with the hardware:
  /// the window has an inset on one side only, with no top inset. That strip
  /// is on the right on the inner display in landscape and on the cover
  /// display in portrait and in one landscape rotation, and on the left in
  /// the other landscape rotation. It is absent where bars stay horizontal:
  ///
  /// * any other iPhone in portrait has a top inset, and in landscape has
  ///   equal insets on both sides;
  /// * an iPad has no side inset;
  /// * the Duo inner display in portrait has a top inset.
  ///
  /// Pass the *view* padding: it is known on the very first frame, and unlike
  /// `padding` it is not consumed by a `SafeArea` further up the tree.
  static DuoBarSide? barSide(EdgeInsets viewPadding) {
    if (viewPadding.top != 0) return null;
    if (viewPadding.right > 0 && viewPadding.left == 0) return DuoBarSide.right;
    if (viewPadding.left > 0 && viewPadding.right == 0) return DuoBarSide.left;
    return null;
  }

  /// Whether toolbar controls belong in a vertical bar right now.
  static bool isVerticalBarPose(EdgeInsets viewPadding) =>
      barSide(viewPadding) != null;

  /// Width of the strip the system reserves on [barSide]. Falls back to
  /// [kDuoVerticalBarWidth] if the inset is ever reported as 0.
  static double stripWidth(EdgeInsets padding) {
    final inset = barSide(padding) == DuoBarSide.left
        ? padding.left
        : padding.right;
    return inset > 0 ? inset : kDuoVerticalBarWidth;
  }

  /// Width of the band the bar is laid out in: the system strip plus
  /// [kDuoVerticalBarBezelInset].
  static double bandWidth(EdgeInsets padding) =>
      stripWidth(padding) + kDuoVerticalBarBezelInset;

  /// Free space to keep above and below the controls, so that they clear the
  /// camera and status cluster wherever the current rotation puts them: at
  /// the top of the strip in portrait, at the bottom of it in one landscape
  /// rotation. Measured on the system's own bar: controls start right at the
  /// edge of a region, and keep [kDuoBarEdgeMargin] from a free window edge.
  static ({double top, double bottom}) barInsets({
    required Size size,
    required EdgeInsets padding,
    required List<ReservedRegion> regions,
  }) {
    final strip = stripWidth(padding);
    final left = barSide(padding) == DuoBarSide.left;
    final stripStart = left ? 0.0 : size.width - strip;
    final stripEnd = left ? strip : size.width;

    // Only regions that really lie in this window's strip count. While the
    // device folds, unfolds or rotates, a reading taken in the previous pose
    // can still be around for a moment; its region sits elsewhere.
    final inStrip = regions.where(
      (r) =>
          r.kind == ReservedRegionKind.occlusion &&
          r.isActive &&
          r.bounds.right > stripStart &&
          r.bounds.left < stripEnd &&
          r.bounds.right <= size.width + 1 &&
          r.bounds.bottom <= size.height + 1,
    );

    double? top;
    double? bottom;
    for (final region in inStrip) {
      if (region.bounds.center.dy < size.height / 2) {
        if (top == null || region.bounds.bottom > top) {
          top = region.bounds.bottom;
        }
      } else {
        final room = size.height - region.bounds.top + kDuoBarRegionGap;
        if (bottom == null || room > bottom) bottom = room;
      }
    }

    // Every pose with a strip has the camera or the status cluster somewhere
    // in it, so an empty strip means nothing has been reported for this pose
    // yet (regions arrive a moment after launch and after a pose change).
    // Until then stay clear of where the cluster can be instead of starting
    // underneath it.
    final unknown = inStrip.isEmpty;
    return (
      top:
          top ??
          (unknown ? kDuoStatusClusterFallbackHeight : kDuoBarEdgeMargin),
      bottom: bottom ?? kDuoBarEdgeMargin,
    );
  }

  /// Top clearance of [barInsets].
  static double topClearance({
    required Size size,
    required EdgeInsets padding,
    required List<ReservedRegion> regions,
  }) => barInsets(size: size, padding: padding, regions: regions).top;
}

/// Space the system leaves between the controls and a free edge of the
/// window, above the first control and below the tab capsule.
const double kDuoBarEdgeMargin = 24.0;

/// Space the system leaves between the controls and a reserved region that
/// sits below them.
const double kDuoBarRegionGap = 11.0;

/// Height of the band at the top of the page that holds the title on iPhone
/// Duo. The system sets the title at the leading edge, centred 48 points
/// below the top, with the controls in the trailing bar instead of beside it.
const double kDuoTitleBandHeight = 70.0;

/// What sits behind the title on iPhone Duo: content scrolling underneath is
/// blurred and faded out towards the top, like the system's scroll edge
/// effect, so the leading-aligned title never reads on top of a list row.
class DuoTitleBackdrop extends StatelessWidget {
  const DuoTitleBackdrop({super.key});

  @override
  Widget build(BuildContext context) {
    final base = CupertinoColors.systemBackground.resolveFrom(context);
    return IgnorePointer(
      child: OverflowBox(
        alignment: Alignment.topCenter,
        maxHeight: kDuoTitleBandHeight + 24,
        minHeight: kDuoTitleBandHeight + 24,
        child: ShaderMask(
          blendMode: BlendMode.dstIn,
          // Solid behind the title, gone just below the band.
          shaderCallback: (rect) => const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: [0.0, 0.62, 1.0],
            colors: [Color(0xFFFFFFFF), Color(0xFFFFFFFF), Color(0x00FFFFFF)],
          ).createShader(rect),
          child: ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
              child: ColoredBox(color: base.withValues(alpha: 0.82)),
            ),
          ),
        ),
      ),
    );
  }
}

/// The page title as iPhone Duo shows it: at the leading edge rather than
/// centred, because the navigation controls live in the trailing bar.
class DuoToolbarTitle extends StatelessWidget {
  const DuoToolbarTitle({super.key, this.title, this.titleWidget});

  final String? title;

  /// Replaces [title] (a custom widget, or a title with a subtitle).
  final Widget? titleWidget;

  @override
  Widget build(BuildContext context) {
    final viewPadding = MediaQuery.viewPaddingOf(context);
    final strip = DuoLayout.stripWidth(viewPadding);
    final onLeft = DuoLayout.barSide(viewPadding) == DuoBarSide.left;
    return Padding(
      padding: EdgeInsets.only(
        left: 20 + (onLeft ? strip : 0),
        right: onLeft ? 20 : strip + 8,
        top: 26,
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child:
            titleWidget ??
            Text(
              title ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.4,
                color: CupertinoColors.label.resolveFrom(context),
              ),
            ),
      ),
    );
  }
}

/// Space between the groups of controls in the bar, as the system leaves it.
const double kDuoBarGroupSpacing = 12.0;

/// Space the system leaves below the tab capsule.
const double kDuoBarBottomMargin = kDuoBarEdgeMargin;

/// The trailing vertical bar used on iPhone Duo, laid out the way the system
/// lays out its own: from the top, below the status cluster, primary
/// navigation (back, close), then the toolbar items, each group in one glass
/// capsule; at the bottom, the tab bar as a capsule of icons.
///
/// This is a Flutter-composed bar rather than a native one: iOS only lays out
/// container-managed bars vertically, never a hand-built UINavigationBar. The
/// capsules themselves are native Liquid Glass.
class DuoVerticalBar extends StatelessWidget {
  const DuoVerticalBar({
    super.key,
    this.leading,
    this.actions = const <AdaptiveAppBarAction>[],
    this.tabBar,
    this.reservedTabs = 0,
    this.tint,
    this.regions = const <ReservedRegion>[],
    this.navigator,
  });

  /// Primary navigation control (back, close), placed first.
  final Widget? leading;

  /// The page's toolbar actions, in order. Consecutive actions share a
  /// capsule; a spacer after an action ([AdaptiveAppBarAction.spacerAfter])
  /// starts a new one, which keeps the groups the top toolbar shows.
  final List<AdaptiveAppBarAction> actions;

  /// The tab bar to show at the bottom of the bar, if any.
  final AdaptiveBottomNavigationBar? tabBar;

  /// Number of tabs to keep room for without drawing them. The fixed chrome
  /// draws the tab bar in a layer of its own, so the layers holding a page's
  /// toolbar items need to know how much of the bar it takes.
  final int reservedTabs;

  /// Tint for the toolbar items.
  final Color? tint;

  /// The page's navigator, for menus opened from a bar above the navigator.
  final NavigatorState? navigator;

  /// Reserved regions reported by the system, used to clear the camera.
  final List<ReservedRegion> regions;

  /// [actions] split into the groups that each get a capsule.
  static List<List<AdaptiveAppBarAction>> groupsOf(
    List<AdaptiveAppBarAction> actions,
  ) {
    final groups = <List<AdaptiveAppBarAction>>[];
    var current = <AdaptiveAppBarAction>[];
    for (final action in actions) {
      current.add(action);
      if (action.spacerAfter != ToolbarSpacerType.none) {
        groups.add(current);
        current = <AdaptiveAppBarAction>[];
      }
    }
    if (current.isNotEmpty) groups.add(current);
    return groups;
  }

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.viewPaddingOf(context);
    final tabs = tabBar?.items ?? const <AdaptiveNavigationDestination>[];
    final insets = DuoLayout.barInsets(
      size: MediaQuery.sizeOf(context),
      padding: padding,
      regions: regions,
    );
    final tabCount = tabs.isNotEmpty ? tabs.length : reservedTabs;
    final tabsHeight = tabCount == 0
        ? 0.0
        : IOS26GlassCapsule.tabsHeight(tabCount) + kDuoBarGroupSpacing;

    return Padding(
      // Safe areas are asymmetric on iPhone Duo; read each edge on its own.
      padding: EdgeInsets.only(top: insets.top, bottom: insets.bottom),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final room = constraints.maxHeight - tabsHeight;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ..._controls(room),
              const Spacer(),
              if (tabs.isNotEmpty)
                SizedBox(
                  width: IOS26GlassCapsule.width,
                  height: IOS26GlassCapsule.tabsHeight(tabs.length),
                  child: IOS26GlassCapsule(
                    items: [
                      for (final tab in tabs)
                        GlassCapsuleItem.fromDestination(tab),
                    ],
                    selectedIndex: tabBar!.selectedIndex ?? 0,
                    inset: IOS26GlassCapsule.tabsInset,
                    tint:
                        tabBar!.selectedItemColor ??
                        CupertinoTheme.of(context).primaryColor,
                    onTap: (index) => tabBar!.onTap?.call(index),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  /// The controls that fit into [room], top to bottom. Toolbar items give way
  /// before the tab bar does, which keeps the primary destinations reachable:
  /// the items that do not fit move, from the bottom up, into one overflow
  /// menu, as the system does. A group can be split, so its first items stay
  /// visible while the rest moves into the menu.
  List<Widget> _controls(double room) {
    final groups = groupsOf(actions);
    final total = actions.length;
    var used = leading == null ? 0.0 : IOS26GlassCapsule.width;
    final overflowCost =
        kDuoBarGroupSpacing + IOS26GlassCapsule.actionsHeight(1);

    final shown = <List<AdaptiveAppBarAction>>[];
    var count = 0;
    outer:
    for (final group in groups) {
      var capsule = <AdaptiveAppBarAction>[];
      for (final action in group) {
        // Growing a capsule costs one more row; starting one costs a whole
        // control plus the gap before it.
        final cost = capsule.isEmpty
            ? (used > 0 ? kDuoBarGroupSpacing : 0.0) + IOS26GlassCapsule.width
            : IOS26GlassCapsule.actionsHeight(capsule.length + 1) -
                  IOS26GlassCapsule.actionsHeight(capsule.length);
        final isLast = count == total - 1;
        // Keep room for the overflow control unless this is the last item.
        if (used + cost + (isLast ? 0 : overflowCost) > room) {
          if (capsule.isNotEmpty) shown.add(capsule);
          break outer;
        }
        used += cost;
        capsule.add(action);
        count++;
      }
      shown.add(capsule);
      capsule = <AdaptiveAppBarAction>[];
    }

    final overflow = actions.skip(count).toList();

    final children = <Widget>[];
    void add(Widget child) {
      if (children.isNotEmpty) {
        children.add(const SizedBox(height: kDuoBarGroupSpacing));
      }
      children.add(child);
    }

    if (leading != null) add(leading!);
    for (final group in shown) {
      if (group.isNotEmpty) add(_ActionCapsule(actions: group, tint: tint));
    }
    if (overflow.isNotEmpty) {
      add(_OverflowCapsule(actions: overflow, navigator: navigator));
    }
    return children;
  }
}

/// The items that did not fit, behind the system's ellipsis menu.
class _OverflowCapsule extends StatelessWidget {
  const _OverflowCapsule({required this.actions, this.navigator});

  final List<AdaptiveAppBarAction> actions;
  final NavigatorState? navigator;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: IOS26GlassCapsule.width,
      height: IOS26GlassCapsule.actionsHeight(1),
      child: IOS26GlassCapsule(
        items: [
          GlassCapsuleItem(
            symbol: 'ellipsis',
            label: 'More',
            fallback: const Icon(CupertinoIcons.ellipsis, size: 22),
            menu: [
              for (var i = 0; i < actions.length; i++)
                GlassCapsuleMenuEntry(
                  id: i,
                  // Without a name the entry shows its symbol alone; a
                  // symbol's identifier is not something to show a person.
                  title: actions[i].effectiveLabel ?? '',
                  symbol: actions[i].iosSymbol,
                ),
            ],
          ),
        ],
        onTap: (_) {},
        // Menus can't nest in the overflow menu, so they open as action sheets
        onMenuTap: (id) {
          if (id >= 0 && id < actions.length) {
            actions[id].press(context, navigator: navigator);
          }
        },
      ),
    );
  }
}

/// One group of toolbar items in one capsule.
class _ActionCapsule extends StatelessWidget {
  const _ActionCapsule({required this.actions, this.tint});

  /// Menu entry id offset per action, as a capsule has one onMenuTap
  static const int _menuIdStride = 1000;

  final List<AdaptiveAppBarAction> actions;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: IOS26GlassCapsule.width,
      height: IOS26GlassCapsule.actionsHeight(actions.length),
      child: IOS26GlassCapsule(
        items: [
          for (var i = 0; i < actions.length; i++)
            GlassCapsuleItem.fromAction(
              actions[i],
              menuIdBase: i * _menuIdStride,
            ),
        ],
        tint: tint,
        onTap: (index) => actions[index].onPressed(),
        onMenuTap: (id) {
          final index = id ~/ _menuIdStride;
          if (index >= 0 && index < actions.length) {
            actions[index].selectMenuItem(id % _menuIdStride);
          }
        },
      ),
    );
  }
}

/// The back button of the trailing bar: one round glass control.
class DuoBarBackButton extends StatelessWidget {
  const DuoBarBackButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: IOS26GlassCapsule.width,
      height: IOS26GlassCapsule.width,
      child: IOS26GlassCapsule(
        items: const [
          GlassCapsuleItem(
            symbol: 'chevron.left',
            label: 'Back',
            fallback: Icon(CupertinoIcons.chevron_left, size: 22),
          ),
        ],
        onTap: (_) => onPressed(),
      ),
    );
  }
}
