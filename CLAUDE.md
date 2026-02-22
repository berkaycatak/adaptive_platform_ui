# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

A Flutter plugin (`adaptive_platform_ui`) that renders platform-adaptive widgets:
- **iOS 26+**: Native UIKit components with Liquid Glass design via platform views
- **iOS 18 and below**: Flutter Cupertino widgets
- **Android**: Flutter Material Design 3 widgets

The iOS native code lives under `ios/Classes/` (Swift). The Dart plugin code lives under `lib/`.

## Build & Development Commands

```bash
# Install dependencies
flutter pub get

# Static analysis (CI uses --fatal-infos)
flutter analyze --fatal-infos

# Run all tests
flutter test

# Run a single test file
flutter test test/adaptive_button_test.dart

# Run tests with coverage
flutter test --coverage

# Format code
dart format .

# Run example app (from repo root)
cd example && flutter pub get && flutter run

# Publish dry run
flutter pub publish --dry-run
```

CI uses Flutter 3.35.6 stable. CI pipeline: analyze -> test -> build example APK.

## Architecture

### Platform Rendering Decision

Every `Adaptive*` widget in `lib/src/widgets/` follows this pattern in `build()`:

```
PlatformInfo.isIOS26OrHigher() → iOS 26+ native widget (lib/src/widgets/ios26/)
PlatformInfo.isIOS             → CupertinoWidget
else (Android)                 → MaterialWidget
```

`PlatformInfo` (`lib/src/platform/platform_info.dart`) parses `Platform.operatingSystemVersion` to detect the iOS major version.

### Flutter-to-Native Bridge (iOS 26+)

Each native component has three parts:

1. **Dart side** (`lib/src/widgets/ios26/ios26_*.dart`): Creates a `UiKitView` with `viewType: 'adaptive_platform_ui/ios26_{component}'`, passes configuration as `creationParams`, and sets up a `MethodChannel` with pattern `adaptive_platform_ui/{component}_{instanceId}` for callbacks.

2. **Swift factory** (`ios/Classes/iOS26*View.swift`): Implements `FlutterPlatformViewFactory`, registered in `AdaptivePlatformUiPlugin.swift`.

3. **Swift view** (same file): Implements `FlutterPlatformView`, creates native UIKit components, handles method channel calls back to Dart.

### Plugin Registration

`ios/Classes/AdaptivePlatformUiPlugin.swift` registers all platform view factories. Android plugin (`android/`) is a no-op stub since Material widgets are pure Dart.

### Key Widget Hierarchy

`AdaptiveApp` (supports both standard and `.router()` GoRouter constructors) wraps separate Material and Cupertino theme configurations. `AdaptiveScaffold` orchestrates app bar, body, bottom navigation, and FAB, with iOS 26+ modes for native toolbar and native tab bar.

### iOS 26+ Native Components (Swift)

Located in `ios/Classes/`:
- Button, Switch, Slider, SegmentedControl (input controls)
- ToolbarPlatformView (UINavigationBar with Liquid Glass)
- TabBarPlatformView (UITabBar with badges)
- AlertDialogView, PopupMenuButtonView (dialogs)
- BlurViewPlatformView (Liquid Glass blur effect)
- ScaffoldManager, NativeTabBarManager (layout coordination)
- SearchTabBarController (**experimental** - replaces Flutter root view controller, not production-ready)

## Conventions

- **Commit messages**: Conventional commits (`feat:`, `fix:`, `docs:`, `refactor:`, `test:`, `chore:`)
- **Releases**: Update version in `pubspec.yaml` + `CHANGELOG.md`, tag with `v` prefix (e.g., `v0.1.101`), push tag to trigger release workflow
- **CHANGELOG format**: `## [version]` header with `* **NEW**:`, `* **FIX**:`, `* **IMPROVEMENT**:` entries
- **New widgets**: Follow the `Adaptive*` naming pattern, implement all three platform paths, add test file in `test/`, add demo page in `example/lib/pages/demos/`
- **Colors in platform channels**: Passed as ARGB integers or hex strings
- **Icons for iOS 26+**: Use `SFSymbol` class (`lib/src/style/sf_symbol.dart`) for native Apple SF Symbols
