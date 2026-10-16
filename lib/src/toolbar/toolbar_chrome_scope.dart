import 'package:flutter/widgets.dart';

/// Tells the pages below an [AdaptiveToolbarHost] which parts of the toolbar
/// the host is drawing for them right now, so they do not draw the same parts
/// themselves.
///
/// The host is the single source of truth for the layout decision: a page
/// never has to agree with it by measuring the device a second time.
class ToolbarChromeScope extends InheritedWidget {
  const ToolbarChromeScope({
    super.key,
    required this.hostsToolbar,
    required this.hostsDuoControls,
    this.onSheetCover,
    required super.child,
  });

  /// True while the host draws the top toolbar (title, back button, actions)
  /// for every page in one fixed bar. Pages then draw no toolbar of their own
  /// and only keep their content clear of it.
  final bool hostsToolbar;

  /// True while the host shows the page's controls (back button, actions) in
  /// the fixed vertical bar of iPhone Duo, on whichever edge the pose puts it
  /// (see `DuoPose`). Pages then keep only their title at the top.
  final bool hostsDuoControls;

  /// Receives how far a bottom sheet covers the chrome, from 0 to 1, so the
  /// host can fade the chrome out under it. Null when the host draws nothing.
  final ValueSetter<double>? onSheetCover;

  /// The [onSheetCover] of the host above [context], to tell it how far a
  /// bottom sheet covers its chrome, from 0 (clear of it) to 1 (over it).
  /// Null without a host. Look it up while [context] is active and keep it:
  /// a sheet reports its last value from `dispose`.
  static ValueSetter<double>? sheetCoverReporterOf(BuildContext context) =>
      context.getInheritedWidgetOfExactType<ToolbarChromeScope>()?.onSheetCover;

  /// The nearest scope, or null when no host is installed and the page must
  /// draw its whole toolbar itself.
  static ToolbarChromeScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ToolbarChromeScope>();

  @override
  bool updateShouldNotify(ToolbarChromeScope oldWidget) =>
      hostsToolbar != oldWidget.hostsToolbar ||
      hostsDuoControls != oldWidget.hostsDuoControls;
}
