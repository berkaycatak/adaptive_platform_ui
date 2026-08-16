import 'package:flutter_test/flutter_test.dart';
// Import via the public barrel — this also proves IOSSpringCurve is exported.
import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';

void main() {
  group('IOSSpringCurve', () {
    const curve = IOSSpringCurve();

    test('endpoints are exact', () {
      // Curve.transform short-circuits the exact endpoints.
      expect(curve.transform(0.0), 0.0);
      expect(curve.transform(1.0), 1.0);
    });

    test('overshoots above 1.0 in the mid-range (clamp regression guard)', () {
      // The spring is underdamped (damping ratio ~0.9), so the simulation
      // overshoots its target before settling. This is the regression guard
      // for the removed `.clamp(0, 1)` — if it is ever re-added, this fails.
      final samples = <double, double>{};
      for (var i = 1; i <= 19; i++) {
        final t = i * 0.05; // 0.05 .. 0.95
        samples[t] = curve.transform(t);
      }
      final overshot = samples.values.any((v) => v > 1.0);
      expect(
        overshot,
        isTrue,
        reason: 'expected at least one sample > 1.0, got: $samples',
      );
    });

    test('all sampled values are finite', () {
      for (var i = 0; i <= 20; i++) {
        final t = i * 0.05; // 0.0 .. 1.0
        final v = curve.transform(t);
        expect(v.isFinite, isTrue, reason: 'transform($t) = $v is not finite');
      }
    });
  });
}
