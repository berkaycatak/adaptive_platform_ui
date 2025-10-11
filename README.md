# Adaptive Platform UI

A Flutter package that provides adaptive platform-specific widgets with native iOS 26+ designs, traditional Cupertino widgets for older iOS versions, and Material Design for Android.

  <img src="https://github.com/berkaycatak/adaptive_platform_ui/blob/main/img/highlight-img.png?raw=true" alt="iOS 26 Native Toolbar">

## iOS 26+ Native Toolbar & Tab Bar

<p align="center">
  <img src="https://github.com/berkaycatak/adaptive_platform_ui/raw/main/img/appbar.gif" alt="iOS 26 Native Toolbar" width="300"/>
  <img src="https://github.com/berkaycatak/adaptive_platform_ui/raw/main/img/bottombar.gif" alt="iOS 26 Native Tab Bar" width="300"/>
</p>

  <img src="https://github.com/berkaycatak/adaptive_platform_ui/blob/main/img/bottom_nav2_p.png?raw=true" alt="iOS 26 Native Tab Bar">

  <img src="https://github.com/berkaycatak/adaptive_platform_ui/blob/main/img/toolbar2_p.png?raw=true" alt="iOS 26 Native Tab Bar">


Native iOS 26 UIToolbar and UITabBar with Liquid Glass blur effects, minimize behavior, and native gesture handling.

## Features

**AdaptiveApp** - Unified app configuration for all platforms:
- Separate themes for Material (Android) and Cupertino (iOS)
- Full theme mode support (light, dark, system)
- Router support via `AdaptiveApp.router()`
- Zero configuration required

**iOS 26+ Native Designs** - Modern iOS 26 components with:
- **Native UIToolbar** - Liquid Glass blur effects with native iOS 26 design
- **Native UITabBar** - Tab bar with minimize behavior and smooth animations
- **Native UIButton** - Button styles with spring animations and haptic feedback
- **Native UISegmentedControl** - Segmented controls with SF Symbol support
- **Native UISwitch & UISlider** - Switches and sliders with native animations
- Native corner radius and shadows
- Smooth spring animations
- Dynamic color system (light/dark mode)
- Multiple component styles

**iOS Legacy Support** - Traditional Cupertino widgets for iOS 18 and below

**Material Design** - Full Material 3 support for Android

**Automatic Platform Detection** - Zero configuration required

**Version-Aware Rendering** - Automatically selects appropriate widget based on iOS version

## Widget Showcase

### AdaptiveScaffold with Native Toolbar & Tab Bar

Adaptive Appbar:
<img src="https://github.com/berkaycatak/adaptive_platform_ui/blob/main/img/toolbar_p.png?raw=true" alt="iOS 26 Native Toolbar">

```dart
AdaptiveScaffold(
  title: 'My App',
  actions: [
    AdaptiveAppBarAction(
      onPressed: () {},
      iosSymbol: 'gear',
      androidIcon: Icons.settings,
    ),
  ],
  destinations: [
    AdaptiveNavigationDestination(
      icon: 'house.fill',
      label: 'Home',
    ),
    AdaptiveNavigationDestination(
      icon: 'person.fill',
      label: 'Profile',
    ),
  ],
  selectedIndex: 0,
  onDestinationSelected: (index) {},
  body: YourContent(),
)
```
Adaptive Bottom Navigation Bar (Destinations):
<p align="center">
  <img src="https://raw.githubusercontent.com/berkaycatak/adaptive_platform_ui/refs/heads/main/img/bottom_nav_p.png" alt="Native Toolbar"/>
</p>


### AdaptiveButton

<img src="https://raw.githubusercontent.com/berkaycatak/adaptive_platform_ui/refs/heads/main/img/buttons_p.png" alt="iOS 26 Native Toolbar">


```dart
// Basic button with label
AdaptiveButton(
  onPressed: () {},
  label: 'Click Me',
)

// Button with custom child
AdaptiveButton.child(
  onPressed: () {},
  child: Row(
    children: [
      Icon(Icons.add),
      Text('Add Item'),
    ],
  ),
)

// Icon button
AdaptiveButton.icon(
  onPressed: () {},
  icon: Icons.favorite,
)
```

### AdaptiveAlertDialog
<img src="https://raw.githubusercontent.com/berkaycatak/adaptive_platform_ui/refs/heads/main/img/alert_p.png" alt="iOS 26 Native Toolbar">


```dart
showAdaptiveAlertDialog(
  context: context,
  title: 'Confirm',
  message: 'Are you sure?',
  icon: 'checkmark.circle.fill',
  actions: [
    AlertAction(
      title: 'Cancel',
      style: AlertActionStyle.cancel,
      onPressed: () => Navigator.pop(context),
    ),
    AlertAction(
      title: 'Confirm',
      style: AlertActionStyle.primary,
      onPressed: () {
        Navigator.pop(context);
        // Do something
      },
    ),
  ],
);
```

### AdaptivePopupMenuButton

<p align="center">
<img src="https://raw.githubusercontent.com/berkaycatak/adaptive_platform_ui/refs/heads/main/img/popup_p.png" alt="iOS 26 Native Popup">
</p>

```dart
AdaptivePopupMenuButton<String>(
  buttonLabel: 'Options',
  items: [
    PopupMenuItem(value: 'edit', label: 'Edit', icon: 'pencil'),
    PopupMenuItem(value: 'delete', label: 'Delete', icon: 'trash', destructive: true),
    PopupMenuItem(value: 'share', label: 'Share', icon: 'square.and.arrow.up'),
  ],
  onSelected: (value) {
    print('Selected: $value');
  },
)
```

### AdaptiveSegmentedControl

<p align="center">
  <img src="https://github.com/berkaycatak/adaptive_platform_ui/raw/main/img/segmented_control.gif" alt="Segmented Control" width="300"/>
</p>

```dart
AdaptiveSegmentedControl(
  labels: ['One', 'Two', 'Three'],
  selectedIndex: 0,
  onValueChanged: (index) {
    print('Selected: $index');
  },
)

// With icons (SF Symbols on iOS)
AdaptiveSegmentedControl(
  labels: [],
  sfSymbols: [
    'house.fill',
    'person.fill',
    'gear',
  ],
  selectedIndex: 0,
  onValueChanged: (index) {},
  iconColor: CupertinoColors.systemBlue,
)
```

### AdaptiveSwitch

<p align="center">
  <img src="https://github.com/berkaycatak/adaptive_platform_ui/raw/main/img/switch.gif" alt="Adaptive Switch" width="300"/>
</p>

```dart
AdaptiveSwitch(
  value: true,
  onChanged: (value) {
    print('Switch: $value');
  },
)
```

### AdaptiveSlider

<p align="center">
  <img src="https://github.com/berkaycatak/adaptive_platform_ui/raw/main/img/slider.gif" alt="Adaptive Slider" width="300"/>
</p>

```dart
AdaptiveSlider(
  value: 0.5,
  onChanged: (value) {
    print('Slider: $value');
  },
  min: 0.0,
  max: 1.0,
)
```

### AdaptiveCheckbox

```dart
AdaptiveCheckbox(
  value: true,
  onChanged: (value) {
    print('Checkbox: $value');
  },
)

// Tristate checkbox
AdaptiveCheckbox(
  value: null, // Can be true, false, or null
  tristate: true,
  onChanged: (value) {
    print('Checkbox: $value');
  },
)
```

### AdaptiveRadio

```dart
enum Options { option1, option2, option3 }
Options? _selectedOption = Options.option1;

AdaptiveRadio<Options>(
  value: Options.option1,
  groupValue: _selectedOption,
  onChanged: (Options? value) {
    setState(() {
      _selectedOption = value;
    });
  },
)
```

### AdaptiveCard

```dart
AdaptiveCard(
  padding: EdgeInsets.all(16),
  child: Text('Card Content'),
)

// Card with custom styling
AdaptiveCard(
  padding: EdgeInsets.all(16),
  color: Colors.blue.withValues(alpha: 0.1),
  borderRadius: BorderRadius.circular(20),
  elevation: 8, // Android only
  child: Column(
    children: [
      Text('Custom Card'),
      Text('With multiple elements'),
    ],
  ),
)
```

### AdaptiveBadge

```dart
AdaptiveBadge(
  count: 5,
  child: Icon(Icons.notifications),
)

// Badge with text label
AdaptiveBadge(
  label: 'NEW',
  backgroundColor: Colors.red,
  child: Icon(Icons.mail),
)

// Large badge
AdaptiveBadge(
  count: 99,
  isLarge: true,
  child: Icon(Icons.message),
)
```

### AdaptiveTooltip

```dart
AdaptiveTooltip(
  message: 'This is a tooltip',
  child: Icon(Icons.info),
)

// Tooltip positioned above
AdaptiveTooltip(
  message: 'Tooltip appears above',
  preferBelow: false,
  child: Icon(Icons.help),
)
```

## Usage

### Button Styles

```dart
// Filled button (primary action)
AdaptiveButton(
  onPressed: () {},
  style: AdaptiveButtonStyle.filled,
  label: 'Filled',
)

// Tinted button (secondary action)
AdaptiveButton(
  onPressed: () {},
  style: AdaptiveButtonStyle.tinted,
  label: 'Tinted',
)

// Gray button (neutral action)
AdaptiveButton(
  onPressed: () {},
  style: AdaptiveButtonStyle.gray,
  label: 'Gray',
)

// Bordered button
AdaptiveButton(
  onPressed: () {},
  style: AdaptiveButtonStyle.bordered,
  label: 'Bordered',
)

// Plain text button
AdaptiveButton(
  onPressed: () {},
  style: AdaptiveButtonStyle.plain,
  label: 'Plain',
)
```

### Button Sizes

```dart
// Small button (28pt height on iOS)
AdaptiveButton(
  onPressed: () {},
  size: AdaptiveButtonSize.small,
  label: 'Small',
)

// Medium button (36pt height on iOS) - default
AdaptiveButton(
  onPressed: () {},
  size: AdaptiveButtonSize.medium,
  label: 'Medium',
)

// Large button (44pt height on iOS)
AdaptiveButton(
  onPressed: () {},
  size: AdaptiveButtonSize.large,
  label: 'Large',
)
```

### Custom Styling

```dart
AdaptiveButton(
  onPressed: () {},
  label: 'Custom Button',
  color: Colors.red,
  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
  borderRadius: BorderRadius.circular(16),
  minSize: Size(200, 50),
)
```

### Disabled State

```dart
AdaptiveButton(
  onPressed: () {},
  label: 'Disabled',
  enabled: false,
)
```

## Platform Detection

Use the `PlatformInfo` utility class to check platform and iOS version:

```dart
import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';

// Check platform
if (PlatformInfo.isIOS) {
  print('Running on iOS');
}

if (PlatformInfo.isAndroid) {
  print('Running on Android');
}

// Check iOS version
if (PlatformInfo.isIOS26OrHigher()) {
  print('Using iOS 26+ features');
}

if (PlatformInfo.isIOS18OrLower()) {
  print('Using legacy iOS widgets');
}

// Get iOS version number
int version = PlatformInfo.iOSVersion; // e.g., 26

// Check version range
if (PlatformInfo.isIOSVersionInRange(24, 26)) {
  print('iOS version is between 24 and 26');
}

// Get platform description
String description = PlatformInfo.platformDescription; // e.g., "iOS 26"
```

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  adaptive_platform_ui: ^0.1.0
```

Then run:

```bash
flutter pub get
```

## Quick Start

### AdaptiveApp - Platform-Specific App Configuration

Use `AdaptiveApp` to automatically configure your app for each platform:

```dart
import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AdaptiveApp(
      title: 'My App',
      themeMode: ThemeMode.system,
      materialLightTheme: ThemeData.light(),
      materialDarkTheme: ThemeData.dark(),
      cupertinoLightTheme: const CupertinoThemeData(
        brightness: Brightness.light,
      ),
      cupertinoDarkTheme: const CupertinoThemeData(
        brightness: Brightness.dark,
      ),
      home: const HomePage(),
    );
  }
}
```

**With Router Support (GoRouter, etc.):**

```dart
AdaptiveApp.router(
  routerConfig: router,
  title: 'My App',
  themeMode: ThemeMode.system,
  materialLightTheme: ThemeData.light(),
  materialDarkTheme: ThemeData.dark(),
  cupertinoLightTheme: const CupertinoThemeData(
    brightness: Brightness.light,
  ),
  cupertinoDarkTheme: const CupertinoThemeData(
    brightness: Brightness.dark,
  ),
)
```

**Key Features:**
- 🎨 Separate themes for Material (Android) and Cupertino (iOS)
- 🌓 Full theme mode support (light, dark, system)
- 🔄 Automatic platform detection
- 🚀 Router support via `AdaptiveApp.router()`
- 🛠️ Platform-specific callbacks for advanced configuration


## iOS 26 Native Features

When running on iOS 26+, widgets automatically use **native UIKit platform views** with Liquid Glass design:

### Platform Architecture
- **Native UIKit Views**: Uses `UiKitView` to render actual iOS 26 UIKit components
- **Platform Channels**: Bidirectional communication between Flutter and native iOS code
- **Liquid Glass Design**: Authentic iOS 26 visual effects rendered by UIKit
- **Zero Overhead**: No custom painting or emulation - pure native rendering

### Visual Features
- **Modern corner radius**: Native iOS 26 design language
- **Dynamic shadows**: Subtle multi-layer shadows
- **Spring animations**: Smooth spring damping with 0.95x scale on press
- **Native color system**: Uses iOS system colors with proper light/dark mode support
- **Liquid Glass effects**: Native iOS 26 translucency and blur effects
- **SF Symbols**: Native SF Symbol rendering with hierarchical color support

### Interaction
- **Press states**: Visual feedback with scale animation
- **Gesture handling**: Native UIKit gesture recognizers
- **Haptic feedback**: Medium impact feedback on interactions
- **Disabled states**: Proper opacity and interaction blocking

### Typography
- **SF Pro font**: Native iOS system font with proper weights
- **Dynamic Type**: Respects system font size settings
- **Weight**: Appropriate font weights for each component

## Example App

Run the example app to see all widgets in action:

```bash
cd example
flutter run
```

The example app includes:
- Platform information display
- All widget types showcase
- Interactive demos
- Style and size comparisons
- Dark mode support

## Widget Catalog

Currently available adaptive widgets:

- ✅ **AdaptiveApp** - Platform-specific app configuration with theme support and router
- ✅ **AdaptiveScaffold** - Scaffold with native iOS 26 toolbar and tab bar
- ✅ **AdaptiveButton** - Buttons with iOS 26+ native designs
- ✅ **AdaptiveSegmentedControl** - Native segmented controls
- ✅ **AdaptiveSwitch** - Native switches
- ✅ **AdaptiveSlider** - Native sliders
- ✅ **AdaptiveCheckbox** - Checkboxes with adaptive styling
- ✅ **AdaptiveRadio** - Radio button groups with adaptive styling
- ✅ **AdaptiveCard** - Cards with platform-specific styling
- ✅ **AdaptiveBadge** - Notification badges with adaptive styling
- ✅ **AdaptiveTooltip** - Platform-specific tooltips
- ✅ **AdaptiveAlertDialog** - Native alert dialogs
- ✅ **AdaptivePopupMenuButton** - Native popup menus

## Design Philosophy

This package follows Apple's Human Interface Guidelines for iOS and Material Design guidelines for Android. The goal is to provide:

1. **Native Look & Feel**: Widgets that feel at home on each platform
2. **Zero Configuration**: Automatic platform detection and adaptation
3. **Version Awareness**: Leverage new platform features while maintaining backward compatibility
4. **Consistency**: Unified API across platforms
5. **Customization**: Allow overrides when needed

## iOS Version Support

- **iOS 26+**: Modern native iOS 26 designs
- **iOS 18 and below**: Traditional Cupertino widgets
- **Automatic fallback**: Seamless degradation for older versions

## Requirements

- Flutter SDK: >=1.17.0
- Dart SDK: ^3.9.2

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Inspired by cupertino_native
- Design guidelines from Apple's Human Interface Guidelines
- Material Design guidelines from Google

## Author

Berkay Çatak

## Support

For issues, feature requests, or questions, please file an issue on the [GitHub repository](https://github.com/berkaycatak/adaptive_platform_ui/issues).
