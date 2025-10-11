import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../platform/platform_info.dart';
import 'ios26/ios26_segmented_control.dart';

/// An adaptive segmented control that renders platform-specific styles
///
/// On iOS 26+: Uses native iOS 26 UISegmentedControl with Liquid Glass
/// On iOS <26 (iOS 18 and below): Uses CupertinoSegmentedControl
/// On Android: Uses Material SegmentedButton
class AdaptiveSegmentedControl extends StatelessWidget {
  /// Creates an adaptive segmented control
  const AdaptiveSegmentedControl({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onValueChanged,
    this.enabled = true,
    this.color,
    this.height = 32.0,
    this.shrinkWrap = false,
    this.sfSymbols,
    this.iconSize,
    this.iconColor,
  });

  /// Segment labels to display, in order
  final List<String> labels;

  /// The index of the selected segment
  final int selectedIndex;

  /// Called when the user selects a segment
  final ValueChanged<int> onValueChanged;

  /// Whether the control is interactive
  final bool enabled;

  /// Tint color for the selected segment
  final Color? color;

  /// Height of the control
  final double height;

  /// Whether the control should shrink to fit content
  final bool shrinkWrap;

  /// Optional SF Symbol names for icons (iOS only)
  final List<String>? sfSymbols;

  /// Icon size (when using sfSymbols)
  final double? iconSize;

  /// Icon color (when using sfSymbols)
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    // iOS 26+ - Use native iOS 26 segmented control
    if (PlatformInfo.isIOS26OrHigher()) {
      return IOS26SegmentedControl(
        labels: labels,
        selectedIndex: selectedIndex,
        onValueChanged: onValueChanged,
        enabled: enabled,
        color: color,
        height: height,
        shrinkWrap: shrinkWrap,
        sfSymbols: sfSymbols,
        iconSize: iconSize,
        iconColor: iconColor,
      );
    }

    // iOS <26 (iOS 18 and below) - Use traditional CupertinoSegmentedControl
    if (PlatformInfo.isIOS) {
      return _buildCupertinoSegmentedControl(context);
    }

    // Android - Use Material SegmentedButton
    if (PlatformInfo.isAndroid) {
      return _buildMaterialSegmentedButton(context);
    }

    // Fallback
    return _buildCupertinoSegmentedControl(context);
  }

  IconData _sfSymbolToCupertinoIcon(String sfSymbol) {
    const iconMap = {
      'list.clipboard': CupertinoIcons.list_bullet_below_rectangle,
      'leaf.arrow.trianglehead.clockwise': CupertinoIcons.arrow_clockwise,
      'figure.walk.diamond': CupertinoIcons.person,
      'house': CupertinoIcons.house,
      'house.fill': CupertinoIcons.house_fill,
      'magnifyingglass': CupertinoIcons.search,
      'heart': CupertinoIcons.heart,
      'heart.fill': CupertinoIcons.heart_fill,
      'person': CupertinoIcons.person,
      'person.fill': CupertinoIcons.person_fill,
      'gear': CupertinoIcons.settings,
      'star': CupertinoIcons.star,
      'star.fill': CupertinoIcons.star_fill,
    };
    return iconMap[sfSymbol] ?? CupertinoIcons.circle;
  }

  Widget _buildCupertinoSegmentedControl(BuildContext context) {
    // Build children map from labels or icons
    final Map<int, Widget> children = {};

    // Check if using icons
    final useIcons = sfSymbols != null && sfSymbols!.isNotEmpty;
    final itemCount = useIcons ? sfSymbols!.length : labels.length;

    for (int i = 0; i < itemCount; i++) {
      if (useIcons) {
        // Icon mode
        children[i] = Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(
            _sfSymbolToCupertinoIcon(sfSymbols![i]),
            size: iconSize ?? 20,
            color: iconColor,
          ),
        );
      } else {
        // Text mode
        children[i] = Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Text(
            labels[i],
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
        );
      }
    }

    Widget control = CupertinoSegmentedControl<int>(
      children: children,
      groupValue: selectedIndex,
      onValueChanged: enabled ? onValueChanged : (_) {},
    );

    if (shrinkWrap) {
      control = Center(child: IntrinsicWidth(child: control));
    }

    return SizedBox(height: height, child: control);
  }

  IconData _sfSymbolToMaterialIcon(String sfSymbol) {
    const iconMap = {
      'list.clipboard': Icons.list,
      'leaf.arrow.trianglehead.clockwise': Icons.refresh,
      'figure.walk.diamond': Icons.directions_walk,
      'house': Icons.home_outlined,
      'house.fill': Icons.home,
      'magnifyingglass': Icons.search,
      'heart': Icons.favorite_border,
      'heart.fill': Icons.favorite,
      'person': Icons.person_outline,
      'person.fill': Icons.person,
      'gear': Icons.settings,
      'star': Icons.star_border,
      'star.fill': Icons.star,
    };
    return iconMap[sfSymbol] ?? Icons.circle_outlined;
  }

  Widget _buildMaterialSegmentedButton(BuildContext context) {
    final segments = <ButtonSegment<int>>[];

    // Check if using icons
    final useIcons = sfSymbols != null && sfSymbols!.isNotEmpty;
    final itemCount = useIcons ? sfSymbols!.length : labels.length;

    for (int i = 0; i < itemCount; i++) {
      if (useIcons) {
        // Icon mode
        segments.add(
          ButtonSegment<int>(
            value: i,
            icon: Icon(
              _sfSymbolToMaterialIcon(sfSymbols![i]),
              size: iconSize ?? 20,
              color: iconColor,
            ),
          ),
        );
      } else {
        // Text mode
        segments.add(
          ButtonSegment<int>(
            value: i,
            label: Text(labels[i]),
          ),
        );
      }
    }

    Widget control = SegmentedButton<int>(
      segments: segments,
      selected: {selectedIndex},
      onSelectionChanged: enabled
          ? (Set<int> newSelection) {
              if (newSelection.isNotEmpty) {
                onValueChanged(newSelection.first);
              }
            }
          : null,
    );

    if (shrinkWrap) {
      control = Center(child: IntrinsicWidth(child: control));
    }

    return SizedBox(height: height, child: control);
  }
}
