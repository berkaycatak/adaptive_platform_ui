import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:adaptive_platform_ui/src/widgets/minute_interval.dart';

void main() {
  group('alignDateTimeToInterval', () {
    test('interval <= 1 is a no-op', () {
      final dt = DateTime(2026, 7, 12, 14, 37);
      expect(alignDateTimeToInterval(dt, 1), dt);
      expect(alignDateTimeToInterval(dt, 0), dt);
    });

    test('rounds to nearest 15-minute mark', () {
      expect(
        alignDateTimeToInterval(DateTime(2026, 7, 12, 14, 37), 15),
        DateTime(2026, 7, 12, 14, 30),
      );
      expect(
        alignDateTimeToInterval(DateTime(2026, 7, 12, 14, 38), 15),
        DateTime(2026, 7, 12, 14, 45),
      );
      expect(
        alignDateTimeToInterval(DateTime(2026, 7, 12, 14, 7), 15),
        DateTime(2026, 7, 12, 14, 0),
      );
      expect(
        alignDateTimeToInterval(DateTime(2026, 7, 12, 14, 8), 15),
        DateTime(2026, 7, 12, 14, 15),
      );
    });

    test('minute overflow rolls into the next hour', () {
      expect(
        alignDateTimeToInterval(DateTime(2026, 7, 12, 14, 53), 15),
        DateTime(2026, 7, 12, 15, 0),
      );
    });

    test('already-aligned values are unchanged', () {
      final dt = DateTime(2026, 7, 12, 15, 0);
      expect(alignDateTimeToInterval(dt, 15), dt);
    });
  });

  group('alignTimeOfDayToInterval', () {
    test('rounds to nearest 15-minute mark', () {
      expect(
        alignTimeOfDayToInterval(const TimeOfDay(hour: 9, minute: 7), 15),
        const TimeOfDay(hour: 9, minute: 0),
      );
      expect(
        alignTimeOfDayToInterval(const TimeOfDay(hour: 9, minute: 8), 15),
        const TimeOfDay(hour: 9, minute: 15),
      );
    });

    test('overflow wraps within the day', () {
      expect(
        alignTimeOfDayToInterval(const TimeOfDay(hour: 23, minute: 53), 15),
        const TimeOfDay(hour: 0, minute: 0),
      );
    });

    test('interval <= 1 is a no-op', () {
      const t = TimeOfDay(hour: 9, minute: 7);
      expect(alignTimeOfDayToInterval(t, 1), t);
    });
  });
}
