# Adaptive Platform UI

A Flutter package that provides adaptive platform-specific widgets with native iOS 26+ designs, traditional Cupertino widgets for older iOS versions, and Material Design for Android.

## Features

✨ **iOS 26+ Native Designs** - Modern iOS 26 button styles with:
- Native corner radius and shadows
- Smooth spring animations
- Dynamic color system (light/dark mode)
- Multiple button styles (filled, tinted, gray, bordered, plain)
- Three size presets (small, medium, large)

🍎 **iOS Legacy Support** - Traditional Cupertino widgets for iOS 25 and below

🤖 **Material Design** - Full Material 3 support for Android

🔍 **Automatic Platform Detection** - Zero configuration required

📱 **Version-Aware Rendering** - Automatically selects appropriate widget based on iOS version

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

## Usage

### Basic Button

```dart
import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';

AdaptiveButton(
  onPressed: () {
    print('Button pressed!');
  },
  child: Text('Click Me'),
)
```

This will automatically render:
- **iOS 26+**: Native iOS 26 filled button with modern styling
- **iOS <26**: CupertinoButton.filled
- **Android**: Material ElevatedButton

### Button Styles

```dart
// Filled button (primary action)
AdaptiveButton(
  onPressed: () {},
  style: AdaptiveButtonStyle.filled,
  child: Text('Filled'),
)

// Tinted button (secondary action)
AdaptiveButton(
  onPressed: () {},
  style: AdaptiveButtonStyle.tinted,
  child: Text('Tinted'),
)

// Gray button (neutral action)
AdaptiveButton(
  onPressed: () {},
  style: AdaptiveButtonStyle.gray,
  child: Text('Gray'),
)

// Bordered button
AdaptiveButton(
  onPressed: () {},
  style: AdaptiveButtonStyle.bordered,
  child: Text('Bordered'),
)

// Plain text button
AdaptiveButton(
  onPressed: () {},
  style: AdaptiveButtonStyle.plain,
  child: Text('Plain'),
)
```

### Button Sizes

```dart
// Small button (28pt height on iOS)
AdaptiveButton(
  onPressed: () {},
  size: AdaptiveButtonSize.small,
  child: Text('Small'),
)

// Medium button (36pt height on iOS) - default
AdaptiveButton(
  onPressed: () {},
  size: AdaptiveButtonSize.medium,
  child: Text('Medium'),
)

// Large button (44pt height on iOS)
AdaptiveButton(
  onPressed: () {},
  size: AdaptiveButtonSize.large,
  child: Text('Large'),
)
```

### Custom Styling

```dart
AdaptiveButton(
  onPressed: () {},
  color: Colors.red,
  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
  borderRadius: BorderRadius.circular(16),
  minSize: Size(200, 50),
  child: Text('Custom Button'),
)
```

### Disabled State

```dart
AdaptiveButton(
  onPressed: null, // null = disabled
  child: Text('Disabled'),
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

if (PlatformInfo.isIOS25OrLower()) {
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

## iOS 26 Native Button Features

When running on iOS 26+, buttons automatically use **native UIKit platform views** with Liquid Glass design:

### Platform Architecture
- **Native UIKit Views**: Uses `UiKitView` to render actual iOS 26 UIButton components
- **Platform Channels**: Bidirectional communication between Flutter and native iOS code
- **Liquid Glass Design**: Authentic iOS 26 visual effects rendered by UIKit
- **Zero Overhead**: No custom painting or emulation - pure native rendering

### Visual Features
- **Modern corner radius**: 10pt for medium, 8pt for small, 12pt for large
- **Dynamic shadows**: Subtle multi-layer shadows for filled buttons
- **Spring animations**: 0.95x scale on press with smooth spring damping
- **Native color system**: Uses iOS system colors with proper light/dark mode support
- **Liquid Glass effects**: Native iOS 26 translucency and blur effects

### Interaction
- **Press states**: Visual feedback with scale animation (0.95x on press)
- **Gesture handling**: Native UIButton gesture recognizers
- **Haptic feedback**: Medium impact feedback on button press
- **Disabled states**: Proper opacity (0.5) and interaction blocking

### Typography
- **SF Pro font**: Native iOS system font with proper weights
- **Size-appropriate text**: 13pt (small), 15pt (medium), 17pt (large)
- **Weight**: Medium for small/medium, Semibold for large

## Technical Architecture

### Native iOS 26 Implementation

The iOS 26 button implementation uses Flutter's platform views to embed native UIKit components:

#### Flutter Side (Dart)
```dart
// Creates a UiKitView that communicates with native iOS
UiKitView(
  viewType: 'adaptive_platform_ui/ios26_button',
  creationParams: {
    'style': 'filled',
    'label': 'Button',
    'enabled': true,
    // ... other configuration
  },
  creationParamsCodec: const StandardMessageCodec(),
)
```

#### Native iOS Side (Swift)
```swift
// iOS26ButtonView.swift - Creates actual UIButton with iOS 26 styling
let button = UIButton(type: .system)
button.layer.cornerRadius = 10
button.backgroundColor = .systemBlue

// Spring animation on press
UIView.animate(withDuration: 0.2, usingSpringWithDamping: 0.7) {
    self.button.transform = .identity
}

// Haptic feedback
let impact = UIImpactFeedbackGenerator(style: .medium)
impact.impactOccurred()
```

### Communication Flow
1. **Flutter → Native**: Button configuration sent via creation parameters
2. **Native → Flutter**: Button press events sent via method channel
3. **Flutter → Native**: Dynamic updates (color, style, enabled state) via method calls

## Advanced Usage

### Using iOS 26 Button Directly

For advanced use cases, you can use the iOS 26 button implementation directly:

```dart
import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';

iOS26Button(
  onPressed: () {},
  style: iOS26ButtonStyle.filled,
  size: iOS26ButtonSize.medium,
  color: CupertinoColors.systemBlue,
  child: Text('iOS 26 Button'),
)
```

**Note**: This will use native UIKit views on iOS 26+ and fall back to CupertinoButton on older versions.

## Example App

Run the example app to see all button styles and sizes in action:

```bash
cd example
flutter run
```

The example app includes:
- Platform information display
- Interactive button style selector
- Size comparison
- All button styles showcase
- Disabled state examples
- Press counter

## Widget Catalog

Currently available adaptive widgets:

- ✅ **AdaptiveButton** - Adaptive button with iOS 26+ native designs

Coming soon:
- 🚧 AdaptiveTabBar
- 🚧 AdaptiveSwitch
- 🚧 AdaptiveSlider
- 🚧 AdaptiveTextField
- 🚧 AdaptiveAlertDialog
- 🚧 AdaptiveNavigationBar
- 🚧 AdaptiveActivityIndicator
- 🚧 AdaptiveScaffold
- 🚧 AdaptiveDatePicker
- 🚧 AdaptiveContextMenu
- 🚧 AdaptiveSearchBar

## Design Philosophy

This package follows Apple's Human Interface Guidelines for iOS and Material Design guidelines for Android. The goal is to provide:

1. **Native Look & Feel**: Widgets that feel at home on each platform
2. **Zero Configuration**: Automatic platform detection and adaptation
3. **Version Awareness**: Leverage new platform features while maintaining backward compatibility
4. **Consistency**: Unified API across platforms
5. **Customization**: Allow overrides when needed

## iOS Version Support

- **iOS 26+**: Modern native iOS 26 designs
- **iOS 25 and below**: Traditional Cupertino widgets
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
