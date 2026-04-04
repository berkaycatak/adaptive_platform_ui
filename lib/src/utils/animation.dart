import 'package:flutter/animation.dart';
import 'package:flutter/physics.dart';

class IOSSpringCurve extends Curve {
  const IOSSpringCurve({
    this.stiffness = 100,
    this.damping = 18,
  });

  final double stiffness;
  final double damping;

  @override
  double transformInternal(double t) {
    final spring = SpringDescription(
      mass: 1,
      stiffness: stiffness,
      damping: damping,
    );
    // Simulate over a fixed duration window (e.g. 1.5s)
    // t is [0,1], so we map it into the spring's time domain
    final sim = SpringSimulation(spring, 0, 1, 0);
    return sim.x(t * 1.5).clamp(0.0, 1.0);
  }
}
