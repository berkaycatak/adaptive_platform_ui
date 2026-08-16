import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../platform/platform_info.dart';
import 'adaptive_time_picker.dart';
import 'minute_interval.dart';

/// An adaptive date picker that renders platform-specific styles
///
/// On iOS: Shows CupertinoDatePicker in a modal bottom sheet
/// On Android: Shows Material DatePickerDialog
class AdaptiveDatePicker {
  AdaptiveDatePicker._();

  /// Shows a platform-adaptive date picker
  ///
  /// Returns the selected [DateTime] or null if cancelled
  static Future<DateTime?> show({
    required BuildContext context,
    required DateTime initialDate,
    DateTime? firstDate,
    DateTime? lastDate,
    CupertinoDatePickerMode mode = CupertinoDatePickerMode.date,
    DatePickerMode initialDatePickerMode = DatePickerMode.day,
    bool use24HourFormat = false,
    int minuteInterval = 1,
  }) async {
    final effectiveFirstDate = firstDate ?? DateTime(1900);
    final effectiveLastDate = lastDate ?? DateTime(2100);

    if (PlatformInfo.isIOS) {
      return _showCupertinoDatePicker(
        context: context,
        initialDate: initialDate,
        firstDate: effectiveFirstDate,
        lastDate: effectiveLastDate,
        mode: mode,
        use24HourFormat: use24HourFormat,
        minuteInterval: minuteInterval,
      );
    }

    return _showMaterialDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: effectiveFirstDate,
      lastDate: effectiveLastDate,
      mode: mode,
      use24HourFormat: use24HourFormat,
      initialDatePickerMode: initialDatePickerMode,
      minuteInterval: minuteInterval,
    );
  }

  static Future<DateTime?> _showCupertinoDatePicker({
    required BuildContext context,
    required DateTime initialDate,
    required DateTime firstDate,
    required DateTime lastDate,
    required CupertinoDatePickerMode mode,
    required bool use24HourFormat,
    required int minuteInterval,
  }) async {
    // CupertinoDatePicker asserts the initial value already sits on the grid.
    final alignedInitial = alignDateTimeToInterval(initialDate, minuteInterval);
    DateTime selectedDate = alignedInitial;

    return showCupertinoModalPopup<DateTime>(
      context: context,
      builder: (BuildContext context) {
        return _CupertinoDatePickerContent(
          initialDate: alignedInitial,
          firstDate: firstDate,
          lastDate: lastDate,
          mode: mode,
          use24HourFormat: use24HourFormat,
          minuteInterval: minuteInterval,
          onDateSelected: (date) => selectedDate = date,
        );
      },
    ).then((result) => result != null ? selectedDate : null);
  }

  static Future<DateTime?> _showMaterialDatePicker({
    required BuildContext context,
    required DateTime initialDate,
    required DateTime firstDate,
    required DateTime lastDate,
    required CupertinoDatePickerMode mode,
    required bool use24HourFormat,
    required DatePickerMode initialDatePickerMode,
    required int minuteInterval,
  }) async {
    DateTime date = initialDate;
    if (mode != CupertinoDatePickerMode.time) {
      // Material has no native month-year picker; force year-only entry and
      // normalize to the 1st so callers still get a usable DateTime.
      final isMonthYear = mode == CupertinoDatePickerMode.monthYear;
      final picked = await showDatePicker(
        context: context,
        initialDate: initialDate,
        firstDate: firstDate,
        lastDate: lastDate,
        initialDatePickerMode:
            isMonthYear ? DatePickerMode.year : initialDatePickerMode,
      );
      if (picked == null) return null;
      date = isMonthYear ? DateTime(picked.year, picked.month, 1) : picked;
    }
    if (mode == CupertinoDatePickerMode.date ||
        mode == CupertinoDatePickerMode.monthYear) {
      return DateTime(date.year, date.month, date.day);
    }
    if (!context.mounted) return null;
    final time = await AdaptiveTimePicker.show(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialDate),
      use24HourFormat: use24HourFormat,
      minuteInterval: minuteInterval,
    );
    if (time == null) return null;
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }
}

/// Internal widget that properly updates when theme changes
class _CupertinoDatePickerContent extends StatefulWidget {
  const _CupertinoDatePickerContent({
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
    required this.mode,
    required this.use24HourFormat,
    required this.minuteInterval,
    required this.onDateSelected,
  });

  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;
  final CupertinoDatePickerMode mode;
  final bool use24HourFormat;
  final int minuteInterval;
  final ValueChanged<DateTime> onDateSelected;

  @override
  State<_CupertinoDatePickerContent> createState() =>
      _CupertinoDatePickerContentState();
}

class _CupertinoDatePickerContentState
    extends State<_CupertinoDatePickerContent> {
  late DateTime selectedDate;

  @override
  void initState() {
    super.initState();
    selectedDate = widget.initialDate;
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
                  onPressed: () => Navigator.of(context).pop(selectedDate),
                  child: Text(
                    MaterialLocalizations.of(context).okButtonLabel,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          // Date picker
          Expanded(
            child: CupertinoDatePicker(
              mode: widget.mode,
              use24hFormat: widget.use24HourFormat,
              minuteInterval: widget.minuteInterval,
              initialDateTime: widget.initialDate,
              minimumDate: widget.firstDate,
              maximumDate: widget.lastDate,
              onDateTimeChanged: (DateTime newDate) {
                setState(() {
                  selectedDate = newDate;
                });
                widget.onDateSelected(newDate);
              },
            ),
          ),
        ],
      ),
    );
  }
}
