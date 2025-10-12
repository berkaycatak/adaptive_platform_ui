# Changelog

## 0.1.4+1
  * Updated README.md

## 0.1.4

* **NEW**: Added `AdaptiveCard` widget for platform-specific card styling
  * iOS: Custom iOS-style card with Cupertino design (border, subtle shadow, rounded corners)
  * Android: Material Design Card with elevation support
  * Support for custom colors, border radius, padding, margin, and clip behavior
* **NEW**: Added `AdaptiveRadio` widget for radio button groups
  * iOS: Custom iOS-style radio with circular design
  * Android: Material Design Radio
  * Support for custom colors, toggleable mode, and disabled state
* **NEW**: Added `AdaptiveBadge` widget for notification badges
  * iOS: Custom iOS-style badge with rounded design
  * Android: Material Design Badge
  * Support for count/label display, custom colors, show zero option, and large size
* **NEW**: Added `AdaptiveTooltip` widget for platform-specific tooltips
  * iOS: Custom iOS-style tooltip with animation and theme support
  * Android: Material Design Tooltip
  * Long press/tap to show, auto-hide after duration
* **NEW**: Added `AdaptiveCheckbox` widget (Cupertino & Material only)
  * iOS: Custom iOS-style checkbox with Cupertino design
  * Android: Material Design Checkbox
  * Support for tristate, custom colors, and dark/light mode
* **EXPERIMENTAL**: Added `IOS26NativeSearchTabBar` for iOS 26+ native search tab bar
  * App-level UITabBarController integration replacing Flutter's navigation
  * Native search tab transformation with UISearchController
  * Liquid Glass effects and native animations
  * Method channel for Flutter ↔ Native communication
  * Search query callbacks and tab selection handling
  * ⚠️ **WARNING**: This feature is highly experimental and unstable:
    - Replaces Flutter's root view controller
    - Breaks widget lifecycle and state management
    - Hot reload may not work properly
    - Navigation stack becomes invalid
    - Only recommended for prototyping and demos
  * See demo page for detailed technical explanation of architectural conflicts
* Added comprehensive demo pages for all new widgets

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
