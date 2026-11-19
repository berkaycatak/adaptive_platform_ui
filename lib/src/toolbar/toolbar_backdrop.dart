import 'dart:ui' show ImageFilter, lerpDouble;

import 'package:flutter/cupertino.dart';

import '../widgets/adaptive_app_bar.dart';
import 'duo_vertical_bar.dart';

/// Height of the horizontal iOS toolbar below the status bar.
const double kToolbarContentHeight = 44;

AdaptiveScrollEdgeEffectStyle visibleToolbarBackdrop(
  AdaptiveScrollEdgeEffectStyle style, {
  required bool scrolledUnder,
}) => style == AdaptiveScrollEdgeEffectStyle.hard && !scrolledUnder
    ? AdaptiveScrollEdgeEffectStyle.none
    : style;

/// The page-resolved colors and edge opacity of a hard toolbar.
typedef HardEdgeAppearance = ({
  Color surface,
  Color separator,
  double edgeOpacity,
});

HardEdgeAppearance resolveHardEdge(
  BuildContext context,
  Color? backgroundColor,
) {
  final dark = CupertinoTheme.brightnessOf(context) == Brightness.dark;
  return (
    // Match CupertinoPageScaffold, even when the fixed host is outside the
    // page's theme or the page overrides its background with a dynamic color.
    surface:
        CupertinoDynamicColor.maybeResolve(backgroundColor, context) ??
        CupertinoTheme.of(context).scaffoldBackgroundColor,
    separator: dark
        ? const Color(0x1AFFFFFF)
        : CupertinoColors.opaqueSeparator.resolveFrom(context),
    edgeOpacity: dark ? 0.40 : 0.30,
  );
}

HardEdgeAppearance lerpHardEdge(
  HardEdgeAppearance from,
  HardEdgeAppearance to,
  double t,
) => (
  surface: Color.lerp(from.surface, to.surface, t)!,
  separator: Color.lerp(from.separator, to.separator, t)!,
  edgeOpacity: lerpDouble(from.edgeOpacity, to.edgeOpacity, t)!,
);

/// Paints behind the controls within the horizontal toolbar or Duo title band.
class ToolbarBackdrop extends StatelessWidget {
  const ToolbarBackdrop({
    super.key,
    required this.style,
    required this.titleOnly,
    this.hardEdge,
  });

  final AdaptiveScrollEdgeEffectStyle style;
  final bool titleOnly;
  final HardEdgeAppearance? hardEdge;

  @override
  Widget build(BuildContext context) => switch (style) {
    AdaptiveScrollEdgeEffectStyle.none => const SizedBox.shrink(),
    AdaptiveScrollEdgeEffectStyle.soft =>
      titleOnly ? const DuoTitleBackdrop() : const _SoftBackdrop(),
    AdaptiveScrollEdgeEffectStyle.hard => _HardBackdrop(
      appearance: hardEdge ?? resolveHardEdge(context, null),
    ),
  };
}

class _HardBackdrop extends StatelessWidget {
  const _HardBackdrop({required this.appearance});

  final HardEdgeAppearance appearance;

  @override
  Widget build(BuildContext context) {
    final pixel = 1 / MediaQuery.devicePixelRatioOf(context);
    return IgnorePointer(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Extend only the paint below the controls. The bar still supplies
          // its usual content inset, and the exposed strip is scrollable.
          Positioned.fill(
            bottom: -12,
            child: DecoratedBox(
              position: DecorationPosition.foreground,
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: appearance.separator, width: pixel),
                ),
              ),
              child: ClipRect(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 0.55, sigmaY: 0.55),
                      child: const SizedBox.expand(),
                    ),
                    // Gaussian variances add. Over the lightly blurred page,
                    // this second pass gives a 2.4-point blur behind the title.
                    BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 2.34, sigmaY: 2.34),
                      child: CustomPaint(painter: _EdgeGradient.hardBlurMask),
                    ),
                    CustomPaint(painter: _EdgeGradient.hardTint(appearance)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EdgeGradient extends CustomPainter {
  const _EdgeGradient(this.gradient, this.blendMode, {this.falloffHeight = 32});

  factory _EdgeGradient.hardTint(HardEdgeAppearance appearance) {
    // Native hard edges leave about 10% of the scrolling content visible at
    // title height. The tint gradually clears toward the separator.
    const titleOpacity = 0.90;
    return _EdgeGradient(
      _gradient(
        appearance.surface,
        (t) => titleOpacity + (appearance.edgeOpacity - titleOpacity) * t * t,
      ),
      BlendMode.srcOver,
    );
  }

  final LinearGradient gradient;
  final BlendMode blendMode;
  final double falloffHeight;
  static const _intervals = 16;

  // Applied inside the stronger blur layer so both blurs crossfade.
  static final hardBlurMask = _EdgeGradient(
    _gradient(const Color(0xFFFFFFFF), (t) => 1 - t * t * (3 - 2 * t)),
    BlendMode.dstIn,
  );

  static LinearGradient _gradient(
    Color color,
    double Function(double) opacityAt,
  ) => LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: List.generate(
      _intervals + 1,
      (i) => color.withValues(alpha: color.a * opacityAt(i / _intervals)),
    ),
  );

  @override
  void paint(Canvas canvas, Size size) {
    final falloff = Rect.fromLTWH(
      0,
      size.height - falloffHeight,
      size.width,
      falloffHeight,
    );
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..blendMode = blendMode
        ..shader = gradient.createShader(falloff),
    );
  }

  @override
  bool shouldRepaint(_EdgeGradient oldDelegate) =>
      gradient != oldDelegate.gradient ||
      blendMode != oldDelegate.blendMode ||
      falloffHeight != oldDelegate.falloffHeight;
}

/// The horizontal soft edge blurs scrolling detail before it reaches the bar.
class _SoftBackdrop extends StatelessWidget {
  const _SoftBackdrop();

  static final _blur = ImageFilter.blur(sigmaX: 1.5, sigmaY: 1.5);
  // Fine detail clears from 24 points above the bottom of the toolbar to
  // 16 below it. Measure the falloff from that edge in every orientation.
  static const _blurMask = _EdgeGradient(
    LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFFFFFFFF),
        Color(0xE6FFFFFF),
        Color(0xA8FFFFFF),
        Color(0x52FFFFFF),
        Color(0x00FFFFFF),
      ],
    ),
    BlendMode.dstIn,
    falloffHeight: 40,
  );

  @override
  Widget build(BuildContext context) {
    final dark = MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    final base = dark ? const Color(0xFF000000) : const Color(0xFFFFFFFF);
    return IgnorePointer(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            bottom: -16,
            child: ClipRect(
              child: BackdropFilter(
                filter: _blur,
                child: const CustomPaint(painter: _blurMask),
              ),
            ),
          ),
          Positioned.fill(
            bottom: -44,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.0, 0.4, 0.7, 0.9, 1.0],
                  colors: [
                    base.withValues(alpha: 0.85),
                    base.withValues(alpha: 0.6),
                    base.withValues(alpha: 0.2),
                    base.withValues(alpha: 0.025),
                    base.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
