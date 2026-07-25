import 'package:flutter/material.dart';

/// Helpers to snap picked times onto a fixed minute grid (e.g. 15-minute
/// steps), keeping the iOS Cupertino and Android Material pickers consistent.
///
/// [CupertinoDatePicker] asserts that its `initialDateTime` already lies on the
/// `minuteInterval` grid, so callers must align the initial value before
/// handing it over — otherwise the picker throws at build time.

/// Round [dateTime] to the nearest multiple of [interval] minutes. Minute
/// overflow rolls into the following hour. An [interval] of 1 (or less) is a
/// no-op, preserving the default per-minute behaviour.
DateTime alignDateTimeToInterval(DateTime dateTime, int interval) {
  if (interval <= 1) return dateTime;
  final base = DateTime(dateTime.year, dateTime.month, dateTime.day, dateTime.hour);
  final roundedMinutes = (dateTime.minute / interval).round() * interval;
  return base.add(Duration(minutes: roundedMinutes));
}

/// Round [time] to the nearest multiple of [interval] minutes, wrapping within
/// the day. Used for the Material time picker, which has no native interval
/// support, so the selected value is snapped after the fact.
TimeOfDay alignTimeOfDayToInterval(TimeOfDay time, int interval) {
  if (interval <= 1) return time;
  final total = time.hour * 60 + time.minute;
  final rounded = (total / interval).round() * interval;
  return TimeOfDay(hour: (rounded ~/ 60) % 24, minute: rounded % 60);
}
