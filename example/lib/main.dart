import 'package:adaptive_platform_ui_example/pages/demos/demo_tabbar_page.dart';
import 'package:adaptive_platform_ui_example/pages/demos/popup_menu_demo_page.dart';
import 'package:adaptive_platform_ui_example/pages/demos/segmented_control_demo_page.dart';
import 'package:adaptive_platform_ui_example/pages/demos/slider_demo_page.dart';
import 'package:adaptive_platform_ui_example/pages/demos/switch_demo_page.dart';
import 'package:adaptive_platform_ui_example/pages/demos/checkbox_demo_page.dart';
import 'package:adaptive_platform_ui_example/pages/demos/radio_demo_page.dart';
import 'package:adaptive_platform_ui_example/pages/demos/card_demo_page.dart';
import 'package:adaptive_platform_ui_example/pages/demos/badge_demo_page.dart';
import 'package:adaptive_platform_ui_example/pages/demos/tooltip_demo_page.dart';
import 'package:adaptive_platform_ui_example/pages/demos/native_search_tab_demo_page.dart';
import 'package:adaptive_platform_ui_example/service/router/router_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'pages/demos/alert_dialog_demo_page.dart';
import 'pages/demos/button_demo_page.dart';

void main() {
  runApp(const AdaptivePlatformUIDemo());
}

class AdaptivePlatformUIDemo extends StatefulWidget {
  const AdaptivePlatformUIDemo({super.key});

  @override
  State<AdaptivePlatformUIDemo> createState() => _AdaptivePlatformUIDemoState();
}

class _AdaptivePlatformUIDemoState extends State<AdaptivePlatformUIDemo> {
  RouterService routerService = RouterService();

  @override
  Widget build(BuildContext context) {
    return AdaptiveApp.router(
      themeMode: ThemeMode.system,
      title: 'Adaptive Platform UI',
      cupertinoLightTheme: CupertinoThemeData(brightness: Brightness.light),
      cupertinoDarkTheme: CupertinoThemeData(brightness: Brightness.dark),
      materialLightTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        brightness: Brightness.light,
      ),
      materialDarkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        brightness: Brightness.dark,
      ),
      routerConfig: routerService.router,
    );
  }
}
