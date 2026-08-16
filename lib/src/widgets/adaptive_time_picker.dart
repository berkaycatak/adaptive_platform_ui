import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../platform/platform_info.dart';
import 'minute_interval.dart';

/// An adaptive time picker that renders platform-specific styles
///
/// On iOS: Shows CupertinoTimerPicker in a modal bottom sheet
/// On Android: Shows Material TimePickerDialog
class AdaptiveTimePicker {
  AdaptiveTimePicker._();

  /// Shows a platform-adaptive time picker
  ///
  /// Returns the selected [TimeOfDay] or null if cancelled.
  ///
  /// [minuteInterval] restricts results to a fixed minute grid (e.g. 15-minute
  /// steps). On iOS the Cupertino wheel only offers interval minutes; on
  /// Android the Material picker stays unrestricted and the confirmed value is
  /// snapped to the nearest interval.
  static Future<TimeOfDay?> show({
    required BuildContext context,
    required TimeOfDay initialTime,
    bool use24HourFormat = false,
    int minuteInterval = 1,
  }) async {
    if (PlatformInfo.isIOS) {
      return _showCupertinoTimePicker(
        context: context,
        initialTime: initialTime,
        use24HourFormat: use24HourFormat,
        minuteInterval: minuteInterval,
      );
    }

    // Android - Use Material TimePicker
    return _showMaterialTimePicker(
      context: context,
      initialTime: initialTime,
      use24HourFormat: use24HourFormat,
      minuteInterval: minuteInterval,
    );
  }

  static Future<TimeOfDay?> _showCupertinoTimePicker({
    required BuildContext context,
    required TimeOfDay initialTime,
    required bool use24HourFormat,
    required int minuteInterval,
  }) async {
    // Convert TimeOfDay to DateTime for CupertinoDatePicker; align onto the
    // grid first, as the picker asserts the initial value is a valid interval.
    final now = DateTime.now();
    DateTime selectedDateTime = alignDateTimeToInterval(
      DateTime(now.year, now.month, now.day, initialTime.hour, initialTime.minute),
      minuteInterval,
    );

    final result = await showCupertinoModalPopup<DateTime>(
      context: context,
      builder: (BuildContext context) {
        return _CupertinoTimePickerContent(
          initialDateTime: selectedDateTime,
          use24HourFormat: use24HourFormat,
          minuteInterval: minuteInterval,
          onTimeSelected: (dateTime) => selectedDateTime = dateTime,
        );
      },
    );

    if (result != null) {
      return TimeOfDay(
        hour: selectedDateTime.hour,
        minute: selectedDateTime.minute,
      );
    }
    return null;
  }

  static Future<TimeOfDay?> _showMaterialTimePicker({
    required BuildContext context,
    required TimeOfDay initialTime,
    required bool use24HourFormat,
    required int minuteInterval,
  }) async {
    final builder = use24HourFormat
        ? (BuildContext ctx, Widget? child) => MediaQuery(
              data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
              child: child!,
            )
        : null;

    // Material has no native minute stepping; snap the picked value onto the
    // grid afterwards instead (no-op for minuteInterval <= 1).
    final picked = await showTimePicker(
      context: context,
      initialTime: alignTimeOfDayToInterval(initialTime, minuteInterval),
      builder: builder,
    );
    if (picked == null) return null;
    return alignTimeOfDayToInterval(picked, minuteInterval);
  }
}

/// Internal widget that properly updates when theme changes
class _CupertinoTimePickerContent extends StatefulWidget {
  const _CupertinoTimePickerContent({
    required this.initialDateTime,
    required this.use24HourFormat,
    required this.minuteInterval,
    required this.onTimeSelected,
  });

  final DateTime initialDateTime;
  final bool use24HourFormat;
  final int minuteInterval;
  final ValueChanged<DateTime> onTimeSelected;

  @override
  State<_CupertinoTimePickerContent> createState() =>
      _CupertinoTimePickerContentState();
}

class _CupertinoTimePickerContentState
    extends State<_CupertinoTimePickerContent> {
  late DateTime selectedDateTime;

  @override
  void initState() {
    super.initState();
    selectedDateTime = widget.initialDateTime;
  }

  @override
  Widget build(BuildContext context) {
    // Use CupertinoTheme to get dynamic colors that update with theme changes
    final backgroundColor = CupertinoTheme.of(context).scaffoldBackgroundColor;
    final separatorColor = CupertinoDynamicColor.resolve(
      CupertinoColors.separator,
      context,
    );

    return Container(
      height: 280,
      color: backgroundColor,
      child: Column(
        children: [
          // Header with Done button
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: separatorColor, width: 0.5),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    PlatformInfo.isIOS
                        ? CupertinoLocalizations.of(context).cancelButtonLabel
                        : MaterialLocalizations.of(context).cancelButtonLabel,
                  ),
                ),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () => Navigator.of(context).pop(selectedDateTime),
                  child: Text(
                    MaterialLocalizations.of(context).okButtonLabel,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          // Time picker
          Expanded(
            child: CupertinoDatePicker(
              mode: CupertinoDatePickerMode.time,
              use24hFormat: widget.use24HourFormat,
              minuteInterval: widget.minuteInterval,
              initialDateTime: widget.initialDateTime,
              onDateTimeChanged: (DateTime newDateTime) {
                setState(() {
                  selectedDateTime = newDateTime;
                });
                widget.onTimeSelected(newDateTime);
              },
            ),
          ),
        ],
      ),
    );
  }
}
