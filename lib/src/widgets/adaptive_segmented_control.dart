import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../platform/platform_info.dart';
import 'ios26/ios26_segmented_control.dart';

/// An adaptive segmented control that renders platform-specific styles
///
/// On iOS 26+: Uses native iOS 26 UISegmentedControl with Liquid Glass
/// On iOS <26: Uses CupertinoSegmentedControl
/// On Android: Uses Material SegmentedButton
class AdaptiveSegmentedControl<T extends Object> extends StatelessWidget {
  const AdaptiveSegmentedControl({
    super.key,
    required this.children,
    required this.onValueChanged,
    this.groupValue,
  });

  /// Map of segment values to their child widgets
  final Map<T, Widget> children;

  /// The currently selected value
  final T? groupValue;

  /// Called when the user taps a segment
  final ValueChanged<T> onValueChanged;

  @override
  Widget build(BuildContext context) {
    // iOS 26+ - Use native iOS 26 segmented control
    if (PlatformInfo.isIOS26OrHigher()) {
      return iOS26SegmentedControl<T>(
        children: children,
        groupValue: groupValue,
        onValueChanged: onValueChanged,
      );
    }

    // iOS 25 and below - Use traditional CupertinoSegmentedControl
    if (PlatformInfo.isIOS) {
      return CupertinoSegmentedControl<T>(
        children: children,
        groupValue: groupValue,
        onValueChanged: onValueChanged,
      );
    }

    // Android - Use Material SegmentedButton
    if (PlatformInfo.isAndroid) {
      return _buildMaterialSegmentedButton(context);
    }

    // Fallback
    return CupertinoSegmentedControl<T>(
      children: children,
      groupValue: groupValue,
      onValueChanged: onValueChanged,
    );
  }

  Widget _buildMaterialSegmentedButton(BuildContext context) {
    final segments = children.entries.map((entry) {
      return ButtonSegment<T>(
        value: entry.key,
        label: entry.value,
      );
    }).toList();

    return SegmentedButton<T>(
      segments: segments,
      selected: groupValue != null ? {groupValue!} : {},
      onSelectionChanged: (Set<T> newSelection) {
        if (newSelection.isNotEmpty) {
          onValueChanged(newSelection.first);
        }
      },
    );
  }
}
