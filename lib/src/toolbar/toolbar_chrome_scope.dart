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
    required this.hostsDuoControls,
    required super.child,
  });

  /// True while the host shows the page's controls (back button, actions) in
  /// the fixed trailing vertical bar of iPhone Duo. Pages
  /// then keep only their title at the top.
  final bool hostsDuoControls;

  /// The nearest scope, or null when no host is installed and the page must
  /// draw its whole toolbar itself.
  static ToolbarChromeScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ToolbarChromeScope>();

  @override
  bool updateShouldNotify(ToolbarChromeScope oldWidget) =>
      hostsDuoControls != oldWidget.hostsDuoControls;
}
