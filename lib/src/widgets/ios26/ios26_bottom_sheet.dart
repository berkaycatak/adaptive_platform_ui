import 'dart:ui' show lerpDouble;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Material, MaterialType;

import '../../toolbar/hosted_top_toolbar.dart' show kHostedToolbarHeight;
import '../../toolbar/toolbar_chrome_scope.dart';
import '../adaptive_blur_view.dart';
import '../detent_sheet.dart';

/// The gap between the top safe area and a sheet at its full height.
const double _kTopGap = 10;

/// How far a floating iOS 26 sheet sits from the screen's sides and bottom.
const double _kFloatingInset = 8;

/// The corner radius of an iOS 26 sheet.
const double _kGlassRadius = 36;

/// The top corner radius of a sheet before iOS 26.
const double _kLegacyRadius = 10;

/// How far above the fixed toolbar's bottom edge a rising sheet starts
/// fading the toolbar out.
const double _kToolbarFadeDistance = 40;

/// A route that shows an iOS bottom sheet drawn in Flutter.
///
/// With [liquidGlass] (iOS 26+), the sheet floats a few points off the
/// screen's sides and bottom with all corners rounded, on a native
/// `UIVisualEffectView` background ([AdaptiveBlurView]); at its full height it
/// meets the screen edges. Without it, the sheet is the opaque, edge-to-edge
/// sheet of iOS 18 and below.
///
/// [AdaptiveBottomSheet.show] picks this route on iOS; push it yourself for
/// more control.
class IOS26BottomSheetRoute<T> extends PopupRoute<T> {
  /// Creates an iOS bottom sheet route.
  IOS26BottomSheetRoute({
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

  /// Builds the sheet's contents.
  final WidgetBuilder builder;

  /// The heights the sheet rests at.
  final List<AdaptiveSheetDetent> detents;

  /// The detent the sheet opens at; the smallest one when null.
  final AdaptiveSheetDetent? initialDetent;

  /// Whether tapping outside the sheet or dragging it down dismisses it.
  final bool isDismissible;

  /// Whether to draw the grabber at the top of the sheet.
  final bool showDragHandle;

  /// A solid background in place of the glass (or the system background
  /// without [liquidGlass]).
  final Color? backgroundColor;

  /// The material of the glass background, when [backgroundColor] is null.
  final BlurStyle blurStyle;

  /// Whether to draw the floating iOS 26 glass sheet instead of the opaque
  /// sheet of iOS 18 and below.
  final bool liquidGlass;

  final String? _barrierLabel;

  /// The sheet's current fraction of [_available], its height below the top
  /// safe area, and the top safe area: what places the sheet's top edge.
  double _extent = 0;
  double _available = 0;
  double _topPadding = 0;

  /// Tells the fixed toolbar host how far the sheet covers its toolbar.
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

  /// The fixed toolbar is drawn above every route, so a sheet that rises to
  /// it would sit under it. Fade the toolbar out as the sheet's top edge,
  /// following both its height and its slide in or out, reaches it.
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
      child: MediaQuery.removeViewInsets(
        context: context,
        removeBottom: true,
        child: MediaQuery.removePadding(
          context: context,
          removeTop: true,
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
    // 0 while the sheet floats, 1 once it reaches the full height. A sheet
    // whose largest detent is below full height always floats.
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
      // The sheet covers the home indicator less by its inset.
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

  /// 1 when the largest detent is the full height, else 0.
  double get _fullHeightFactor =>
      DetentSheet.sizesOf(detents).last >= 1.0 ? 1.0 : 0.0;
}
