import 'package:flutter/material.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
BuildContext? get currentContext => navigatorKey.currentContext;

ScrollController homeScrollController = ScrollController();
ScrollController infoScrollController = ScrollController();
ScrollController searchScrollController = ScrollController();

/// Controls native tab bar visibility from anywhere in the app.
/// Set to true to hide the tab bar (e.g. when showing bottom sheets).
final ValueNotifier<bool> tabBarHiddenNotifier = ValueNotifier<bool>(false);
