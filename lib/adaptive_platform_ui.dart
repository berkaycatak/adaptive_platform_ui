/// A Flutter package that provides adaptive platform-specific widgets
///
/// This package automatically renders native-looking widgets based on the platform:
/// - iOS 26+: Modern iOS 26 native designs with latest visual styles
/// - iOS <26: Traditional Cupertino widgets
/// - Android: Material Design widgets
///
/// ## Features
///
/// - Automatic platform detection
/// - iOS version-specific widget rendering
/// - Native iOS 26 designs following Apple's Human Interface Guidelines
/// - Seamless fallback to appropriate widgets for older iOS versions
/// - Material Design for Android
///
/// ## Usage
///
/// ```dart
/// import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
///
/// AdaptiveButton(
///   onPressed: () {
///     print('Button pressed');
///   },
///   child: Text('Click Me'),
/// )
/// ```
library;

// Platform utilities
export 'src/platform/platform_info.dart';

// Styles
export 'src/style/sf_symbol.dart';

// Widgets
export 'src/widgets/adaptive_button.dart';

// iOS 26 specific widgets (for advanced usage)
export 'src/widgets/ios26/ios26_button.dart';
