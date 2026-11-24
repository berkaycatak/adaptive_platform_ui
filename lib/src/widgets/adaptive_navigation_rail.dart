import 'package:flutter/material.dart';

import '../platform/platform_info.dart';
import 'adaptive_app_bar_action.dart';
import 'adaptive_glass_capsules.dart';
import 'adaptive_scaffold.dart';
import 'ios26/ios26_glass_capsule.dart';

/// How an [AdaptiveNavigationRail] fits the height it has: whether the
/// destinations keep their labels, and whether the actions fold into one
/// control that opens a menu of them.
typedef RailPlan = ({bool showLabels, bool foldActions});

/// A vertical navigation bar along the leading edge, for windows wide enough
/// to give one: an iPad, a phone turned sideways.
///
/// - **iOS 26+**: native Liquid Glass. The destinations are one glass capsule,
///   with the selected one highlighted (it can be taken and dragged to another
///   destination) and, by default, its label under each icon; the [actions]
///   are a second capsule at the foot. Both are the capsules of the iPhone Duo
///   bar ([IOS26GlassCapsule]), laid out by the app instead of the system.
/// - **Everywhere else**: a Material [NavigationRail], with the [actions] at
///   its foot.
///
/// UIKit has no vertical tab bar outside a split view's sidebar, so this is
/// the closest native material for a rail drawn by a Flutter app.
class AdaptiveNavigationRail extends StatelessWidget {
  const AdaptiveNavigationRail({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
    this.actions = const [],
    this.showLabels = true,
    this.tint,
    this.margin = defaultMargin,
    this.leading,
    this.leadingExtent = 0,
    this.footer,
    this.footerExtent = 0,
    this.destinationKeys,
    this.actionKeys,
    this.native = true,
    this.destinationFallbackIcons,
  }) : assert(
         destinationKeys == null ||
             destinationKeys.length == destinations.length,
       ),
       assert(actionKeys == null || actionKeys.length == actions.length);

  /// The destinations, top to bottom. SF Symbol names, [IconData] and
  /// [ImageProvider]s work as icons, as in [AdaptiveBottomNavigationBar].
  final List<AdaptiveNavigationDestination> destinations;

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  /// Controls at the foot of the rail, such as notifications or the profile.
  /// They take a [AdaptiveAppBarAction.badgeCount] and an
  /// [AdaptiveAppBarAction.iconImage] (shown as a round avatar) as on the
  /// toolbar.
  final List<AdaptiveAppBarAction> actions;

  /// Whether each destination shows its label under its icon. Without them
  /// the rail is as narrow as the iPhone Duo bar, and the labels are only read
  /// by VoiceOver.
  final bool showLabels;

  /// Tint of the selected destination.
  final Color? tint;

  /// Space between the capsules and the window's edges.
  final double margin;

  /// A widget above the destinations, such as the app's logo, given at least
  /// [leadingExtent] of height (what [planFor] counts).
  final Widget? leading;
  final double leadingExtent;

  /// A widget above the actions, given at least [footerExtent] of height (what
  /// [planFor] counts): for a control that has to stay a Flutter widget.
  final Widget? footer;
  final double footerExtent;

  /// One key per destination, placed on an empty box over its cell (on the
  /// Material rail, on its icon): for a menu that opens beside a destination,
  /// or a guided tour, to find where it is.
  final List<Key>? destinationKeys;

  /// The same for the [actions]. While they are folded into one control (see
  /// [planFor]) there is no cell to put them on, and they are left out.
  final List<Key>? actionKeys;

  /// Whether the capsules are native views. Off, they are drawn by Flutter
  /// with the same layout, for a moment when a native view would be wrong
  /// (under another route or a dimming overlay, in a hero flight).
  final bool native;

  /// What the capsules drawn by Flutter show for each destination, in place of
  /// an SF Symbol they cannot draw.
  final List<Widget>? destinationFallbackIcons;

  /// Default for [margin].
  static const double defaultMargin = 12;

  /// Forces the glass rail (true) or the Material one (false) regardless of
  /// the platform, for tests.
  @visibleForTesting
  static bool? debugForceGlass;

  /// Width the glass rail takes, margins included.
  static double widthFor({
    bool showLabels = true,
    double margin = defaultMargin,
  }) =>
      (showLabels ? IOS26GlassCapsule.labeledWidth : IOS26GlassCapsule.width) +
      margin * 2;

  /// Least space kept between the destinations and what is below them.
  static const double _gap = 8;

  /// How the rail fits a column [height] tall, of which [fixedExtent] is
  /// taken by other things (a leading widget, a footer): as asked for when
  /// there is room; otherwise without labels; then with the actions folded
  /// into one control that opens a menu of them (a phone turned sideways is
  /// about 345 pt tall once the safe area and margins are taken).
  static RailPlan planFor({
    required double height,
    required int destinationCount,
    required int actionCount,
    required bool showLabels,
    double fixedExtent = 0,
  }) {
    double tabs(bool labels) => labels
        ? IOS26GlassCapsule.labeledTabsHeight(destinationCount)
        : IOS26GlassCapsule.tabsHeight(destinationCount);
    double foot(bool fold) => actionCount == 0
        ? 0
        : _gap + IOS26GlassCapsule.actionsHeight(fold ? 1 : actionCount);

    final options = <RailPlan>[
      (showLabels: showLabels, foldActions: false),
      if (showLabels) (showLabels: false, foldActions: false),
      if (actionCount > 1) ...[
        (showLabels: showLabels, foldActions: true),
        if (showLabels) (showLabels: false, foldActions: true),
      ],
    ];
    for (final option in options) {
      if (fixedExtent + tabs(option.showLabels) + foot(option.foldActions) <=
          height) {
        return option;
      }
    }
    return options.last;
  }

  bool get _useGlass => debugForceGlass ?? PlatformInfo.isIOS26OrHigher();

  @override
  Widget build(BuildContext context) {
    if (_useGlass) return _buildGlass(context);
    return _buildMaterial(context);
  }

  Widget _buildGlass(BuildContext context) {
    // The folded actions come back as `foldedId + index`.
    const foldedId = 1000000;
    final hasFooter = footer != null;

    return SafeArea(
      right: false,
      child: Padding(
        padding: EdgeInsets.all(margin),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final plan = planFor(
              height: constraints.maxHeight,
              destinationCount: destinations.length,
              actionCount: actions.length,
              showLabels: showLabels,
              fixedExtent:
                  (leading == null ? 0 : leadingExtent) +
                  (hasFooter ? footerExtent + _gap : 0),
            );
            final width = AdaptiveTabCapsule.widthFor(
              showLabels: plan.showLabels,
            );
            final badges = actions.fold<int>(
              0,
              (sum, action) => sum + (action.badgeCount ?? 0),
            );

            return SizedBox(
              width: width,
              child: Column(
                children: [
                  // The extents are what the plan counts; a leading widget or a
                  // footer a little taller (larger text) still gets its room.
                  if (leading != null)
                    ConstrainedBox(
                      constraints: BoxConstraints(minHeight: leadingExtent),
                      child: Center(heightFactor: 1, child: leading),
                    ),
                  AdaptiveTabCapsule(
                    destinations: destinations,
                    selectedIndex: selectedIndex,
                    onDestinationSelected: onDestinationSelected,
                    showLabels: plan.showLabels,
                    tint: tint,
                    native: native,
                    destinationKeys: destinationKeys,
                    fallbackIcons: destinationFallbackIcons,
                  ),
                  const Spacer(),
                  if (hasFooter) ...[
                    ConstrainedBox(
                      constraints: BoxConstraints(minHeight: footerExtent),
                      child: Center(heightFactor: 1, child: footer),
                    ),
                    const SizedBox(height: _gap),
                  ],
                  if (actions.isNotEmpty && plan.foldActions)
                    // One round button, whatever the width of the capsules
                    // above it (labeled tabs are wider than the action cells).
                    SizedBox(
                      width: IOS26GlassCapsule.width,
                      height: AdaptiveActionCapsule.heightFor(1),
                      child: IOS26GlassCapsule(
                        items: [
                          GlassCapsuleItem(
                            symbol: 'ellipsis',
                            label: 'More',
                            badge: badges,
                            fallback: const Icon(Icons.more_horiz),
                            menu: [
                              for (var i = 0; i < actions.length; i++)
                                GlassCapsuleMenuEntry(
                                  id: foldedId + i,
                                  title: actions[i].effectiveLabel ?? '',
                                  symbol: actions[i].iosSymbol,
                                ),
                            ],
                          ),
                        ],
                        native: native,
                        onTap: (_) {},
                        onMenuTap: (id) =>
                            actions[id - foldedId].press(context),
                      ),
                    )
                  else if (actions.isNotEmpty)
                    AdaptiveActionCapsule(
                      actions: actions,
                      actionKeys: actionKeys,
                      native: native,
                      width: width,
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildMaterial(BuildContext context) {
    Widget iconOf(Object? icon) => switch (icon) {
      IconData data => Icon(data),
      ImageProvider image => ClipOval(
        child: Image(image: image, width: 24, height: 24, fit: BoxFit.cover),
      ),
      Widget widget => widget,
      // An SF Symbol name: nothing to draw it with here.
      _ => const Icon(Icons.circle_outlined),
    };
    Widget keyed(Key? key, Widget child) =>
        key == null ? child : KeyedSubtree(key: key, child: child);

    return NavigationRail(
      selectedIndex: selectedIndex,
      onDestinationSelected: onDestinationSelected,
      labelType: showLabels
          ? NavigationRailLabelType.all
          : NavigationRailLabelType.none,
      leading: leading,
      destinations: [
        for (var i = 0; i < destinations.length; i++)
          NavigationRailDestination(
            // Only one of the two icons is built at a time, so a key is never
            // twice in the tree.
            icon: keyed(destinationKeys?[i], iconOf(destinations[i].icon)),
            selectedIcon: keyed(
              destinationKeys?[i],
              iconOf(destinations[i].selectedIcon ?? destinations[i].icon),
            ),
            label: Text(destinations[i].label),
          ),
      ],
      trailing: actions.isEmpty && footer == null
          ? null
          : Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: EdgeInsets.only(bottom: margin),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ?footer,
                      for (var i = 0; i < actions.length; i++)
                        keyed(
                          actionKeys?[i],
                          IconButton(
                            tooltip: actions[i].effectiveLabel,
                            onPressed: () => actions[i].press(context),
                            icon: actions[i].wrapWithBadge(
                              actions[i].imageWidget ??
                                  actions[i].iconWidget ??
                                  Icon(
                                    actions[i].icon ?? Icons.circle_outlined,
                                  ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
