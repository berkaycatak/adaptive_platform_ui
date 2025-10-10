import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';

class AlertDialogDemoPage extends StatelessWidget {
  const AlertDialogDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AdaptiveScaffold(
      title: 'AdaptiveAlertDialog Demo',
      destinations: const [],
      selectedIndex: 0,
      onDestinationSelected: (_) {},
      children: [
        SafeArea(child: _buildContent(context)),
      ],
    );
  }

  Widget _buildContent(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // Platform Information
        _buildSection(
          'Platform Information',
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: PlatformInfo.isIOS
                  ? CupertinoColors.systemGrey6
                  : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              PlatformInfo.platformDescription,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: PlatformInfo.isIOS
                    ? CupertinoColors.label
                    : Colors.black87,
              ),
            ),
          ),
        ),

        const SizedBox(height: 32),

        // Basic Alert
        _buildSection(
          'Basic Alerts',
          Column(
            children: [
              _buildButton(
                context,
                'Simple Alert',
                () => _showSimpleAlert(context),
              ),
              const SizedBox(height: 12),
              _buildButton(
                context,
                'Alert with Message',
                () => _showAlertWithMessage(context),
              ),
              const SizedBox(height: 12),
              _buildButton(
                context,
                'Alert with Icon',
                () => _showAlertWithIcon(context),
              ),
            ],
          ),
        ),

        const SizedBox(height: 32),

        // Action Styles
        _buildSection(
          'Action Styles',
          Column(
            children: [
              _buildButton(
                context,
                'Primary Action',
                () => _showPrimaryActionAlert(context),
              ),
              const SizedBox(height: 12),
              _buildButton(
                context,
                'Destructive Action',
                () => _showDestructiveActionAlert(context),
              ),
              const SizedBox(height: 12),
              _buildButton(
                context,
                'Multiple Action Styles',
                () => _showMultipleActionsAlert(context),
              ),
            ],
          ),
        ),

        const SizedBox(height: 32),

        // Special Features
        _buildSection(
          'Special Features',
          Column(
            children: [
              _buildButton(
                context,
                'One-Time Code',
                () => _showOneTimeCodeAlert(context),
              ),
              const SizedBox(height: 12),
              _buildButton(
                context,
                'Icon + OTP Code',
                () => _showIconWithOTPAlert(context),
              ),
              const SizedBox(height: 12),
              _buildButton(
                context,
                'Colored Icon',
                () => _showColoredIconAlert(context),
              ),
            ],
          ),
        ),

        const SizedBox(height: 32),

        // Description
        _buildSection(
          'About',
          Text(
            'The AdaptiveAlertDialog automatically uses:\n\n'
            '• Native iOS 26 UIAlertController with Liquid Glass on iOS 26+\n'
            '• CupertinoAlertDialog on iOS 25 and below\n'
            '• Material AlertDialog on Android\n\n'
            'Features:\n'
            '• Multiple action styles (primary, destructive, success, etc.)\n'
            '• SF Symbol icon support\n'
            '• One-time code display\n'
            '• Automatic light/dark mode\n'
            '• Native animations and blur effects',
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: PlatformInfo.isIOS
                  ? CupertinoColors.secondaryLabel
                  : Colors.black54,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSection(String title, Widget content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: PlatformInfo.isIOS ? CupertinoColors.label : Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        content,
      ],
    );
  }

  Widget _buildButton(
    BuildContext context,
    String title,
    VoidCallback onPressed,
  ) {
    return AdaptiveButton(
      color: CupertinoColors.systemBlue,
      onPressed: onPressed,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      borderRadius: BorderRadius.circular(12),
      label: title,
    );
  }

  void _showSimpleAlert(BuildContext context) {
    AdaptiveAlertDialog.show(
      context: context,
      title: 'Hello',
      actions: [
        AlertAction(
          title: 'OK',
          onPressed: () {
            debugPrint('OK pressed');
          },
          style: AlertActionStyle.primary,
        ),
      ],
    );
  }

  void _showAlertWithMessage(BuildContext context) {
    AdaptiveAlertDialog.show(
      context: context,
      title: 'Update Available',
      message:
          'A new version of the app is available. Would you like to update now?',
      actions: [
        AlertAction(
          title: 'Later',
          onPressed: () {
            debugPrint('Later pressed');
          },
          style: AlertActionStyle.cancel,
        ),
        AlertAction(
          title: 'Update',
          onPressed: () {
            debugPrint('Update pressed');
          },
          style: AlertActionStyle.primary,
        ),
      ],
    );
  }

  void _showAlertWithIcon(BuildContext context) {
    AdaptiveAlertDialog.show(
      context: context,
      title: 'Success',
      message: 'Your changes have been saved successfully.',
      icon: 'checkmark.circle.fill',
      iconSize: 48,
      iconColor: Colors.green,
      actions: [
        AlertAction(
          title: 'OK',
          onPressed: () {
            debugPrint('OK pressed');
          },
          style: AlertActionStyle.primary,
        ),
      ],
    );
  }

  void _showPrimaryActionAlert(BuildContext context) {
    AdaptiveAlertDialog.show(
      context: context,
      title: 'Confirm Action',
      message: 'Are you sure you want to proceed?',
      actions: [
        AlertAction(
          title: 'Cancel',
          onPressed: () {
            debugPrint('Cancel pressed');
          },
          style: AlertActionStyle.cancel,
        ),
        AlertAction(
          title: 'Confirm',
          onPressed: () {
            debugPrint('Confirm pressed');
          },
          style: AlertActionStyle.primary,
        ),
      ],
    );
  }

  void _showDestructiveActionAlert(BuildContext context) {
    AdaptiveAlertDialog.show(
      context: context,
      title: 'Delete Item',
      message: 'This action cannot be undone.',
      icon: 'trash.fill',
      iconSize: 48,
      iconColor: Colors.red,
      actions: [
        AlertAction(
          title: 'Cancel',
          onPressed: () {
            debugPrint('Cancel pressed');
          },
          style: AlertActionStyle.cancel,
        ),
        AlertAction(
          title: 'Delete',
          onPressed: () {
            debugPrint('Delete pressed');
          },
          style: AlertActionStyle.destructive,
        ),
      ],
    );
  }

  void _showMultipleActionsAlert(BuildContext context) {
    AdaptiveAlertDialog.show(
      context: context,
      title: 'Choose an Option',
      message: 'Select one of the actions below.',
      actions: [
        AlertAction(
          title: 'Save',
          onPressed: () {
            debugPrint('Save pressed');
          },
          style: AlertActionStyle.success,
        ),
        AlertAction(
          title: 'Discard',
          onPressed: () {
            debugPrint('Discard pressed');
          },
          style: AlertActionStyle.warning,
        ),
        AlertAction(
          title: 'Cancel',
          onPressed: () {
            debugPrint('Cancel pressed');
          },
          style: AlertActionStyle.cancel,
        ),
      ],
    );
  }

  void _showOneTimeCodeAlert(BuildContext context) {
    AdaptiveAlertDialog.show(
      context: context,
      title: 'Verification Code',
      message: 'Enter this code in the app to verify your identity.',
      oneTimeCode: '123456',
      actions: [
        AlertAction(
          title: 'Copy Code',
          onPressed: () {
            debugPrint('Copy Code pressed');
          },
          style: AlertActionStyle.primary,
        ),
        AlertAction(
          title: 'Close',
          onPressed: () {
            debugPrint('Close pressed');
          },
          style: AlertActionStyle.cancel,
        ),
      ],
    );
  }

  void _showIconWithOTPAlert(BuildContext context) {
    AdaptiveAlertDialog.show(
      context: context,
      title: 'Authentication Required',
      message: 'Use this code to complete your authentication.',
      icon: 'lock.shield.fill',
      iconSize: 48,
      iconColor: Colors.blue,
      oneTimeCode: '987654',
      actions: [
        AlertAction(
          title: 'Copy & Continue',
          onPressed: () {
            debugPrint('Copy & Continue pressed');
          },
          style: AlertActionStyle.primary,
        ),
        AlertAction(
          title: 'Cancel',
          onPressed: () {
            debugPrint('Cancel pressed');
          },
          style: AlertActionStyle.cancel,
        ),
      ],
    );
  }

  void _showColoredIconAlert(BuildContext context) {
    AdaptiveAlertDialog.show(
      context: context,
      title: 'Warning',
      message: 'Please review your changes before proceeding.',
      icon: 'exclamationmark.triangle.fill',
      iconSize: 48,
      iconColor: Colors.orange,
      actions: [
        AlertAction(
          title: 'Review',
          onPressed: () {
            debugPrint('Review pressed');
          },
          style: AlertActionStyle.primary,
        ),
        AlertAction(
          title: 'Proceed Anyway',
          onPressed: () {
            debugPrint('Proceed pressed');
          },
          style: AlertActionStyle.warning,
        ),
        AlertAction(
          title: 'Cancel',
          onPressed: () {
            debugPrint('Cancel pressed');
          },
          style: AlertActionStyle.cancel,
        ),
      ],
    );
  }
}
