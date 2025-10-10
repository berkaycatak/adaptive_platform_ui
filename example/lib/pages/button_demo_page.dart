import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';

/// Demo page showcasing AdaptiveButton features
class ButtonDemoPage extends StatefulWidget {
  const ButtonDemoPage({super.key});

  @override
  State<ButtonDemoPage> createState() => _ButtonDemoPageState();
}

class _ButtonDemoPageState extends State<ButtonDemoPage> {
  @override
  Widget build(BuildContext context) {
    return AdaptiveScaffold(title: 'Button Demos', child: _buildBody(context));
  }

  Widget _buildBody(BuildContext context) {
    final topPadding = PlatformInfo.isIOS ? 130.0 : 16.0;

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
          title: 'iOS 26 Button Examples',
          children: [
            const Text(
              'Default Button',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: AdaptiveButton(
                style: AdaptiveButtonStyle.prominentGlass,
                textColor: Colors.white,
                onPressed: () =>
                    _showMessage(context, 'Default button pressed'),
                label: 'Click Me',
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Button with Icon',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: AdaptiveButton.sfSymbol(
                style: AdaptiveButtonStyle.prominentGlass,
                onPressed: () => _showMessage(context, 'Icon button pressed'),
                sfSymbol: SFSymbol('heart.fill', size: 20),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Disabled Button',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: const AdaptiveButton(onPressed: null, label: 'Disabled'),
            ),
          ],
        ),

        const SizedBox(height: 24),
        _buildSection(
          context,
          title: 'Basic Buttons',
          children: [
            const Text(
              'Default Button',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            AdaptiveButton(
              onPressed: () => _showMessage(context, 'Default button pressed'),
              label: 'Click Me',
            ),
            const SizedBox(height: 16),
            const Text(
              'Button with Icon',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            AdaptiveButton.icon(
              onPressed: () => _showMessage(context, 'Icon button pressed'),
              icon: PlatformInfo.isIOS
                  ? CupertinoIcons.heart_fill
                  : Icons.favorite,
            ),
            const SizedBox(height: 16),
            const Text(
              'Disabled Buttson',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            const AdaptiveButton(onPressed: null, label: 'Disabled'),
          ],
        ),
        const SizedBox(height: 24),
        _buildSection(
          context,
          title: 'Button Styles',
          children: [
            const Text(
              'Filled Button',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            AdaptiveButton(
              onPressed: () => _showMessage(context, 'Filled button'),
              style: AdaptiveButtonStyle.filled,
              label: 'Filled',
            ),
            const SizedBox(height: 16),
            const Text(
              'Tinted Button',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            AdaptiveButton(
              onPressed: () => _showMessage(context, 'Tinted button'),
              style: AdaptiveButtonStyle.tinted,
              label: 'Tinted',
            ),
            const SizedBox(height: 16),
            const Text(
              'Bordered Button',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            AdaptiveButton(
              onPressed: () => _showMessage(context, 'Bordered button'),
              style: AdaptiveButtonStyle.bordered,
              label: 'Bordered',
            ),
            const SizedBox(height: 16),
            const Text(
              'Plain Button',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            AdaptiveButton(
              onPressed: () => _showMessage(context, 'Plain button'),
              style: AdaptiveButtonStyle.plain,
              label: 'Plain',
            ),
            const SizedBox(height: 16),
            const Text(
              'Gray Button',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            AdaptiveButton(
              onPressed: () => _showMessage(context, 'Gray button'),
              style: AdaptiveButtonStyle.gray,
              label: 'Gray',
            ),
          ],
        ),
        const SizedBox(height: 24),
        _buildSection(
          context,
          title: 'Button Sizes',
          children: [
            const Text(
              'Large Button',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: AdaptiveButton(
                onPressed: () => _showMessage(context, 'Large button'),
                style: AdaptiveButtonStyle.filled,
                size: AdaptiveButtonSize.large,
                label: 'Full Width',
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Compact Buttons',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: AdaptiveButton(
                    onPressed: () => _showMessage(context, 'Yes'),
                    style: AdaptiveButtonStyle.filled,
                    label: 'Yes',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AdaptiveButton(
                    onPressed: () => _showMessage(context, 'No'),
                    style: AdaptiveButtonStyle.bordered,
                    label: 'No',
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 24),
        _buildSection(
          context,
          title: 'Icon-Only Buttons',
          children: [
            const Text(
              'Action Buttons',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildIconButton(
                  context,
                  icon: PlatformInfo.isIOS
                      ? CupertinoIcons.heart
                      : Icons.favorite_border,
                  label: 'Like',
                ),
                _buildIconButton(
                  context,
                  icon: PlatformInfo.isIOS ? CupertinoIcons.share : Icons.share,
                  label: 'Share',
                ),
                _buildIconButton(
                  context,
                  icon: PlatformInfo.isIOS
                      ? CupertinoIcons.bookmark
                      : Icons.bookmark_border,
                  label: 'Save',
                ),
                _buildIconButton(
                  context,
                  icon: PlatformInfo.isIOS
                      ? CupertinoIcons.ellipsis
                      : Icons.more_horiz,
                  label: 'More',
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: PlatformInfo.isIOS
            ? CupertinoColors.systemBackground
            : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: PlatformInfo.isIOS
              ? CupertinoColors.separator
              : Theme.of(context).dividerColor,
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: PlatformInfo.isIOS
                  ? CupertinoColors.label
                  : Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildIconButton(
    BuildContext context, {
    required IconData icon,
    required String label,
  }) {
    return Column(
      children: [
        AdaptiveButton.icon(
          onPressed: () => _showMessage(context, '$label pressed'),
          style: AdaptiveButtonStyle.bordered,
          icon: icon,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: PlatformInfo.isIOS
                ? CupertinoColors.secondaryLabel
                : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  void _showMessage(BuildContext context, String message) {
    AdaptiveAlertDialog.show(
      context: context,
      title: message,
      actions: [
        AlertAction(
          title: 'OK',
          onPressed: () {},
          style: AlertActionStyle.defaultAction,
        ),
      ],
    );
  }
}
