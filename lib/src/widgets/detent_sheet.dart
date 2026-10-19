import 'dart:math' as math;

import 'package:flutter/cupertino.dart';

/// A height an `AdaptiveBottomSheet` can rest at
///
/// Like UIKit's `UISheetPresentationController.Detent`: [medium] is half the
/// available height, [large] is all of it, and [AdaptiveSheetDetent.fraction]
/// is any share of it.
@immutable
class AdaptiveSheetDetent {
  /// A detent at [fraction] of the available height, in (0, 1]
  const AdaptiveSheetDetent.fraction(this.fraction)
    : assert(fraction > 0 && fraction <= 1);

  /// Half the available height
  static const AdaptiveSheetDetent medium = AdaptiveSheetDetent.fraction(0.5);

  /// The full available height
  static const AdaptiveSheetDetent large = AdaptiveSheetDetent.fraction(1.0);

  /// Share of the available height, in (0, 1]
  final double fraction;

  @override
  bool operator ==(Object other) =>
      other is AdaptiveSheetDetent && other.fraction == fraction;

  @override
  int get hashCode => fraction.hashCode;

  @override
  String toString() => 'AdaptiveSheetDetent(${fraction.toStringAsFixed(2)})';
}

/// Wraps the sheet's scroll view in its background, given the current extent
typedef SheetChromeBuilder =
    Widget Function(BuildContext context, double extent, Widget child);

/// A sheet that rests at [detents], snaps between them and, when
/// [isDismissible], pops its route when dragged down past the smallest one
///
/// Shared by the Material sheet and `IOSBottomSheetRoute`; each draws its own
/// background with [chromeBuilder].
class DetentSheet extends StatefulWidget {
  const DetentSheet({
    super.key,
    required this.detents,
    this.initialDetent,
    this.isDismissible = true,
    this.dragHandle,
    required this.chromeBuilder,
    required this.builder,
  }) : assert(detents.length > 0);

  final List<AdaptiveSheetDetent> detents;

  final AdaptiveSheetDetent? initialDetent;

  final bool isDismissible;

  final Widget? dragHandle;

  final SheetChromeBuilder chromeBuilder;

  final WidgetBuilder builder;

  /// The detents' fractions, without duplicates, smallest first
  static List<double> sizesOf(List<AdaptiveSheetDetent> detents) =>
      detents.map((d) => d.fraction).toSet().toList()..sort();

  @override
  State<DetentSheet> createState() => _DetentSheetState();
}

class _DetentSheetState extends State<DetentSheet> {
  late final ValueNotifier<double> _extent = ValueNotifier(_initialSize);
  bool _closing = false;

  List<double> get _sizes => DetentSheet.sizesOf(widget.detents);

  double get _initialSize {
    final initial = widget.initialDetent;
    assert(
      initial == null || widget.detents.contains(initial),
      'initialDetent must be one of detents',
    );
    return initial?.fraction ?? _sizes.first;
  }

  @override
  void dispose() {
    _extent.dispose();
    super.dispose();
  }

  bool _handleExtent(DraggableScrollableNotification notification) {
    _extent.value = notification.extent;
    // A dismissible sheet may be dragged down to 0; popping there, after the
    // frame, closes it without a second animation from the route.
    if (widget.isDismissible && !_closing && notification.extent <= 0.001) {
      _closing = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (ModalRoute.of(context)?.isCurrent ?? false) {
          Navigator.of(context).pop();
        }
      });
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final sizes = _sizes;
    return LayoutBuilder(
      builder: (context, constraints) {
        return NotificationListener<DraggableScrollableNotification>(
          onNotification: _handleExtent,
          child: DraggableScrollableSheet(
            expand: false,
            initialChildSize: _initialSize,
            minChildSize: widget.isDismissible ? 0 : sizes.first,
            maxChildSize: sizes.last,
            snap: true,
            snapSizes: sizes,
            shouldCloseOnMinExtent: false,
            builder: (context, scrollController) {
              final scrollView = CustomScrollView(
                controller: scrollController,
                physics: const ClampingScrollPhysics(),
                slivers: [
                  if (widget.dragHandle != null)
                    SliverToBoxAdapter(child: widget.dragHandle),
                  // The contents fill what the handle leaves of the sheet.
                  // Below the smallest detent they keep that detent's height
                  // and slide off screen instead of being squashed.
                  SliverLayoutBuilder(
                    builder: (context, sliver) {
                      final remaining =
                          sliver.viewportMainAxisExtent -
                          sliver.precedingScrollExtent;
                      final hidden =
                          math.max(0.0, sizes.first - _extent.value) *
                          constraints.maxHeight;
                      return SliverToBoxAdapter(
                        child: SizedBox(
                          height: math.max(0, remaining + hidden),
                          child: Builder(builder: widget.builder),
                        ),
                      );
                    },
                  ),
                ],
              );
              return ValueListenableBuilder<double>(
                valueListenable: _extent,
                builder: (context, extent, child) =>
                    widget.chromeBuilder(context, extent, child!),
                child: scrollView,
              );
            },
          ),
        );
      },
    );
  }
}

/// The iOS sheet grabber: a short rounded bar at the top of the sheet
class SheetGrabber extends StatelessWidget {
  const SheetGrabber({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 5, bottom: 10),
      child: Center(
        child: Container(
          width: 36,
          height: 5,
          decoration: BoxDecoration(
            color: CupertinoDynamicColor.resolve(
              CupertinoColors.tertiaryLabel,
              context,
            ),
            borderRadius: BorderRadius.circular(2.5),
          ),
        ),
      ),
    );
  }
}
