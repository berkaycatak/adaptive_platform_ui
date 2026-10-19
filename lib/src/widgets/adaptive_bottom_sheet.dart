import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../platform/platform_info.dart';
import '../toolbar/toolbar_chrome_scope.dart';
import 'adaptive_blur_view.dart';
import 'detent_sheet.dart';
import 'ios_bottom_sheet_route.dart';

export 'detent_sheet.dart' show AdaptiveSheetDetent;

/// An adaptive modal bottom sheet that shows your own widgets
///
/// The sheet rests at its detents, snaps between them, and dismisses when
/// dragged down past the smallest one.
///
/// On iOS, full height only: the system page sheet (`showCupertinoSheet`)
/// On iOS 26+, other detents: a floating Liquid Glass sheet
/// On iOS <26, other detents: the opaque edge-to-edge iOS sheet
/// On Android: Material 3 `showModalBottomSheet`
class AdaptiveBottomSheet {
  AdaptiveBottomSheet._();

  /// Shows a modal bottom sheet and returns the value it is popped with
  ///
  /// Pass exactly one of [builder] and [scrollableBuilder]. [builder] fills
  /// the sheet with any widget. [scrollableBuilder] hands the contents' scroll
  /// view a [ScrollController] the sheet creates and disposes.
  ///
  /// [detents] are the heights the sheet rests at; it opens at
  /// [initialDetent], which must be one of them, or at the smallest one.
  ///
  /// When [isDismissible] is false, the barrier and dragging down do not
  /// close the sheet; pop it from its contents instead.
  ///
  /// [showDragHandle] draws the grabber at the top. [backgroundColor]
  /// replaces the platform background, and on iOS 26+ the Liquid Glass blur.
  /// [blurStyle] is the Liquid Glass material on iOS 26+.
  ///
  /// Returns a Future that resolves to the popped value, or null when the
  /// sheet is dismissed
  static Future<T?> show<T>({
    required BuildContext context,
    WidgetBuilder? builder,
    ScrollableWidgetBuilder? scrollableBuilder,
    List<AdaptiveSheetDetent> detents = const [AdaptiveSheetDetent.large],
    AdaptiveSheetDetent? initialDetent,
    bool isDismissible = true,
    bool showDragHandle = true,
    bool useRootNavigator = true,
    Color? backgroundColor,
    BlurStyle blurStyle = BlurStyle.systemMaterial,
  }) {
    assert(
      (builder == null) != (scrollableBuilder == null),
      'Pass either builder or scrollableBuilder',
    );
    assert(detents.isNotEmpty, 'A sheet needs at least one detent');
    assert(
      initialDetent == null || detents.contains(initialDetent),
      'initialDetent must be one of detents',
    );

    final barrierLabel = Localizations.of<CupertinoLocalizations>(
      context,
      CupertinoLocalizations,
    )?.modalBarrierDismissLabel;
    final WidgetBuilder contentBuilder =
        builder ??
        (context) => _OwnScrollController(builder: scrollableBuilder!);

    // A sheet that only rests at full height is what UIKit shows as a page
    // sheet, so iOS uses the system one, which also recedes the page behind.
    final fullHeightOnly = DetentSheet.sizesOf(detents).first >= 1.0;
    if (PlatformInfo.isIOS && fullHeightOnly) {
      return showCupertinoSheet<T>(
        context: context,
        enableDrag: isDismissible,
        // `builder` is deprecated for `scrollableBuilder` after Flutter 3.40,
        // which the CI's Flutter 3.35 does not have yet.
        // ignore: deprecated_member_use
        builder: (context) => _ToolbarCover(
          child: CupertinoUserInterfaceLevel(
            data: CupertinoUserInterfaceLevelData.elevated,
            child: _CupertinoSheetContents(
              showDragHandle: showDragHandle,
              backgroundColor: backgroundColor,
              child: Builder(builder: contentBuilder),
            ),
          ),
        ),
      );
    }

    if (PlatformInfo.isIOS26OrHigher()) {
      return Navigator.of(context, rootNavigator: useRootNavigator).push<T>(
        IOSBottomSheetRoute<T>(
          builder: contentBuilder,
          detents: detents,
          initialDetent: initialDetent,
          isDismissible: isDismissible,
          showDragHandle: showDragHandle,
          backgroundColor: backgroundColor,
          blurStyle: blurStyle,
          barrierLabel: barrierLabel,
        ),
      );
    }

    if (PlatformInfo.isIOS) {
      return Navigator.of(context, rootNavigator: useRootNavigator).push<T>(
        IOSBottomSheetRoute<T>(
          builder: contentBuilder,
          detents: detents,
          initialDetent: initialDetent,
          isDismissible: isDismissible,
          showDragHandle: showDragHandle,
          backgroundColor: backgroundColor,
          liquidGlass: false,
          barrierLabel: barrierLabel,
        ),
      );
    }

    // DetentSheet drags and snaps the sheet and draws the handle, so the
    // Material sheet's own drag and handle are turned off.
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      useRootNavigator: useRootNavigator,
      isDismissible: isDismissible,
      enableDrag: false,
      showDragHandle: false,
      backgroundColor: backgroundColor,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: DetentSheet(
          detents: detents,
          initialDetent: initialDetent,
          isDismissible: isDismissible,
          dragHandle: showDragHandle ? const _MaterialDragHandle() : null,
          chromeBuilder: (context, extent, child) => child,
          builder: contentBuilder,
        ),
      ),
    );
  }
}

class _CupertinoSheetContents extends StatelessWidget {
  const _CupertinoSheetContents({
    required this.showDragHandle,
    required this.backgroundColor,
    required this.child,
  });

  final bool showDragHandle;
  final Color? backgroundColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final color =
        backgroundColor ??
        CupertinoDynamicColor.resolve(
          CupertinoColors.systemBackground,
          context,
        );
    return ColoredBox(
      color: color,
      child: Material(
        type: MaterialType.transparency,
        child: DefaultTextStyle(
          style: CupertinoTheme.of(context).textTheme.textStyle,
          child: Column(
            children: [
              if (showDragHandle) const SheetGrabber(),
              Expanded(child: child),
            ],
          ),
        ),
      ),
    );
  }
}

class _MaterialDragHandle extends StatelessWidget {
  const _MaterialDragHandle();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = theme.bottomSheetTheme.dragHandleSize ?? const Size(32, 4);
    final color =
        theme.bottomSheetTheme.dragHandleColor ??
        theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4);
    return SizedBox(
      height: kMinInteractiveDimension,
      child: Center(
        child: Container(
          width: size.width,
          height: size.height,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(size.height / 2),
          ),
        ),
      ),
    );
  }
}

/// Owns the controller handed to a `scrollableBuilder` for the sheet's life
class _OwnScrollController extends StatefulWidget {
  const _OwnScrollController({required this.builder});

  final ScrollableWidgetBuilder builder;

  @override
  State<_OwnScrollController> createState() => _OwnScrollControllerState();
}

class _OwnScrollControllerState extends State<_OwnScrollController> {
  final _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _controller);
}

/// Fades the hosted toolbar out as the iOS page sheet rises over it
///
/// The hosted toolbar is drawn above every route, so a sheet cannot cover it.
/// This reports the sheet route's animation to the toolbar host instead, and
/// reports 0 when the sheet goes away.
class _ToolbarCover extends StatefulWidget {
  const _ToolbarCover({required this.child});

  final Widget child;

  @override
  State<_ToolbarCover> createState() => _ToolbarCoverState();
}

class _ToolbarCoverState extends State<_ToolbarCover> {
  ValueSetter<double>? _report;
  Animation<double>? _animation;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _report ??= ToolbarChromeScope.sheetCoverReporterOf(context);
    final animation = ModalRoute.of(context)?.animation;
    if (animation == _animation) return;
    _animation?.removeListener(_reportCover);
    _animation = animation?..addListener(_reportCover);
  }

  void _reportCover() => _report?.call(_animation!.value.clamp(0.0, 1.0));

  @override
  void dispose() {
    _animation?.removeListener(_reportCover);
    _report?.call(0);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
