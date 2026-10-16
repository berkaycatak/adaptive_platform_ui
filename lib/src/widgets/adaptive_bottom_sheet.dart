import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../platform/platform_info.dart';
import 'adaptive_blur_view.dart';
import 'detent_sheet.dart';
import 'ios26/ios26_bottom_sheet.dart';

export 'detent_sheet.dart' show AdaptiveSheetDetent;

/// An adaptive modal bottom sheet that renders platform-specific styles
///
/// On iOS 26+: A floating Liquid Glass sheet on a native `UIVisualEffectView`
/// background that meets the screen edges at its full height
/// On iOS <26 (iOS 18 and below): `showCupertinoSheet` when the sheet only
/// opens at full height, else the opaque edge-to-edge iOS sheet at its detents
/// On Android: Material 3 `showModalBottomSheet`
///
/// On every platform the sheet rests at [AdaptiveSheetDetent]s and snaps
/// between them; dragging it down past the smallest one dismisses it. The
/// contents are your own widgets, so they share the app's theme, providers
/// and navigator.
class AdaptiveBottomSheet {
  AdaptiveBottomSheet._();

  /// Shows an adaptive bottom sheet whose contents [builder] builds.
  ///
  /// The sheet opens at [initialDetent] (the smallest of [detents] when null)
  /// and rests at [detents]. The contents get the sheet's height below the
  /// drag handle; give a long list its own scroll view.
  ///
  /// [isDismissible] lets a tap outside the sheet or a drag down dismiss it.
  /// [showDragHandle] draws the grabber (iOS) or drag handle (Android).
  /// [backgroundColor] replaces the glass on iOS 26+ and the default surface
  /// elsewhere. [blurStyle] picks the glass material on iOS 26+.
  ///
  /// Returns a Future that resolves to the value the sheet was popped with,
  /// or null when it was dismissed.
  static Future<T?> show<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    List<AdaptiveSheetDetent> detents = const [AdaptiveSheetDetent.large],
    AdaptiveSheetDetent? initialDetent,
    bool isDismissible = true,
    bool showDragHandle = true,
    bool useRootNavigator = true,
    Color? backgroundColor,
    BlurStyle blurStyle = BlurStyle.systemMaterial,
  }) {
    assert(detents.isNotEmpty, 'A sheet needs at least one detent');
    assert(
      initialDetent == null || detents.contains(initialDetent),
      'initialDetent must be one of detents',
    );

    final barrierLabel = Localizations.of<CupertinoLocalizations>(
      context,
      CupertinoLocalizations,
    )?.modalBarrierDismissLabel;

    // iOS 26+ - Floating Liquid Glass sheet
    if (PlatformInfo.isIOS26OrHigher()) {
      return Navigator.of(context, rootNavigator: useRootNavigator).push<T>(
        IOS26BottomSheetRoute<T>(
          builder: builder,
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

    // iOS 18 and below
    if (PlatformInfo.isIOS) {
      final fullHeightOnly = DetentSheet.sizesOf(detents).first >= 1.0;
      if (fullHeightOnly) {
        // The system page sheet, with the page behind it scaled back
        return showCupertinoSheet<T>(
          context: context,
          enableDrag: isDismissible,
          builder: (context) => _CupertinoSheetContents(
            showDragHandle: showDragHandle,
            backgroundColor: backgroundColor,
            child: Builder(builder: builder),
          ),
        );
      }

      // showCupertinoSheet has no detents; draw the classic sheet at them
      return Navigator.of(context, rootNavigator: useRootNavigator).push<T>(
        IOS26BottomSheetRoute<T>(
          builder: builder,
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

    // Android - Material 3 bottom sheet
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      useRootNavigator: useRootNavigator,
      isDismissible: isDismissible,
      // The detent sheet inside handles dragging, snapping and dismissing,
      // and draws the handle so that dragging it moves the sheet.
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
          builder: builder,
        ),
      ),
    );
  }
}

/// The surface of a full-height iOS 18 sheet: [showCupertinoSheet] only clips
/// its page, so the background and text style come from here.
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

/// The Material 3 drag handle, drawn inside the detent sheet so that dragging
/// it moves the sheet.
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
