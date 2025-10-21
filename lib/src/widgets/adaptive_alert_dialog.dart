import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../platform/platform_info.dart';
import 'ios26/ios26_alert_dialog.dart';

export 'ios26/ios26_alert_dialog.dart' show AlertAction, AlertActionStyle;

/// Configuration for text input in alert dialog
class AdaptiveAlertDialogInput {
  /// Creates a text input configuration for alert dialog
  const AdaptiveAlertDialogInput({
    required this.placeholder,
    this.initialValue,
    this.keyboardType,
    this.obscureText = false,
    this.maxLength,
  });

  /// Placeholder text for the text field
  final String placeholder;

  /// Initial value for the text field
  final String? initialValue;

  /// Keyboard type for the text field
  final TextInputType? keyboardType;

  /// Whether to obscure the text (for passwords)
  final bool obscureText;

  /// Maximum length of the text input
  final int? maxLength;
}

/// An adaptive alert dialog that renders platform-specific styles
///
/// On iOS 26+: Uses native iOS 26 UIAlertController with Liquid Glass
/// On iOS <26 (iOS 18 and below): Uses CupertinoAlertDialog
/// On Android: Uses Material AlertDialog
class AdaptiveAlertDialog {
  AdaptiveAlertDialog._();

  /// Shows an adaptive alert dialog
  ///
  /// The [icon] parameter accepts:
  /// - iOS 26+: String (SF Symbol name, e.g., "checkmark.circle.fill")
  /// - iOS <26: IconData (e.g., CupertinoIcons.checkmark_alt_circle_fill)
  /// - Android: IconData (e.g., Icons.check_circle)
  ///
  /// The [input] parameter enables a text input field in the alert.
  /// When provided, the alert will include a text field for user input.
  /// The returned Future will contain the entered text value (or null if empty).
  static Future<String?> show({
    required BuildContext context,
    required String title,
    String? message,
    required List<AlertAction> actions,
    dynamic icon,
    double? iconSize,
    Color? iconColor,
    String? oneTimeCode,
    AdaptiveAlertDialogInput? input,
  }) {
    // iOS 26+ - Use native iOS 26 alert dialog
    if (PlatformInfo.isIOS26OrHigher()) {
      // Convert icon to String if needed for iOS 26 (expects SF Symbol)
      String? iconString;
      if (icon != null) {
        if (icon is String) {
          iconString = icon;
        }
        // If IconData is provided on iOS 26+, ignore it (iOS 26 uses SF Symbols)
      }

      return showCupertinoDialog<String?>(
        context: context,
        builder: (context) => IOS26AlertDialog(
          title: title,
          message: message,
          actions: actions,
          icon: iconString,
          iconSize: iconSize,
          iconColor: iconColor,
          oneTimeCode: oneTimeCode,
          input: input,
        ),
      );
    }

    // iOS 18 and below - Use CupertinoAlertDialog with custom content for OTP/icon/textfield
    if (PlatformInfo.isIOS) {
      final textController = TextEditingController(text: input?.initialValue);

      return showCupertinoDialog<String?>(
        context: context,
        builder: (context) {
          Widget? contentWidget;

          // Build custom content if icon, OTP, or textfield is present
          if (icon != null ||
              oneTimeCode != null ||
              message != null ||
              input != null) {
            contentWidget = ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: input != null ? 100 : 60,
                maxHeight: 300,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (icon != null &&
                        icon is IconData &&
                        iconSize != null) ...[
                      Icon(
                        icon,
                        size: iconSize,
                        color: iconColor ?? CupertinoColors.systemBlue,
                      ),
                      const SizedBox(height: 8),
                    ],
                    if (message != null) ...[
                      Text(
                        message,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 13),
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (oneTimeCode != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: CupertinoColors.systemGrey6,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          oneTimeCode,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Courier',
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (input != null) ...[
                      CupertinoTextField(
                        controller: textController,
                        placeholder: input.placeholder,
                        keyboardType: input.keyboardType,
                        obscureText: input.obscureText,
                        maxLength: input.maxLength,
                        autofocus: true,
                        padding: const EdgeInsets.all(12),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }

          return CupertinoAlertDialog(
            title: Text(title),
            content: contentWidget != null
                ? Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: contentWidget,
                  )
                : null,
            actions: actions.map((action) {
              return CupertinoDialogAction(
                onPressed: () {
                  final text = textController.text;
                  Navigator.of(context).pop(text.isNotEmpty ? text : null);
                  action.onPressed();
                },
                isDefaultAction: action.style == AlertActionStyle.primary,
                isDestructiveAction:
                    action.style == AlertActionStyle.destructive,
                child: Text(action.title),
              );
            }).toList(),
          );
        },
      );
    }

    // Android - Use Material Design AlertDialog with custom content
    if (PlatformInfo.isAndroid) {
      final textController = TextEditingController(text: input?.initialValue);

      return showDialog<String?>(
        context: context,
        builder: (context) {
          // Build custom content if icon, OTP, or textfield is present
          Widget? contentWidget;
          if (icon != null ||
              oneTimeCode != null ||
              message != null ||
              input != null) {
            contentWidget = Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null && icon is IconData && iconSize != null) ...[
                  Icon(icon, size: iconSize, color: iconColor ?? Colors.blue),
                  const SizedBox(height: 12),
                ],
                if (message != null) ...[
                  Text(message, textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                ],
                if (oneTimeCode != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      oneTimeCode,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                        letterSpacing: 4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                if (input != null) ...[
                  TextField(
                    controller: textController,
                    decoration: InputDecoration(
                      hintText: input.placeholder,
                      border: const OutlineInputBorder(),
                    ),
                    keyboardType: input.keyboardType,
                    obscureText: input.obscureText,
                    maxLength: input.maxLength,
                  ),
                ],
              ],
            );
          }

          // Separate actions by type
          final normalActions = actions
              .where((a) => a.style != AlertActionStyle.cancel)
              .toList();
          final cancelLabel = MaterialLocalizations.of(
            context,
          ).cancelButtonLabel;
          final cancelAction = actions.firstWhere(
            (a) => a.style == AlertActionStyle.cancel,
            orElse: () => AlertAction(
              title: cancelLabel,
              onPressed: () {},
              style: AlertActionStyle.cancel,
            ),
          );

          return AlertDialog(
            title: Text(title),
            content: contentWidget,
            actions: [
              ...normalActions.map((action) {
                Color? buttonColor;
                switch (action.style) {
                  case AlertActionStyle.destructive:
                    buttonColor = Colors.red;
                    break;
                  case AlertActionStyle.primary:
                    buttonColor = Theme.of(context).colorScheme.primary;
                    break;
                  case AlertActionStyle.success:
                    buttonColor = Colors.green;
                    break;
                  case AlertActionStyle.warning:
                    buttonColor = Colors.orange;
                    break;
                  case AlertActionStyle.info:
                    buttonColor = Colors.blue;
                    break;
                  default:
                    buttonColor = null;
                }

                return TextButton(
                  onPressed: action.enabled
                      ? () {
                          final text = textController.text;
                          Navigator.of(
                            context,
                          ).pop(text.isNotEmpty ? text : null);
                          action.onPressed();
                        }
                      : null,
                  style: buttonColor != null
                      ? TextButton.styleFrom(foregroundColor: buttonColor)
                      : null,
                  child: Text(action.title),
                );
              }),
              if (actions.any((a) => a.style == AlertActionStyle.cancel))
                TextButton(
                  onPressed: () {
                    final text = textController.text;
                    Navigator.of(context).pop(text.isNotEmpty ? text : null);
                    cancelAction.onPressed();
                  },
                  child: Text(cancelAction.title),
                ),
            ],
          );
        },
      );
    }

    // Fallback to CupertinoAlertDialog with input support
    final textController = TextEditingController(text: input?.initialValue);

    return showCupertinoDialog<String?>(
      context: context,
      builder: (context) {
        Widget? contentWidget;

        // Build custom content if message or input is present
        if (message != null || input != null) {
          contentWidget = Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (message != null) ...[
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 12),
              ],
              if (input != null) ...[
                CupertinoTextField(
                  controller: textController,
                  placeholder: input.placeholder,
                  keyboardType: input.keyboardType,
                  obscureText: input.obscureText,
                  maxLength: input.maxLength,
                  autofocus: true,
                  padding: const EdgeInsets.all(12),
                ),
              ],
            ],
          );
        }

        return CupertinoAlertDialog(
          title: Text(title),
          content: contentWidget,
          actions: actions.map((action) {
            return CupertinoDialogAction(
              onPressed: () {
                final text = textController.text;
                Navigator.of(context).pop(text.isNotEmpty ? text : null);
                action.onPressed();
              },
              isDefaultAction: action.style == AlertActionStyle.defaultAction,
              isDestructiveAction: action.style == AlertActionStyle.destructive,
              child: Text(action.title),
            );
          }).toList(),
        );
      },
    );
  }
}
