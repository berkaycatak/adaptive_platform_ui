import 'dart:math' as math;

import 'package:flutter/cupertino.dart';

/// A height a bottom sheet rests at, like `UISheetPresentationController.Detent`.
///
/// The fraction is of the height the sheet may take: the screen below the top
/// safe area (and the keyboard, when it is up).
@immutable
class AdaptiveSheetDetent {
  /// A detent at [fraction] of the available height, from just above 0 to 1.
  const AdaptiveSheetDetent.fraction(this.fraction)
    : assert(fraction > 0 && fraction <= 1);

  /// About half the available height, like the system's `.medium` detent.
  static const AdaptiveSheetDetent medium = AdaptiveSheetDetent.fraction(0.5);

  /// The full available height, like the system's `.large` detent.
  static const AdaptiveSheetDetent large = AdaptiveSheetDetent.fraction(1.0);

  /// The share of the available height the sheet takes at this detent.
  final double fraction;

  @override
  bool operator ==(Object other) =>
      other is AdaptiveSheetDetent && other.fraction == fraction;

  @override
  int get hashCode => fraction.hashCode;

  @override
  String toString() => 'AdaptiveSheetDetent(${fraction.toStringAsFixed(2)})';
}

/// Builds the surface around a sheet's contents for the current [extent], the
/// fraction of the available height the sheet takes right now.
typedef SheetChromeBuilder =
    Widget Function(BuildContext context, double extent, Widget child);

/// The draggable part of every adaptive bottom sheet: it rests at [detents],
/// snaps between them, and pops its route when dragged or flung away.
///
/// The drag handle and the contents sit in one scroll view driven by a
/// [DraggableScrollableSheet], so dragging anywhere outside a scrollable of
/// the contents moves the sheet. A scrollable inside the contents scrolls on
/// its own.
///
/// Below the smallest detent the contents keep that detent's height and are
/// cut at the bottom, so the sheet looks like it slides away instead of
/// squeezing its layout.
class DetentSheet extends StatefulWidget {
  /// Creates a sheet that rests at [detents].
  const DetentSheet({
    super.key,
    required this.detents,
    this.initialDetent,
    this.isDismissible = true,
    this.dragHandle,
    required this.chromeBuilder,
    required this.builder,
  }) : assert(detents.length > 0);

  /// The heights the sheet rests at, in any order.
  final List<AdaptiveSheetDetent> detents;

  /// The detent the sheet opens at; the smallest one when null.
  final AdaptiveSheetDetent? initialDetent;

  /// Whether dragging the sheet down past its smallest detent dismisses it.
  final bool isDismissible;

  /// Drawn above the contents; dragging it moves the sheet.
  final Widget? dragHandle;

  /// Wraps the drag handle and contents in the platform's surface.
  final SheetChromeBuilder chromeBuilder;

  /// Builds the sheet's contents.
  final WidgetBuilder builder;

  /// The detent fractions, ascending and without duplicates.
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
    if (widget.isDismissible && !_closing && notification.extent <= 0.001) {
      _closing = true;
      // The notification can arrive mid-layout; pop once the frame is done.
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
            // The sheet pops its own route; a Material bottom sheet around it
            // must not close at the non-dismissible minimum.
            shouldCloseOnMinExtent: false,
            builder: (context, scrollController) {
              final scrollView = CustomScrollView(
                controller: scrollController,
                physics: const ClampingScrollPhysics(),
                slivers: [
                  if (widget.dragHandle != null)
                    SliverToBoxAdapter(child: widget.dragHandle),
                  SliverLayoutBuilder(
                    builder: (context, sliver) {
                      final remaining =
                          sliver.viewportMainAxisExtent -
                          sliver.precedingScrollExtent;
                      // Below the smallest detent, keep the height the
                      // contents had there and cut them at the bottom.
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

/// The capsule at the top of an iOS sheet.
class SheetGrabber extends StatelessWidget {
  /// Creates the grabber of an iOS sheet.
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
