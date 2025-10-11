# Changelog

## 0.1.3

* **BREAKING CHANGE**: Renamed `AdaptiveScaffold.child` parameter to `body` to match standard Scaffold API
* **NEW**: Added `AdaptiveApp` widget for automatic platform-specific app configuration
  * `AdaptiveApp()` - Constructor for normal navigation
  * `AdaptiveApp.router()` - Constructor for router-based navigation (GoRouter, etc.)
  * Direct theme parameters: `themeMode`, `materialLightTheme`, `materialDarkTheme`, `cupertinoLightTheme`, `cupertinoDarkTheme`
  * Platform-specific callbacks: `material()` and `cupertino()` for advanced configuration
  * Automatic platform detection (iOS uses CupertinoApp, Android uses MaterialApp)
  * Full support for all MaterialApp and CupertinoApp properties
* Debug banner now hidden by default (`debugShowCheckedModeBanner: false`)
* Updated all example code to use new `body` parameter

## 0.1.2

* Fix image links in README.md to use GitHub raw URLs
* Images now display correctly on pub.dev

## 0.1.1

* Documentation improvements
* Added comprehensive README with images for all widgets
* Added visual showcase for toolbar, tab bar, buttons, segmented controls, switches, sliders, alerts, and popup menus
* Improved code examples and usage documentation

## 0.1.0

* Initial release with iOS 26+ support
* Features:
  * `AdaptiveScaffold` - Platform-adaptive scaffold with native iOS 26 toolbar and tab bar
  * `AdaptiveButton` - Adaptive buttons with iOS 26 Liquid Glass design
  * `AdaptiveSegmentedControl` - Native segmented controls for all platforms
  * `AdaptiveSwitch` - Platform-adaptive switches
  * `AdaptiveSlider` - Platform-adaptive sliders
  * `AdaptiveAlertDialog` - Native alert dialogs
  * `AdaptivePopupMenuButton` - Platform-adaptive popup menus
* iOS 26+ features:
  * Native UIToolbar with Liquid Glass blur effects
  * Native UITabBar with minimize behavior
  * Native UISegmentedControl
  * Native SF Symbol support
  * Haptic feedback
  * Automatic light/dark mode adaptation
* Platform support:
  * iOS 26+ with native Liquid Glass designs
  * iOS <26 (iOS 18 and below) with traditional Cupertino widgets
  * Android with Material Design 3
