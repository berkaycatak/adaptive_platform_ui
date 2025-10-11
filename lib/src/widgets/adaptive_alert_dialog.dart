import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../platform/platform_info.dart';
import 'ios26/ios26_alert_dialog.dart';

export 'ios26/ios26_alert_dialog.dart' show AlertAction, AlertActionStyle;

// Map SF Symbol names to Flutter icons
IconData _getIconData(String sfSymbolName) {
  // Common SF Symbols mapping
  final iconMap = {
    'checkmark.circle.fill': Icons.check_circle,
    'checkmark.circle': Icons.check_circle_outline,
    'xmark.circle.fill': Icons.cancel,
    'xmark.circle': Icons.cancel_outlined,
    'exclamationmark.triangle.fill': Icons.warning,
    'exclamationmark.triangle': Icons.warning_amber_outlined,
    'exclamationmark.circle.fill': Icons.error,
    'exclamationmark.circle': Icons.error_outline,
    'info.circle.fill': Icons.info,
    'info.circle': Icons.info_outline,
    'questionmark.circle.fill': Icons.help,
    'questionmark.circle': Icons.help_outline,
    'trash.fill': Icons.delete,
    'trash': Icons.delete_outline,
    'lock.shield.fill': Icons.security,
    'lock.shield': Icons.security_outlined,
    'lock.fill': Icons.lock,
    'lock': Icons.lock_outline,
    'bell.fill': Icons.notifications,
    'bell': Icons.notifications_outlined,
    'star.fill': Icons.star,
    'star': Icons.star_outline,
    'heart.fill': Icons.favorite,
    'heart': Icons.favorite_outline,
  };

  return iconMap[sfSymbolName] ?? Icons.info;
}

/// An adaptive alert dialog that renders platform-specific styles
///
/// On iOS 26+: Uses native iOS 26 UIAlertController with Liquid Glass
/// On iOS <26 (iOS 18 and below): Uses CupertinoAlertDialog
/// On Android: Uses Material AlertDialog
class AdaptiveAlertDialog {
  AdaptiveAlertDialog._();

  /// Shows an adaptive alert dialog
  static Future<void> show({
    required BuildContext context,
    required String title,
    String? message,
    required List<AlertAction> actions,
    String? icon,
    double? iconSize,
    Color? iconColor,
    String? oneTimeCode,
  }) {
    // iOS 26+ - Use native iOS 26 alert dialog
    if (PlatformInfo.isIOS26OrHigher()) {
      return showCupertinoDialog<void>(
        context: context,
        builder: (context) => IOS26AlertDialog(
          title: title,
          message: message,
          actions: actions,
          icon: icon,
          iconSize: iconSize,
          iconColor: iconColor,
          oneTimeCode: oneTimeCode,
        ),
      );
    }

    // iOS 18 and below - Use CupertinoAlertDialog with custom content for OTP/icon
    if (PlatformInfo.isIOS) {
      return showCupertinoDialog<void>(
        context: context,
        builder: (context) {
          Widget? contentWidget;

          // Build custom content if icon or OTP is present
          if (icon != null || oneTimeCode != null) {
            contentWidget = Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null && iconSize != null) ...[
                  Icon(
                    _getIconData(icon),
                    size: iconSize,
                    color: iconColor ?? CupertinoColors.systemBlue,
                  ),
                  const SizedBox(height: 8),
                ],
                if (message != null) ...[
                  Text(
                    message,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                ],
                if (oneTimeCode != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                    ),
                  ),
                ],
              ],
            );
          } else if (message != null) {
            contentWidget = Text(message);
          }

          return CupertinoAlertDialog(
            title: Text(title),
            content: contentWidget,
            actions: actions.map((action) {
              return CupertinoDialogAction(
                onPressed: () {
                  Navigator.of(context).pop();
                  action.onPressed();
                },
                isDefaultAction: action.style == AlertActionStyle.primary,
                isDestructiveAction: action.style == AlertActionStyle.destructive,
                child: Text(action.title),
              );
            }).toList(),
          );
        },
      );
    }

    // Android - Use Material Design AlertDialog with custom content
    if (PlatformInfo.isAndroid) {
      return showDialog<void>(
        context: context,
        builder: (context) {
          // Build custom content if icon or OTP is present
          Widget? contentWidget;
          if (icon != null || oneTimeCode != null) {
            contentWidget = Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null && iconSize != null) ...[
                  Icon(
                    _getIconData(icon),
                    size: iconSize,
                    color: iconColor ?? Colors.blue,
                  ),
                  const SizedBox(height: 12),
                ],
                if (message != null) ...[
                  Text(
                    message,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                ],
                if (oneTimeCode != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
                ],
              ],
            );
          } else if (message != null) {
            contentWidget = Text(message);
          }

          // Separate actions by type
          final normalActions = actions
              .where((a) => a.style != AlertActionStyle.cancel)
              .toList();
          final cancelAction = actions
              .firstWhere(
                (a) => a.style == AlertActionStyle.cancel,
                orElse: () => AlertAction(
                  title: 'Cancel',
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
                          Navigator.of(context).pop();
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
                    Navigator.of(context).pop();
                    cancelAction.onPressed();
                  },
                  child: Text(cancelAction.title),
                ),
            ],
          );
        },
      );
    }

    // Fallback to CupertinoAlertDialog
    return showCupertinoDialog<void>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(title),
        content: message != null ? Text(message) : null,
        actions: actions.map((action) {
          return CupertinoDialogAction(
            onPressed: () {
              Navigator.of(context).pop();
              action.onPressed();
            },
            isDefaultAction: action.style == AlertActionStyle.defaultAction,
            isDestructiveAction: action.style == AlertActionStyle.destructive,
            child: Text(action.title),
          );
        }).toList(),
      ),
    );
  }
}
