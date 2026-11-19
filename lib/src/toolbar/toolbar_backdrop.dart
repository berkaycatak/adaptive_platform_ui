import 'dart:ui' show ImageFilter;

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

/// Paints behind the controls within the horizontal toolbar or Duo title band.
class ToolbarBackdrop extends StatelessWidget {
  const ToolbarBackdrop({
    super.key,
    required this.style,
    required this.titleOnly,
  });

  final AdaptiveScrollEdgeEffectStyle style;
  final bool titleOnly;

  @override
  Widget build(BuildContext context) => switch (style) {
    AdaptiveScrollEdgeEffectStyle.none => const SizedBox.shrink(),
    AdaptiveScrollEdgeEffectStyle.soft =>
      titleOnly ? const DuoTitleBackdrop() : const _SoftBackdrop(),
    AdaptiveScrollEdgeEffectStyle.hard => const _HardBackdrop(),
  };
}

class _HardBackdrop extends StatelessWidget {
  const _HardBackdrop();

  @override
  Widget build(BuildContext context) {
    final dark = CupertinoTheme.brightnessOf(context) == Brightness.dark;
    final surface = CupertinoColors.systemBackground.resolveFrom(context);
    // The native dark hairline approximates 10% white over the filtered edge.
    final separator = dark
        ? const Color(0x1AFFFFFF)
        : CupertinoColors.opaqueSeparator.resolveFrom(context);
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
                  bottom: BorderSide(color: separator, width: pixel),
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
                      child: CustomPaint(painter: _HardEdgeGradient.blurMask),
                    ),
                    if (dark)
                      CustomPaint(painter: _HardEdgeGradient.darkShadows),
                    CustomPaint(
                      painter: _HardEdgeGradient.tint(surface, dark: dark),
                    ),
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

class _HardEdgeGradient extends CustomPainter {
  const _HardEdgeGradient(this.gradient, this.blendMode);

  factory _HardEdgeGradient.tint(Color surface, {required bool dark}) =>
      _HardEdgeGradient(
        _gradient(
          surface,
          (t) => 1 - _transmission(t, dark ? _darkEdgeTransmission : 0.70),
        ),
        BlendMode.srcOver,
      );

  final LinearGradient gradient;
  final BlendMode blendMode;
  static const _height = 32.0;
  static const _intervals = 16;
  static const _titleTransmission = 0.20;
  static const _darkEdgeTransmission = 0.60;

  static double _transmission(double t, double atEdge) =>
      _titleTransmission + (atEdge - _titleTransmission) * t * t * t;

  // Black in overlay mode darkens shadows and preserves white. As the tint
  // clears, compensate for exactly that change on dark pixels so an empty
  // surface keeps its tone all the way from the title to the separator.
  static final darkShadows = _HardEdgeGradient(
    _gradient(
      const Color(0xFF000000),
      (t) => 1 - _titleTransmission / _transmission(t, _darkEdgeTransmission),
    ),
    BlendMode.overlay,
  );

  // Applied inside the stronger blur layer so both blurs crossfade.
  static final blurMask = _HardEdgeGradient(
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
      (i) => color.withValues(alpha: opacityAt(i / _intervals)),
    ),
  );

  @override
  void paint(Canvas canvas, Size size) {
    final falloff = Rect.fromLTWH(
      0,
      size.height - _height,
      size.width,
      _height,
    );
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..blendMode = blendMode
        ..shader = gradient.createShader(falloff),
    );
  }

  @override
  bool shouldRepaint(_HardEdgeGradient oldDelegate) =>
      gradient != oldDelegate.gradient || blendMode != oldDelegate.blendMode;
}

/// The soft gradient that keeps the bar readable over scrolling content.
class _SoftBackdrop extends StatelessWidget {
  const _SoftBackdrop();

  @override
  Widget build(BuildContext context) {
    final dark = MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    final base = dark ? const Color(0xFF000000) : const Color(0xFFFFFFFF);
    return IgnorePointer(
      child: OverflowBox(
        alignment: Alignment.topCenter,
        maxHeight: double.infinity,
        child: Container(
          // Runs on below the bar for a smooth fade into the content.
          height:
              MediaQuery.viewPaddingOf(context).top +
              kToolbarContentHeight +
              30,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: const [0.0, 0.4, 0.7, 1.0],
              colors: [
                base.withValues(alpha: 0.85),
                base.withValues(alpha: 0.6),
                base.withValues(alpha: 0.2),
                base.withValues(alpha: 0.0),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
