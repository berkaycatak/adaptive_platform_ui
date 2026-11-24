import 'package:flutter/widgets.dart';

import 'adaptive_app_bar_action.dart';
import 'adaptive_scaffold.dart';
import 'ios26/ios26_glass_capsule.dart';

/// [capsule] with an empty, untouchable box keyed with each of [keys] over
/// its cells, which the capsule spreads evenly between its insets: for a menu
/// that opens beside a cell, or a guided tour, to find where it is.
Widget _withAnchors(Widget capsule, List<Key>? keys, {double inset = 0}) {
  if (keys == null) return capsule;
  return Stack(
    fit: StackFit.expand,
    children: [
      capsule,
      IgnorePointer(
        child: ExcludeSemantics(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: inset),
            child: Column(
              children: [
                for (final key in keys)
                  Expanded(child: SizedBox.expand(key: key)),
              ],
            ),
          ),
        ),
      ),
    ],
  );
}

/// A column of tabs in one Liquid Glass capsule, the selected one highlighted
/// (it can be taken and dragged to another tab), as the iPhone Duo bar shows
/// them: the building block of [AdaptiveNavigationRail], for an app that lays
/// its side controls out itself.
///
/// It is the native view on iOS 26 unless [native] is off, and a capsule drawn
/// by Flutter, with the same size and cells, otherwise.
class AdaptiveTabCapsule extends StatelessWidget {
  const AdaptiveTabCapsule({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
    this.showLabels = false,
    this.expandOnLensDrag = false,
    this.tint,
    this.native = true,
    this.destinationKeys,
    this.fallbackIcons,
    this.itemExtent,
  }) : assert(
         destinationKeys == null ||
             destinationKeys.length == destinations.length,
       ),
       assert(
         fallbackIcons == null || fallbackIcons.length == destinations.length,
       );

  /// The tabs, top to bottom; SF Symbol names, [IconData] and
  /// [ImageProvider]s work as icons.
  final List<AdaptiveNavigationDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  /// Whether each tab shows its label under its icon.
  final bool showLabels;

  /// Whether the capsule grows, and shows the labels, while the selected tab's
  /// lens is held, as the vertical tab bar of the iPhone Duo does (see
  /// [IOS26GlassCapsule.expandOnLensDrag]). Its place keeps this size.
  final bool expandOnLensDrag;

  /// Tint of the selected tab.
  final Color? tint;

  /// Whether the capsule is the native view (see [IOS26GlassCapsule.native]).
  final bool native;

  /// One key per tab, on an empty box over its cell.
  final List<Key>? destinationKeys;

  /// What the capsule drawn by Flutter shows for each tab, in place of an SF
  /// Symbol it cannot draw.
  final List<Widget>? fallbackIcons;

  /// Height of one tab, for a column with its own measure; by default the
  /// one the system's bar uses.
  final double? itemExtent;

  static double widthFor({bool showLabels = false}) =>
      showLabels ? IOS26GlassCapsule.labeledWidth : IOS26GlassCapsule.width;

  static double heightFor(
    int count, {
    bool showLabels = false,
    double? itemExtent,
  }) => itemExtent != null
      ? count * itemExtent + 2 * IOS26GlassCapsule.tabsInset
      : showLabels
      ? IOS26GlassCapsule.labeledTabsHeight(count)
      : IOS26GlassCapsule.tabsHeight(count);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widthFor(showLabels: showLabels),
      height: heightFor(
        destinations.length,
        showLabels: showLabels,
        itemExtent: itemExtent,
      ),
      child: _withAnchors(
        IOS26GlassCapsule(
          items: [
            for (var i = 0; i < destinations.length; i++)
              GlassCapsuleItem.fromDestination(
                destinations[i],
                fallback: fallbackIcons?[i],
              ),
          ],
          selectedIndex: selectedIndex,
          inset: IOS26GlassCapsule.tabsInset,
          showLabels: showLabels,
          expandOnLensDrag: expandOnLensDrag,
          tint: tint,
          native: native,
          onTap: onDestinationSelected,
        ),
        destinationKeys,
        inset: IOS26GlassCapsule.tabsInset,
      ),
    );
  }
}

/// A column of controls in one Liquid Glass capsule, as the iPhone Duo bar
/// groups toolbar items: the actions at the foot of [AdaptiveNavigationRail].
/// They take a [AdaptiveAppBarAction.badgeCount] and an
/// [AdaptiveAppBarAction.iconImage] (a round avatar), as on the toolbar.
class AdaptiveActionCapsule extends StatelessWidget {
  const AdaptiveActionCapsule({
    super.key,
    required this.actions,
    this.actionKeys,
    this.native = true,
    this.width = IOS26GlassCapsule.width,
    this.itemExtent,
  }) : assert(actionKeys == null || actionKeys.length == actions.length);

  final List<AdaptiveAppBarAction> actions;

  /// One key per action, on an empty box over its cell.
  final List<Key>? actionKeys;

  /// Whether the capsule is the native view (see [IOS26GlassCapsule.native]).
  final bool native;

  final double width;

  /// Height of one control, for a column with its own measure; by default the
  /// one the system's bar uses.
  final double? itemExtent;

  static double heightFor(int count, {double? itemExtent}) => itemExtent != null
      ? count * itemExtent
      : IOS26GlassCapsule.actionsHeight(count);

  @override
  Widget build(BuildContext context) {
    // Each action's menu entries come back as `index * menuStride + entry`.
    const menuStride = 1000;
    return SizedBox(
      width: width,
      height: heightFor(actions.length, itemExtent: itemExtent),
      child: _withAnchors(
        IOS26GlassCapsule(
          items: [
            for (var i = 0; i < actions.length; i++)
              GlassCapsuleItem.fromAction(
                actions[i],
                menuIdBase: i * menuStride,
              ),
          ],
          native: native,
          onTap: (i) => actions[i].press(context),
          onMenuTap: (id) =>
              actions[id ~/ menuStride].selectMenuItem(id % menuStride),
        ),
        actionKeys,
      ),
    );
  }
}
