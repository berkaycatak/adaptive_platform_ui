import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';

/// Demo page showcasing AdaptiveAlertDialog features
class AlertDialogDemoPage extends StatelessWidget {
  const AlertDialogDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AdaptiveScaffold(
      title: 'Alert Dialog',
      destinations: [],
      selectedIndex: null,
      onDestinationSelected: (int value) {},
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    final topPadding = PlatformInfo.isIOS ? 100.0 : 16.0;

    return ListView(
      padding: EdgeInsets.only(
        left: 16.0,
        right: 16.0,
        top: topPadding,
        bottom: 16.0,
      ),
      children: [
        _buildSection(
          context,
          title: 'Basic Alerts',
          items: [
            _DemoItem(
              title: 'Simple Alert',
              description: 'Basic alert with title and message',
              onTap: () => _showSimpleAlert(context),
            ),
            _DemoItem(
              title: 'Alert with Icon',
              description: 'Alert dialog with custom icon',
              onTap: () => _showIconAlert(context),
            ),
            _DemoItem(
              title: 'One-Time Code',
              description: 'Alert displaying OTP code',
              onTap: () => _showOTPAlert(context),
            ),
            _DemoItem(
              title: 'Authentication Required',
              description: 'Alert displaying authentication code',
              onTap: () => _showAuthenticationRequiredAlert(context),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _buildSection(
          context,
          title: 'Action Styles',
          items: [
            _DemoItem(
              title: 'Primary Action',
              description: 'Alert with primary action button',
              onTap: () => _showPrimaryActionAlert(context),
            ),
            _DemoItem(
              title: 'Destructive Action',
              description: 'Alert with destructive action',
              onTap: () => _showDestructiveAlert(context),
            ),
            _DemoItem(
              title: 'Multiple Actions',
              description: 'Alert with various action styles',
              onTap: () => _showMultipleActionsAlert(context),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _buildSection(
          context,
          title: 'Icon Variations',
          items: [
            _DemoItem(
              title: 'Success Alert',
              description: 'Alert with checkmark icon',
              onTap: () => _showSuccessAlert(context),
            ),
            _DemoItem(
              title: 'Warning Alert',
              description: 'Alert with warning icon',
              onTap: () => _showWarningAlert(context),
            ),
            _DemoItem(
              title: 'Error Alert',
              description: 'Alert with error icon',
              onTap: () => _showErrorAlert(context),
            ),
            _DemoItem(
              title: 'Info Alert',
              description: 'Alert with info icon',
              onTap: () => _showInfoAlert(context),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _buildSection(
          context,
          title: 'Complex Scenarios',
          items: [
            _DemoItem(
              title: 'Confirmation Dialog',
              description: 'Yes/No confirmation dialog',
              onTap: () => _showConfirmationDialog(context),
            ),
            _DemoItem(
              title: 'Triple Choice',
              description: 'Dialog with three options',
              onTap: () => _showTripleChoiceDialog(context),
            ),
            _DemoItem(
              title: 'Disabled Action',
              description: 'Dialog with disabled button',
              onTap: () => _showDisabledActionDialog(context),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required List<_DemoItem> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: PlatformInfo.isIOS
                  ? CupertinoColors.label
                  : Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
        ...items.map((item) => _buildDemoItem(context, item)),
      ],
    );
  }

  Widget _buildDemoItem(BuildContext context, _DemoItem item) {
    if (PlatformInfo.isIOS) {
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        child: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: item.onTap,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: CupertinoColors.systemBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: CupertinoColors.separator, width: 0.5),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: CupertinoColors.label,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.description,
                        style: const TextStyle(
                          fontSize: 13,
                          color: CupertinoColors.secondaryLabel,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  CupertinoIcons.chevron_right,
                  color: CupertinoColors.systemGrey,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.description,
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }

  // Alert Dialog Examples

  void _showSimpleAlert(BuildContext context) {
    AdaptiveAlertDialog.show(
      context: context,
      title: 'Simple Alert',
      message: 'This is a basic alert dialog with a title and message.',
      actions: [
        AlertAction(
          title: 'OK',
          onPressed: () {},
          style: AlertActionStyle.defaultAction,
        ),
      ],
    );
  }

  void _showIconAlert(BuildContext context) {
    AdaptiveAlertDialog.show(
      context: context,
      title: 'Notification Settings',
      message: 'Would you like to enable push notifications?',
      icon: 'bell.fill',
      iconSize: 48,
      iconColor: PlatformInfo.isIOS ? CupertinoColors.systemBlue : Colors.blue,
      actions: [
        AlertAction(
          title: 'Enable',
          onPressed: () {},
          style: AlertActionStyle.primary,
        ),
        AlertAction(
          title: 'Not Now',
          onPressed: () {},
          style: AlertActionStyle.cancel,
        ),
      ],
    );
  }

  void _showOTPAlert(BuildContext context) {
    AdaptiveAlertDialog.show(
      context: context,
      title: 'Verification Code',
      message: 'Use this code to verify your identity:',
      oneTimeCode: '123456',
      actions: [
        AlertAction(
          title: 'Copy Code',
          onPressed: () {},
          style: AlertActionStyle.primary,
        ),
        AlertAction(
          title: 'Done',
          onPressed: () {},
          style: AlertActionStyle.cancel,
        ),
      ],
    );
  }

  void _showAuthenticationRequiredAlert(BuildContext context) {
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

  void _showPrimaryActionAlert(BuildContext context) {
    AdaptiveAlertDialog.show(
      context: context,
      title: 'Update Available',
      message:
          'A new version of the app is available. Would you like to update now?',
      actions: [
        AlertAction(
          title: 'Update',
          onPressed: () {},
          style: AlertActionStyle.primary,
        ),
        AlertAction(
          title: 'Later',
          onPressed: () {},
          style: AlertActionStyle.cancel,
        ),
      ],
    );
  }

  void _showDestructiveAlert(BuildContext context) {
    AdaptiveAlertDialog.show(
      context: context,
      title: 'Delete Account',
      message:
          'This action cannot be undone. All your data will be permanently deleted.',
      icon: 'trash.fill',
      iconSize: 48,
      iconColor: PlatformInfo.isIOS ? CupertinoColors.systemRed : Colors.red,
      actions: [
        AlertAction(
          title: 'Delete',
          onPressed: () {},
          style: AlertActionStyle.destructive,
        ),
        AlertAction(
          title: 'Cancel',
          onPressed: () {},
          style: AlertActionStyle.cancel,
        ),
      ],
    );
  }

  void _showMultipleActionsAlert(BuildContext context) {
    AdaptiveAlertDialog.show(
      context: context,
      title: 'Choose Action',
      message: 'Select an action to perform on this item:',
      actions: [
        AlertAction(
          title: 'Save',
          onPressed: () {},
          style: AlertActionStyle.success,
        ),
        AlertAction(
          title: 'Edit',
          onPressed: () {},
          style: AlertActionStyle.info,
        ),
        AlertAction(
          title: 'Delete',
          onPressed: () {},
          style: AlertActionStyle.destructive,
        ),
        AlertAction(
          title: 'Cancel',
          onPressed: () {},
          style: AlertActionStyle.cancel,
        ),
      ],
    );
  }

  void _showSuccessAlert(BuildContext context) {
    AdaptiveAlertDialog.show(
      context: context,
      title: 'Success',
      message: 'Your changes have been saved successfully!',
      icon: 'checkmark.circle.fill',
      iconSize: 48,
      iconColor: PlatformInfo.isIOS
          ? CupertinoColors.systemGreen
          : Colors.green,
      actions: [
        AlertAction(
          title: 'Great!',
          onPressed: () {},
          style: AlertActionStyle.primary,
        ),
      ],
    );
  }

  void _showWarningAlert(BuildContext context) {
    AdaptiveAlertDialog.show(
      context: context,
      title: 'Warning',
      message: 'Your storage is almost full. Please free up some space.',
      icon: 'exclamationmark.triangle.fill',
      iconSize: 48,
      iconColor: PlatformInfo.isIOS
          ? CupertinoColors.systemOrange
          : Colors.orange,
      actions: [
        AlertAction(
          title: 'Manage Storage',
          onPressed: () {},
          style: AlertActionStyle.warning,
        ),
        AlertAction(
          title: 'Later',
          onPressed: () {},
          style: AlertActionStyle.cancel,
        ),
      ],
    );
  }

  void _showErrorAlert(BuildContext context) {
    AdaptiveAlertDialog.show(
      context: context,
      title: 'Error',
      message:
          'Failed to connect to the server. Please check your internet connection.',
      icon: 'exclamationmark.circle.fill',
      iconSize: 48,
      iconColor: PlatformInfo.isIOS ? CupertinoColors.systemRed : Colors.red,
      actions: [
        AlertAction(
          title: 'Retry',
          onPressed: () {},
          style: AlertActionStyle.primary,
        ),
        AlertAction(
          title: 'Cancel',
          onPressed: () {},
          style: AlertActionStyle.cancel,
        ),
      ],
    );
  }

  void _showInfoAlert(BuildContext context) {
    AdaptiveAlertDialog.show(
      context: context,
      title: 'Information',
      message:
          'This feature requires iOS 15 or later. Please update your device.',
      icon: 'info.circle.fill',
      iconSize: 48,
      iconColor: PlatformInfo.isIOS ? CupertinoColors.systemBlue : Colors.blue,
      actions: [
        AlertAction(
          title: 'OK',
          onPressed: () {},
          style: AlertActionStyle.defaultAction,
        ),
      ],
    );
  }

  void _showConfirmationDialog(BuildContext context) {
    AdaptiveAlertDialog.show(
      context: context,
      title: 'Save Changes?',
      message: 'Do you want to save your changes before leaving?',
      actions: [
        AlertAction(
          title: 'Yes',
          onPressed: () {},
          style: AlertActionStyle.primary,
        ),
        AlertAction(
          title: 'No',
          onPressed: () {},
          style: AlertActionStyle.destructive,
        ),
      ],
    );
  }

  void _showTripleChoiceDialog(BuildContext context) {
    AdaptiveAlertDialog.show(
      context: context,
      title: 'Save Document',
      message: 'How would you like to save this document?',
      actions: [
        AlertAction(
          title: 'Save to Cloud',
          onPressed: () {},
          style: AlertActionStyle.primary,
        ),
        AlertAction(
          title: 'Save Locally',
          onPressed: () {},
          style: AlertActionStyle.defaultAction,
        ),
        AlertAction(
          title: 'Cancel',
          onPressed: () {},
          style: AlertActionStyle.cancel,
        ),
      ],
    );
  }

  void _showDisabledActionDialog(BuildContext context) {
    AdaptiveAlertDialog.show(
      context: context,
      title: 'Terms and Conditions',
      message: 'Please read and accept the terms to continue.',
      actions: [
        AlertAction(
          title: 'Accept',
          onPressed: () {},
          style: AlertActionStyle.primary,
          enabled: false, // Disabled action
        ),
        AlertAction(
          title: 'Read Terms',
          onPressed: () {},
          style: AlertActionStyle.defaultAction,
        ),
        AlertAction(
          title: 'Cancel',
          onPressed: () {},
          style: AlertActionStyle.cancel,
        ),
      ],
    );
  }
}

class _DemoItem {
  final String title;
  final String description;
  final VoidCallback onTap;

  const _DemoItem({
    required this.title,
    required this.description,
    required this.onTap,
  });
}
