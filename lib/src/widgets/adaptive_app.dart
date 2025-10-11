import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../platform/platform_info.dart';

/// Platform-specific configuration for MaterialApp
class MaterialAppData {
  const MaterialAppData({
    this.color,
    this.highContrastTheme,
    this.highContrastDarkTheme,
    this.debugShowMaterialGrid = false,
    this.showPerformanceOverlay = false,
    this.checkerboardRasterCacheImages = false,
    this.checkerboardOffscreenLayers = false,
    this.showSemanticsDebugger = false,
    this.debugShowCheckedModeBanner = false,
    this.shortcuts,
    this.actions,
    this.restorationScopeId,
    this.scrollBehavior,
  });

  final Color? color;
  final ThemeData? highContrastTheme;
  final ThemeData? highContrastDarkTheme;
  final bool debugShowMaterialGrid;
  final bool showPerformanceOverlay;
  final bool checkerboardRasterCacheImages;
  final bool checkerboardOffscreenLayers;
  final bool showSemanticsDebugger;
  final bool debugShowCheckedModeBanner;
  final Map<ShortcutActivator, Intent>? shortcuts;
  final Map<Type, Action<Intent>>? actions;
  final String? restorationScopeId;
  final ScrollBehavior? scrollBehavior;
}

/// Platform-specific configuration for CupertinoApp
class CupertinoAppData {
  const CupertinoAppData({
    this.color,
    this.showPerformanceOverlay = false,
    this.checkerboardRasterCacheImages = false,
    this.checkerboardOffscreenLayers = false,
    this.showSemanticsDebugger = false,
    this.debugShowCheckedModeBanner = false,
    this.shortcuts,
    this.actions,
    this.restorationScopeId,
    this.scrollBehavior,
  });

  final Color? color;
  final bool showPerformanceOverlay;
  final bool checkerboardRasterCacheImages;
  final bool checkerboardOffscreenLayers;
  final bool showSemanticsDebugger;
  final bool debugShowCheckedModeBanner;
  final Map<ShortcutActivator, Intent>? shortcuts;
  final Map<Type, Action<Intent>>? actions;
  final String? restorationScopeId;
  final ScrollBehavior? scrollBehavior;
}

/// Platform detection for configuration callbacks
enum PlatformTarget {
  /// Android platform
  android,

  /// iOS platform (any version)
  ios,

  /// iOS 26 or higher
  ios26Plus,

  /// iOS 18 or lower (pre-iOS 26)
  ios18OrLower,

  /// Web platform
  web,

  /// Desktop platforms (macOS, Windows, Linux)
  desktop,

  /// Unknown or other platforms
  other,
}

/// An adaptive app that uses MaterialApp for Android and CupertinoApp for iOS
///
/// This widget automatically selects the appropriate app widget based on the
/// current platform, providing a native look and feel.
///
/// Example:
/// ```dart
/// AdaptiveApp(
///   title: 'My App',
///   home: HomePage(),
///   themeMode: ThemeMode.system,
///   materialLightTheme: ThemeData.light(),
///   materialDarkTheme: ThemeData.dark(),
///   cupertinoLightTheme: CupertinoThemeData(brightness: Brightness.light),
///   cupertinoDarkTheme: CupertinoThemeData(brightness: Brightness.dark),
/// )
/// ```
class AdaptiveApp extends StatelessWidget {
  /// Creates an AdaptiveApp with navigation
  const AdaptiveApp({
    super.key,
    this.navigatorKey,
    this.home,
    this.routes = const <String, WidgetBuilder>{},
    this.initialRoute,
    this.onGenerateRoute,
    this.onGenerateInitialRoutes,
    this.onUnknownRoute,
    this.navigatorObservers = const <NavigatorObserver>[],
    this.builder,
    this.title = '',
    this.onGenerateTitle,
    this.themeMode,
    this.materialLightTheme,
    this.materialDarkTheme,
    this.cupertinoLightTheme,
    this.cupertinoDarkTheme,
    this.locale,
    this.localizationsDelegates,
    this.localeListResolutionCallback,
    this.localeResolutionCallback,
    this.supportedLocales = const <Locale>[Locale('en', 'US')],
    this.material,
    this.cupertino,
  })  : routerConfig = null,
        routeInformationProvider = null,
        routeInformationParser = null,
        routerDelegate = null,
        backButtonDispatcher = null;

  /// Creates an AdaptiveApp with router support
  const AdaptiveApp.router({
    super.key,
    this.routerConfig,
    this.routeInformationProvider,
    this.routeInformationParser,
    this.routerDelegate,
    this.backButtonDispatcher,
    this.builder,
    this.title = '',
    this.onGenerateTitle,
    this.themeMode,
    this.materialLightTheme,
    this.materialDarkTheme,
    this.cupertinoLightTheme,
    this.cupertinoDarkTheme,
    this.locale,
    this.localizationsDelegates,
    this.localeListResolutionCallback,
    this.localeResolutionCallback,
    this.supportedLocales = const <Locale>[Locale('en', 'US')],
    this.material,
    this.cupertino,
  })  : navigatorKey = null,
        home = null,
        routes = const <String, WidgetBuilder>{},
        initialRoute = null,
        onGenerateRoute = null,
        onGenerateInitialRoutes = null,
        onUnknownRoute = null,
        navigatorObservers = const <NavigatorObserver>[];

  // Navigation properties
  final GlobalKey<NavigatorState>? navigatorKey;
  final Widget? home;
  final Map<String, WidgetBuilder> routes;
  final String? initialRoute;
  final RouteFactory? onGenerateRoute;
  final InitialRouteListFactory? onGenerateInitialRoutes;
  final RouteFactory? onUnknownRoute;
  final List<NavigatorObserver> navigatorObservers;

  // Router properties
  final RouterConfig<Object>? routerConfig;
  final RouteInformationProvider? routeInformationProvider;
  final RouteInformationParser<Object>? routeInformationParser;
  final RouterDelegate<Object>? routerDelegate;
  final BackButtonDispatcher? backButtonDispatcher;

  // Common properties
  final TransitionBuilder? builder;
  final String title;
  final GenerateAppTitle? onGenerateTitle;

  // Theme properties
  final ThemeMode? themeMode;
  final ThemeData? materialLightTheme;
  final ThemeData? materialDarkTheme;
  final CupertinoThemeData? cupertinoLightTheme;
  final CupertinoThemeData? cupertinoDarkTheme;

  // Localization properties
  final Locale? locale;
  final Iterable<LocalizationsDelegate<dynamic>>? localizationsDelegates;
  final LocaleListResolutionCallback? localeListResolutionCallback;
  final LocaleResolutionCallback? localeResolutionCallback;
  final Iterable<Locale> supportedLocales;

  // Platform-specific configuration callbacks
  final MaterialAppData Function(BuildContext, PlatformTarget)? material;
  final CupertinoAppData Function(BuildContext, PlatformTarget)? cupertino;

  @override
  Widget build(BuildContext context) {
    final platform = _detectPlatform();
    final isRouter = routerConfig != null ||
        routerDelegate != null ||
        routeInformationParser != null;

    if (PlatformInfo.isIOS) {
      return _buildCupertinoApp(context, platform, isRouter);
    }

    return _buildMaterialApp(context, platform, isRouter);
  }

  Widget _buildCupertinoApp(
      BuildContext context, PlatformTarget platform, bool isRouter) {
    final config = cupertino?.call(context, platform) ?? const CupertinoAppData();

    // Determine theme based on themeMode
    CupertinoThemeData? effectiveTheme;
    if (themeMode == ThemeMode.dark) {
      effectiveTheme = cupertinoDarkTheme;
    } else if (themeMode == ThemeMode.light) {
      effectiveTheme = cupertinoLightTheme;
    } else {
      // ThemeMode.system - let CupertinoApp handle it
      final brightness = MediaQuery.platformBrightnessOf(context);
      effectiveTheme = brightness == Brightness.dark
          ? cupertinoDarkTheme
          : cupertinoLightTheme;
    }

    if (isRouter) {
      return CupertinoApp.router(
        key: key,
        routerConfig: routerConfig,
        routeInformationProvider: routeInformationProvider,
        routeInformationParser: routeInformationParser,
        routerDelegate: routerDelegate,
        backButtonDispatcher: backButtonDispatcher,
        builder: builder,
        title: title,
        onGenerateTitle: onGenerateTitle,
        color: config.color,
        theme: effectiveTheme,
        locale: locale,
        localizationsDelegates: localizationsDelegates,
        localeListResolutionCallback: localeListResolutionCallback,
        localeResolutionCallback: localeResolutionCallback,
        supportedLocales: supportedLocales,
        showPerformanceOverlay: config.showPerformanceOverlay,
        checkerboardRasterCacheImages: config.checkerboardRasterCacheImages,
        checkerboardOffscreenLayers: config.checkerboardOffscreenLayers,
        showSemanticsDebugger: config.showSemanticsDebugger,
        debugShowCheckedModeBanner: config.debugShowCheckedModeBanner,
        shortcuts: config.shortcuts,
        actions: config.actions,
        restorationScopeId: config.restorationScopeId,
        scrollBehavior: config.scrollBehavior,
      );
    }

    return CupertinoApp(
      key: key,
      navigatorKey: navigatorKey,
      home: home,
      routes: routes,
      initialRoute: initialRoute,
      onGenerateRoute: onGenerateRoute,
      onGenerateInitialRoutes: onGenerateInitialRoutes,
      onUnknownRoute: onUnknownRoute,
      navigatorObservers: navigatorObservers,
      builder: builder,
      title: title,
      onGenerateTitle: onGenerateTitle,
      color: config.color,
      theme: effectiveTheme,
      locale: locale,
      localizationsDelegates: localizationsDelegates,
      localeListResolutionCallback: localeListResolutionCallback,
      localeResolutionCallback: localeResolutionCallback,
      supportedLocales: supportedLocales,
      showPerformanceOverlay: config.showPerformanceOverlay,
      checkerboardRasterCacheImages: config.checkerboardRasterCacheImages,
      checkerboardOffscreenLayers: config.checkerboardOffscreenLayers,
      showSemanticsDebugger: config.showSemanticsDebugger,
      debugShowCheckedModeBanner: config.debugShowCheckedModeBanner,
      shortcuts: config.shortcuts,
      actions: config.actions,
      restorationScopeId: config.restorationScopeId,
      scrollBehavior: config.scrollBehavior,
    );
  }

  Widget _buildMaterialApp(
      BuildContext context, PlatformTarget platform, bool isRouter) {
    final config = material?.call(context, platform) ?? const MaterialAppData();

    if (isRouter) {
      return MaterialApp.router(
        key: key,
        routerConfig: routerConfig,
        routeInformationProvider: routeInformationProvider,
        routeInformationParser: routeInformationParser,
        routerDelegate: routerDelegate,
        backButtonDispatcher: backButtonDispatcher,
        builder: builder,
        title: title,
        onGenerateTitle: onGenerateTitle,
        color: config.color,
        theme: materialLightTheme,
        darkTheme: materialDarkTheme,
        themeMode: themeMode,
        locale: locale,
        localizationsDelegates: localizationsDelegates,
        localeListResolutionCallback: localeListResolutionCallback,
        localeResolutionCallback: localeResolutionCallback,
        supportedLocales: supportedLocales,
        debugShowMaterialGrid: config.debugShowMaterialGrid,
        showPerformanceOverlay: config.showPerformanceOverlay,
        checkerboardRasterCacheImages: config.checkerboardRasterCacheImages,
        checkerboardOffscreenLayers: config.checkerboardOffscreenLayers,
        showSemanticsDebugger: config.showSemanticsDebugger,
        debugShowCheckedModeBanner: config.debugShowCheckedModeBanner,
        shortcuts: config.shortcuts,
        actions: config.actions,
        restorationScopeId: config.restorationScopeId,
        scrollBehavior: config.scrollBehavior,
        highContrastTheme: config.highContrastTheme,
        highContrastDarkTheme: config.highContrastDarkTheme,
      );
    }

    return MaterialApp(
      key: key,
      navigatorKey: navigatorKey,
      home: home,
      routes: routes,
      initialRoute: initialRoute,
      onGenerateRoute: onGenerateRoute,
      onGenerateInitialRoutes: onGenerateInitialRoutes,
      onUnknownRoute: onUnknownRoute,
      navigatorObservers: navigatorObservers,
      builder: builder,
      title: title,
      onGenerateTitle: onGenerateTitle,
      color: config.color,
      theme: materialLightTheme,
      darkTheme: materialDarkTheme,
      themeMode: themeMode,
      locale: locale,
      localizationsDelegates: localizationsDelegates,
      localeListResolutionCallback: localeListResolutionCallback,
      localeResolutionCallback: localeResolutionCallback,
      supportedLocales: supportedLocales,
      debugShowMaterialGrid: config.debugShowMaterialGrid,
      showPerformanceOverlay: config.showPerformanceOverlay,
      checkerboardRasterCacheImages: config.checkerboardRasterCacheImages,
      checkerboardOffscreenLayers: config.checkerboardOffscreenLayers,
      showSemanticsDebugger: config.showSemanticsDebugger,
      debugShowCheckedModeBanner: config.debugShowCheckedModeBanner,
      shortcuts: config.shortcuts,
      actions: config.actions,
      restorationScopeId: config.restorationScopeId,
      scrollBehavior: config.scrollBehavior,
      highContrastTheme: config.highContrastTheme,
      highContrastDarkTheme: config.highContrastDarkTheme,
    );
  }

  PlatformTarget _detectPlatform() {
    if (PlatformInfo.isIOS26OrHigher()) {
      return PlatformTarget.ios26Plus;
    } else if (PlatformInfo.isIOS18OrLower()) {
      return PlatformTarget.ios18OrLower;
    } else if (PlatformInfo.isIOS) {
      return PlatformTarget.ios;
    } else if (PlatformInfo.isAndroid) {
      return PlatformTarget.android;
    } else if (PlatformInfo.isWeb) {
      return PlatformTarget.web;
    } else if (PlatformInfo.isMacOS) {
      return PlatformTarget.desktop;
    }
    return PlatformTarget.other;
  }
}
