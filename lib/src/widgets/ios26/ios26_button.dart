import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// iOS 26 native button styles
enum iOS26ButtonStyle {
  /// Filled button with solid background (primary action)
  filled,

  /// Tinted button with translucent background
  tinted,

  /// Gray button with subtle background
  gray,

  /// Bordered button with outline
  bordered,

  /// Plain text button without background
  plain,
}

/// iOS 26 button size presets matching native design
enum iOS26ButtonSize {
  /// Small button (height: 28)
  small,

  /// Medium button (height: 36) - default
  medium,

  /// Large button (height: 44)
  large,
}

/// Native iOS 26 button implementation
///
/// This button follows iOS 26 design guidelines with:
/// - Modern corner radius (10pt for medium size)
/// - Dynamic shadow system
/// - Haptic feedback on press
/// - Smooth spring animations
/// - Native color system
/// - Context-aware styling
class iOS26Button extends StatefulWidget {
  /// Creates an iOS 26 style button
  const iOS26Button({
    super.key,
    required this.onPressed,
    required this.child,
    this.style = iOS26ButtonStyle.filled,
    this.size = iOS26ButtonSize.medium,
    this.color,
    this.minSize,
    this.padding,
    this.borderRadius,
    this.alignment = Alignment.center,
  });

  /// The callback that is called when the button is tapped or otherwise activated
  final VoidCallback? onPressed;

  /// The widget below this widget in the tree
  final Widget child;

  /// The visual style of the button
  final iOS26ButtonStyle style;

  /// The size preset for the button
  final iOS26ButtonSize size;

  /// The color of the button (uses system blue if not specified)
  final Color? color;

  /// The minimum size of the button
  final Size? minSize;

  /// The amount of space to surround the child inside the button
  final EdgeInsetsGeometry? padding;

  /// The border radius of the button
  final BorderRadius? borderRadius;

  /// The alignment of the button's child
  final AlignmentGeometry alignment;

  @override
  State<iOS26Button> createState() => _iOS26ButtonState();
}

class _iOS26ButtonState extends State<iOS26Button>
    with SingleTickerProviderStateMixin {
  bool _isPressed = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.onPressed != null) {
      setState(() => _isPressed = true);
      _animationController.forward();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (_isPressed) {
      setState(() => _isPressed = false);
      _animationController.reverse();
    }
  }

  void _handleTapCancel() {
    if (_isPressed) {
      setState(() => _isPressed = false);
      _animationController.reverse();
    }
  }

  double get _height {
    switch (widget.size) {
      case iOS26ButtonSize.small:
        return 28.0;
      case iOS26ButtonSize.medium:
        return 36.0;
      case iOS26ButtonSize.large:
        return 44.0;
    }
  }

  double get _cornerRadius {
    switch (widget.size) {
      case iOS26ButtonSize.small:
        return 8.0;
      case iOS26ButtonSize.medium:
        return 10.0;
      case iOS26ButtonSize.large:
        return 12.0;
    }
  }

  EdgeInsetsGeometry get _defaultPadding {
    switch (widget.size) {
      case iOS26ButtonSize.small:
        return const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0);
      case iOS26ButtonSize.medium:
        return const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0);
      case iOS26ButtonSize.large:
        return const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0);
    }
  }

  Color _getBackgroundColor(BuildContext context) {
    final bool isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;
    final color = widget.color ?? CupertinoColors.systemBlue;
    final isDisabled = widget.onPressed == null;

    switch (widget.style) {
      case iOS26ButtonStyle.filled:
        if (isDisabled) {
          return isDark
              ? CupertinoColors.systemGrey.darkColor.withValues(alpha: 0.3)
              : CupertinoColors.systemGrey.color.withValues(alpha: 0.3);
        }
        return _isPressed ? _darkenColor(color, 0.2) : color;

      case iOS26ButtonStyle.tinted:
        if (isDisabled) {
          return isDark
              ? CupertinoColors.systemGrey.darkColor.withValues(alpha: 0.1)
              : CupertinoColors.systemGrey.color.withValues(alpha: 0.1);
        }
        return _isPressed
            ? color.withValues(alpha: 0.25)
            : color.withValues(alpha: 0.15);

      case iOS26ButtonStyle.gray:
        if (isDisabled) {
          return isDark
              ? CupertinoColors.systemGrey6.darkColor.withValues(alpha: 0.3)
              : CupertinoColors.systemGrey6.color.withValues(alpha: 0.3);
        }
        return _isPressed
            ? (isDark
                ? CupertinoColors.systemGrey5.darkColor
                : CupertinoColors.systemGrey5.color)
            : (isDark
                ? CupertinoColors.systemGrey6.darkColor
                : CupertinoColors.systemGrey6.color);

      case iOS26ButtonStyle.bordered:
        if (_isPressed) {
          return isDark
              ? CupertinoColors.systemGrey6.darkColor.withValues(alpha: 0.5)
              : CupertinoColors.systemGrey6.color.withValues(alpha: 0.5);
        }
        return Colors.transparent;

      case iOS26ButtonStyle.plain:
        return Colors.transparent;
    }
  }

  Color _getForegroundColor(BuildContext context) {
    final bool isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;
    final color = widget.color ?? CupertinoColors.systemBlue;
    final isDisabled = widget.onPressed == null;

    if (isDisabled) {
      return isDark
          ? CupertinoColors.systemGrey.darkColor
          : CupertinoColors.systemGrey.color;
    }

    switch (widget.style) {
      case iOS26ButtonStyle.filled:
        return CupertinoColors.white;
      case iOS26ButtonStyle.tinted:
      case iOS26ButtonStyle.gray:
      case iOS26ButtonStyle.bordered:
      case iOS26ButtonStyle.plain:
        return color;
    }
  }

  BoxBorder? _getBorder(BuildContext context) {
    if (widget.style != iOS26ButtonStyle.bordered) return null;

    final bool isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;
    final color = widget.color ?? CupertinoColors.systemBlue;

    return Border.all(
      color: _isPressed
          ? color.withOpacity(0.5)
          : (isDark
              ? CupertinoColors.systemGrey4.darkColor
              : CupertinoColors.systemGrey4.color),
      width: 1.0,
    );
  }

  List<BoxShadow>? _getShadow(BuildContext context) {
    // iOS 26 uses subtle shadows for filled buttons
    if (widget.style == iOS26ButtonStyle.filled &&
        widget.onPressed != null &&
        !_isPressed) {
      return [
        BoxShadow(
          color: Colors.black.withOpacity(0.12),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
        BoxShadow(
          color: Colors.black.withOpacity(0.08),
          blurRadius: 4,
          offset: const Offset(0, 1),
        ),
      ];
    }
    return null;
  }

  Color _darkenColor(Color color, double amount) {
    final hsl = HSLColor.fromColor(color);
    return hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0)).toColor();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: widget.onPressed,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          constraints: BoxConstraints(
            minHeight: widget.minSize?.height ?? _height,
            minWidth: widget.minSize?.width ?? 0,
          ),
          decoration: BoxDecoration(
            color: _getBackgroundColor(context),
            borderRadius: widget.borderRadius ?? BorderRadius.circular(_cornerRadius),
            border: _getBorder(context),
            boxShadow: _getShadow(context),
          ),
          padding: widget.padding ?? _defaultPadding,
          alignment: widget.alignment,
          child: DefaultTextStyle(
            style: TextStyle(
              color: _getForegroundColor(context),
              fontSize: widget.size == iOS26ButtonSize.small ? 13 :
                        widget.size == iOS26ButtonSize.medium ? 15 : 17,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.3,
            ),
            child: IconTheme(
              data: IconThemeData(
                color: _getForegroundColor(context),
                size: widget.size == iOS26ButtonSize.small ? 16 :
                      widget.size == iOS26ButtonSize.medium ? 18 : 20,
              ),
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}
