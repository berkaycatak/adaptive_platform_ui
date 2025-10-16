# Contributing to Adaptive Platform UI

Thank you for your interest in contributing to Adaptive Platform UI! This document provides guidelines and instructions for contributing.

## Code of Conduct

Please be respectful and constructive in all interactions. We're here to build great software together.

## How to Contribute

### Reporting Bugs

1. **Search existing issues** to avoid duplicates
2. **Use the bug report template** when creating a new issue
3. **Provide detailed information**:
   - Clear description of the bug
   - Steps to reproduce
   - Expected vs actual behavior
   - Code sample
   - Environment details (Flutter version, platform, device)
   - Screenshots if applicable

### Suggesting Features

1. **Check existing feature requests** to avoid duplicates
2. **Use the feature request template**
3. **Explain the use case** and problem it solves
4. **Consider platform differences** (iOS vs Android behavior)
5. **Provide code examples** of proposed API

### Submitting Pull Requests

#### Before You Start

1. **Open an issue first** for major changes to discuss the approach
2. **Fork the repository** and create a branch from `main`
3. **Follow the existing code style** and conventions

#### Development Setup

```bash
# Clone your fork
git clone https://github.com/YOUR_USERNAME/adaptive_platform_ui.git
cd adaptive_platform_ui

# Install dependencies
flutter pub get

# Run the example app
cd example
flutter pub get
flutter run
```

#### Making Changes

1. **Create a feature branch**:
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Make your changes**:
   - Follow Dart style guide
   - Add documentation comments for public APIs
   - Keep platform-specific logic separated
   - Support both iOS 26+ and legacy iOS versions
   - Support Material Design for Android

3. **Test your changes**:
   - Test on both iOS and Android
   - Test on different iOS versions if applicable
   - Ensure no existing functionality breaks
   - Add demo examples to the example app

4. **Update documentation**:
   - Add/update widget documentation
   - Update README.md if needed
   - Update CHANGELOG.md with your changes
   - Add code examples

5. **Commit your changes**:
   ```bash
   git add .
   git commit -m "feat: Add new feature description"
   ```

   Follow conventional commit format:
   - `feat:` for new features
   - `fix:` for bug fixes
   - `docs:` for documentation
   - `refactor:` for code refactoring
   - `test:` for tests
   - `chore:` for maintenance

#### Submitting the PR

1. **Push to your fork**:
   ```bash
   git push origin feature/your-feature-name
   ```

2. **Create a Pull Request** from your fork to the main repository

3. **Fill out the PR template** completely:
   - Describe your changes
   - Link related issues
   - Show screenshots/videos if applicable
   - Check all relevant boxes in the checklist

4. **Wait for review**:
   - Address any feedback or requested changes
   - Be responsive to comments
   - Keep the PR focused and avoid unrelated changes

## Code Style Guidelines

### Dart Code

- Follow [Effective Dart](https://dart.dev/guides/language/effective-dart) guidelines
- Use `flutter analyze` to check for issues
- Format code with `dart format`
- Maximum line length: 80 characters (flexible for readability)

### Widget Structure

```dart
/// Documentation comment explaining the widget
///
/// Additional details about platform-specific behavior:
/// - iOS 26+: Native implementation details
/// - iOS <26: Fallback implementation
/// - Android: Material implementation
class AdaptiveWidget extends StatelessWidget {
  /// Creates an adaptive widget
  const AdaptiveWidget({
    super.key,
    required this.parameter,
    this.optionalParameter,
  });

  /// Required parameter description
  final String parameter;

  /// Optional parameter description
  final String? optionalParameter;

  @override
  Widget build(BuildContext context) {
    // Platform detection
    if (PlatformInfo.isIOS26OrHigher()) {
      return _buildIOS26Widget();
    }

    if (PlatformInfo.isIOS) {
      return _buildCupertinoWidget();
    }

    return _buildMaterialWidget();
  }

  // Private build methods...
}
```

### Platform-Specific Guidelines

#### iOS 26+ Native Widgets
- Use `UiKitView` for native rendering when needed
- Implement proper platform channels for communication
- Handle both light and dark mode
- Follow Apple's Human Interface Guidelines

#### iOS Legacy (iOS 18 and below)
- Use Cupertino widgets as fallback
- Ensure consistent behavior with iOS 26+ version
- Test on actual devices when possible

#### Android
- Use Material Design 3 widgets
- Follow Material Design guidelines
- Ensure proper theme integration

## Documentation Standards

### Widget Documentation

```dart
/// Brief one-line description
///
/// Longer description explaining the widget's purpose and behavior.
///
/// **Platform behavior:**
/// - **iOS 26+**: Native UIKit implementation with Liquid Glass effects
/// - **iOS <26**: CupertinoWidget with traditional styling
/// - **Android**: Material Design implementation
///
/// Example:
/// ```dart
/// AdaptiveWidget(
///   parameter: 'value',
///   onChanged: (value) {
///     print('Changed: $value');
///   },
/// )
/// ```
///
/// See also:
/// - [RelatedWidget] for similar functionality
/// - [AnotherWidget] for different use cases
class AdaptiveWidget extends StatelessWidget {
  // Implementation...
}
```

### README Updates

When adding new widgets:
1. Add to Widget Catalog section
2. Add usage example with code
3. Include screenshots if possible
4. Explain platform differences

### CHANGELOG Format

```markdown
## [version]
* **NEW**: Added `WidgetName` for description
  * Platform 1: Implementation details
  * Platform 2: Implementation details
  * Key features and parameters
* **FIX**: Fixed issue description
  * What was broken
  * How it's fixed
* **IMPROVEMENT**: Improvement description
  * Details of the improvement
```

## Testing Guidelines

### Manual Testing Checklist

- [ ] Test on iOS simulator (latest version)
- [ ] Test on iOS device (if possible)
- [ ] Test on Android emulator
- [ ] Test on Android device (if possible)
- [ ] Test light mode
- [ ] Test dark mode
- [ ] Test different screen sizes
- [ ] Test with different font sizes (accessibility)
- [ ] Test animations and transitions
- [ ] Verify no console errors or warnings

### Adding Examples

All new widgets should have examples in the example app:

1. Create a new demo page in `example/lib/pages/demos/`
2. Add route in `router_service.dart`
3. Add route constant in `route_constants.dart`
4. Add navigation item in `home_page.dart`
5. Show various use cases and parameters

## Questions?

- Open a [Discussion](https://github.com/berkaycatak/adaptive_platform_ui/discussions) for questions
- Check existing issues and PRs for similar topics
- Read the [README](../README.md) for documentation

## Thank You!

Your contributions help make Adaptive Platform UI better for everyone. We appreciate your time and effort!
