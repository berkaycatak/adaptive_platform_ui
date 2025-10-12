import 'package:adaptive_platform_ui_example/service/router/router_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';

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
