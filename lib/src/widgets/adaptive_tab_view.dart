import 'package:flutter/material.dart';
import '../platform/platform_info.dart';
import 'adaptive_segmented_control.dart';

/// An adaptive tab bar view (horizontal swipeable tabs)
///
/// Shows tabs at the top with a swipeable content area below
///
/// On iOS 26+: Uses native iOS 26 segmented control with Liquid Glass + PageView
/// On iOS <26: Uses CupertinoSegmentedControl + PageView
/// On Android: Uses Material TabBar + TabBarView
///
/// Example:
/// ```dart
/// AdaptiveTabBarView(
///   tabs: ['Tab 1', 'Tab 2', 'Tab 3'],
///   children: [
///     Page1(),
///     Page2(),
///     Page3(),
///   ],
/// )
/// ```
class AdaptiveTabBarView extends StatefulWidget {
  /// Creates an adaptive tab bar view
  const AdaptiveTabBarView({
    super.key,
    required this.tabs,
    required this.children,
    this.onTabChanged,
    this.backgroundColor,
    this.selectedColor,
    this.unselectedColor,
    this.selectedLabelColor,
  });

  /// Tab labels
  final List<String> tabs;

  /// Tab content pages
  final List<Widget> children;

  /// Callback when tab changes
  final ValueChanged<int>? onTabChanged;

  /// Background color for the tab bar
  /// On iOS: Background color of the segmented control
  /// On Android: Background color of the TabBar. Null paints the theme's
  /// primary colour with white labels; any other colour, including
  /// `Colors.transparent`, gets labels that contrast with it (#37).
  final Color? backgroundColor;

  /// Color for the selected tab
  /// On iOS: Thumb color of the selected segment; its label switches to a
  /// contrasting colour unless [selectedLabelColor] is set
  /// On Android: Label and indicator color of the selected tab
  final Color? selectedColor;

  /// Color for unselected tabs
  /// On iOS: Text color of unselected segments
  /// On Android: Label color of unselected tabs
  final Color? unselectedColor;

  /// Label color of the selected tab on every platform. Null derives it:
  /// from [selectedColor] on iOS (white on a dark thumb, black on a light
  /// one) and from [backgroundColor] on Android.
  final Color? selectedLabelColor;

  /// White on dark colours, black on light ones, for text drawn over [on].
  static Color contrastingLabelFor(Color on) =>
      ThemeData.estimateBrightnessForColor(on) == Brightness.dark
      ? Colors.white
      : Colors.black;

  @override
  State<AdaptiveTabBarView> createState() => _AdaptiveTabBarViewState();
}

class _AdaptiveTabBarViewState extends State<AdaptiveTabBarView>
    with SingleTickerProviderStateMixin {
  late PageController _pageController;
  late TabController _materialController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _materialController = TabController(
      length: widget.tabs.length,
      vsync: this,
    );
    _materialController.addListener(_handleMaterialTabChanged);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _materialController.removeListener(_handleMaterialTabChanged);
    _materialController.dispose();
    super.dispose();
  }

  void _handleMaterialTabChanged() {
    if (_materialController.indexIsChanging) {
      widget.onTabChanged?.call(_materialController.index);
    }
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
    widget.onTabChanged?.call(index);
  }

  void _onSegmentChanged(int index) {
    if (index != _currentIndex) {
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  /// The selected segment's label on iOS: the caller's choice, else a
  /// colour that contrasts with the thumb when one was given (#37).
  Color? get _iosSelectedLabelColor {
    if (widget.selectedLabelColor != null) return widget.selectedLabelColor;
    final thumb = widget.selectedColor;
    return thumb == null ? null : AdaptiveTabBarView.contrastingLabelFor(thumb);
  }

  @override
  Widget build(BuildContext context) {
    // iOS implementation - Uses AdaptiveSegmentedControl
    // On iOS 26+: Native segmented control with Liquid Glass
    // On iOS <26: CupertinoSlidingSegmentedControl
    if (PlatformInfo.isIOS) {
      return Column(
        children: [
          // iOS segmented control as tab bar
          Container(
            color: widget.backgroundColor,
            padding: const EdgeInsets.all(16.0),
            child: AdaptiveSegmentedControl(
              labels: widget.tabs,
              selectedIndex: _currentIndex,
              onValueChanged: _onSegmentChanged,
              height: 40.0,
              color: widget.selectedColor,
              textColor: widget.unselectedColor,
              selectedTextColor: _iosSelectedLabelColor,
            ),
          ),
          // Content with PageView for iOS
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: _onPageChanged,
              children: widget.children,
            ),
          ),
        ],
      );
    }

    // Android - Material Design implementation
    if (PlatformInfo.isAndroid) {
      final theme = Theme.of(context);
      final defaultBackgroundColor =
          widget.backgroundColor ?? theme.primaryColor;
      // Labels must contrast with what they are drawn on: white on the
      // primary-coloured bar, the surface text colour on a transparent or
      // light custom background (#37).
      final bg = widget.backgroundColor;
      final Color onBackground = bg == null
          ? Colors.white
          : bg.a < 0.5 ||
                ThemeData.estimateBrightnessForColor(bg) == Brightness.light
          ? theme.colorScheme.onSurface
          : Colors.white;
      final defaultSelectedColor = widget.selectedColor ?? onBackground;
      final defaultSelectedLabelColor =
          widget.selectedLabelColor ?? defaultSelectedColor;
      final defaultUnselectedColor =
          widget.unselectedColor ?? onBackground.withValues(alpha: 0.7);

      return Column(
        children: [
          Material(
            color: defaultBackgroundColor,
            child: TabBar(
              controller: _materialController,
              tabs: widget.tabs.map((label) => Tab(text: label)).toList(),
              indicatorColor: defaultSelectedColor,
              labelColor: defaultSelectedLabelColor,
              unselectedLabelColor: defaultUnselectedColor,
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _materialController,
              children: widget.children,
            ),
          ),
        ],
      );
    }

    // Fallback - iOS style
    return Column(
      children: [
        Container(
          color: widget.backgroundColor,
          padding: const EdgeInsets.all(16.0),
          child: AdaptiveSegmentedControl(
            labels: widget.tabs,
            selectedIndex: _currentIndex,
            onValueChanged: _onSegmentChanged,
            height: 40.0,
            color: widget.selectedColor,
            textColor: widget.unselectedColor,
            selectedTextColor: _iosSelectedLabelColor,
          ),
        ),
        Expanded(
          child: PageView(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            children: widget.children,
          ),
        ),
      ],
    );
  }
}
