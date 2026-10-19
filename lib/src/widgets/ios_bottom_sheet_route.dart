import 'dart:ui' show lerpDouble;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Material, MaterialType;

import '../toolbar/hosted_top_toolbar.dart' show kHostedToolbarHeight;
import '../toolbar/toolbar_chrome_scope.dart';
import 'adaptive_blur_view.dart';
import 'detent_sheet.dart';

/// Space between the status bar and a full-height sheet
const double _kTopGap = 10;

/// Gap between a floating Liquid Glass sheet and the screen edges
const double _kFloatingInset = 8;

/// Corner radius of the Liquid Glass sheet
const double _kGlassRadius = 36;

/// Top corner radius of the pre-iOS 26 sheet
const double _kLegacyRadius = 10;

/// How far the sheet's top edge travels over the toolbar while it fades out
const double _kToolbarFadeDistance = 40;

/// A route that shows an iOS bottom sheet resting at [detents]
///
/// With [liquidGlass] (iOS 26+), the sheet floats off the screen edges on a
/// native `UIVisualEffectView` background and meets the edges at full
/// height. Without it (iOS 18 and below), the sheet is the opaque
/// edge-to-edge iOS sheet. `AdaptiveBottomSheet.show` picks this route on
/// iOS; push it directly for custom navigation.
class IOSBottomSheetRoute<T> extends PopupRoute<T> {
  /// Creates an iOS bottom sheet route
  IOSBottomSheetRoute({
    required this.builder,
    this.detents = const [AdaptiveSheetDetent.large],
    this.initialDetent,
    this.isDismissible = true,
    this.showDragHandle = true,
    this.backgroundColor,
    this.blurStyle = BlurStyle.systemMaterial,
    this.liquidGlass = true,
    String? barrierLabel,
    super.settings,
  }) : assert(detents.isNotEmpty),
       _barrierLabel = barrierLabel;

  /// Builds the sheet's contents
  final WidgetBuilder builder;

  /// The heights the sheet rests at
  final List<AdaptiveSheetDetent> detents;

  /// The detent the sheet opens at; the smallest one when null
  final AdaptiveSheetDetent? initialDetent;

  /// Whether the barrier and dragging down close the sheet
  final bool isDismissible;

  /// Whether to draw the grabber at the top of the sheet
  final bool showDragHandle;

  /// Opaque background instead of the platform one
  final Color? backgroundColor;

  /// The Liquid Glass material, when [liquidGlass] and no [backgroundColor]
  final BlurStyle blurStyle;

  /// Whether to draw the floating iOS 26 Liquid Glass sheet
  final bool liquidGlass;

  final String? _barrierLabel;

  // Layout of the last frame, for working out where the sheet's top is.
  double _extent = 0;
  double _available = 0;
  double _topPadding = 0;

  ValueSetter<double>? _reportCover;

  @override
  Color? get barrierColor => const Color(0x33000000);

  @override
  bool get barrierDismissible => isDismissible;

  @override
  String? get barrierLabel => _barrierLabel ?? 'Dismiss';

  @override
  Duration get transitionDuration => const Duration(milliseconds: 450);

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 300);

  @override
  void install() {
    super.install();
    animation!.addListener(_reportToolbarCover);
  }

  @override
  void dispose() {
    animation?.removeListener(_reportToolbarCover);
    _reportCover?.call(0);
    super.dispose();
  }

  /// Tells the toolbar host how far the sheet covers the hosted toolbar
  ///
  /// The toolbar is drawn above every route, so it fades out over
  /// [_kToolbarFadeDistance] as the sheet's top edge, sliding in with the
  /// route animation, rises past the toolbar's bottom edge.
  void _reportToolbarCover() {
    final report = _reportCover;
    if (report == null || _available <= 0) return;
    final shown = _extent * _available;
    final top =
        _topPadding +
        _kTopGap +
        (_available - shown) +
        (1 - animation!.value) * shown;
    final toolbarBottom = _topPadding + kHostedToolbarHeight;
    final cover =
        (toolbarBottom + _kToolbarFadeDistance - top) / _kToolbarFadeDistance;
    report(cover.clamp(0.0, 1.0));
  }

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    _reportCover ??= ToolbarChromeScope.sheetCoverReporterOf(context);
    final mediaQuery = MediaQuery.of(context);
    _topPadding = mediaQuery.padding.top;
    _available =
        mediaQuery.size.height -
        mediaQuery.viewInsets.bottom -
        mediaQuery.padding.top -
        _kTopGap;
    return Padding(
      padding: EdgeInsets.only(
        top: mediaQuery.padding.top + _kTopGap,
        bottom: mediaQuery.viewInsets.bottom,
      ),
      child: MediaQuery(
        data: mediaQuery
            .removeViewInsets(removeBottom: true)
            .removePadding(removeTop: true),
        // UIKit draws sheets at the elevated level, so dynamic colors such as
        // systemBackground stand out from the page in dark mode.
        child: CupertinoUserInterfaceLevel(
          data: CupertinoUserInterfaceLevelData.elevated,
          child: Semantics(
            scopesRoute: true,
            namesRoute: true,
            explicitChildNodes: true,
            child: DetentSheet(
              detents: detents,
              initialDetent: initialDetent,
              isDismissible: isDismissible,
              dragHandle: showDragHandle ? const SheetGrabber() : null,
              chromeBuilder: _buildChrome,
              builder: builder,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.fastEaseInToSlowEaseOut,
      reverseCurve: Curves.easeInCubic,
    );
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 1),
        end: Offset.zero,
      ).animate(curved),
      child: child,
    );
  }

  Widget _buildChrome(BuildContext context, double extent, Widget child) {
    _extent = extent;
    _reportToolbarCover();
    // 0 while floating, 1 at full height: over the last tenth of the drag the
    // Liquid Glass sheet grows into the screen edges and squares its bottom.
    final full = liquidGlass
        ? ((extent - 0.9) / 0.1).clamp(0.0, 1.0) * _fullHeightFactor
        : 1.0;
    final inset = lerpDouble(_kFloatingInset, 0, full)!;
    final topRadius = liquidGlass ? _kGlassRadius : _kLegacyRadius;
    final bottomRadius = liquidGlass
        ? lerpDouble(_kGlassRadius, 0, full)!
        : 0.0;
    final borderRadius = BorderRadius.vertical(
      top: Radius.circular(topRadius),
      bottom: Radius.circular(bottomRadius),
    );

    final mediaQuery = MediaQuery.of(context);
    final contents = MediaQuery(
      data: mediaQuery.copyWith(
        padding: mediaQuery.padding.copyWith(
          bottom: (mediaQuery.padding.bottom - inset).clamp(
            0.0,
            double.infinity,
          ),
        ),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: DefaultTextStyle(
          style: CupertinoTheme.of(context).textTheme.textStyle,
          child: child,
        ),
      ),
    );

    final Widget surface;
    if (backgroundColor != null || !liquidGlass) {
      final color =
          backgroundColor ??
          CupertinoDynamicColor.resolve(
            CupertinoColors.systemBackground,
            context,
          );
      surface = ClipRRect(
        borderRadius: borderRadius,
        child: ColoredBox(color: color, child: contents),
      );
    } else {
      surface = AdaptiveBlurView(
        blurStyle: blurStyle,
        borderRadius: borderRadius,
        child: contents,
      );
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(inset, 0, inset, inset),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          boxShadow: [
            if (liquidGlass)
              const BoxShadow(
                color: Color(0x1F000000),
                blurRadius: 30,
                offset: Offset(0, 4),
              ),
          ],
        ),
        child: surface,
      ),
    );
  }

  double get _fullHeightFactor =>
      DetentSheet.sizesOf(detents).last >= 1.0 ? 1.0 : 0.0;
}
