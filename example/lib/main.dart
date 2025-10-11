import 'package:adaptive_platform_ui_example/pages/demo_tabbar_page.dart';
import 'package:adaptive_platform_ui_example/pages/popup_menu_demo_page.dart';
import 'package:adaptive_platform_ui_example/pages/segmented_control_demo_page.dart';
import 'package:adaptive_platform_ui_example/pages/slider_demo_page.dart';
import 'package:adaptive_platform_ui_example/pages/switch_demo_page.dart';
import 'package:adaptive_platform_ui_example/pages/checkbox_demo_page.dart';
import 'package:adaptive_platform_ui_example/pages/radio_demo_page.dart';
import 'package:adaptive_platform_ui_example/pages/card_demo_page.dart';
import 'package:adaptive_platform_ui_example/pages/badge_demo_page.dart';
import 'package:adaptive_platform_ui_example/pages/tooltip_demo_page.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'pages/alert_dialog_demo_page.dart';
import 'pages/button_demo_page.dart';

void main() {
  runApp(const AdaptivePlatformUIDemo());
}

class AdaptivePlatformUIDemo extends StatelessWidget {
  const AdaptivePlatformUIDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return AdaptiveApp(
      themeMode: ThemeMode.system,
      title: 'Adaptive Platform UI',
      cupertinoLightTheme: CupertinoThemeData(brightness: Brightness.light),
      cupertinoDarkTheme: CupertinoThemeData(brightness: Brightness.dark),
      materialLightTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        brightness: Brightness.light,
      ),
      materialDarkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        brightness: Brightness.dark,
      ),

      home: HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return AdaptiveScaffold(
      title: "Adaptive Platform UI",
      actions: [
        AdaptiveAppBarAction(
          onPressed: () {},
          iosSymbol: "info.circle",
          androidIcon: CupertinoIcons.info_circle,
        ),
      ],
      body: _buildBody(context),
    );
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
        _buildHeader(context),
        const SizedBox(height: 24),
        _buildSection(
          context,
          title: 'Screen',
          items: [
            _DemoItem(
              icon: PlatformInfo.isIOS
                  ? CupertinoIcons.square_split_2x2
                  : Icons.dashboard,
              title: 'Tabbar',
              description: 'Adaptive tab bars with platform-specific styles',
              page: const DemoTabbarPage(),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildSection(
          context,
          title: 'Components',
          items: [
            _DemoItem(
              icon: PlatformInfo.isIOS
                  ? CupertinoIcons.hand_point_right_fill
                  : Icons.touch_app,
              title: 'Button',
              description: 'Adaptive buttons with platform-specific styles',
              page: const ButtonDemoPage(),
            ),
            _DemoItem(
              icon: PlatformInfo.isIOS
                  ? CupertinoIcons.chat_bubble_fill
                  : Icons.message,
              title: 'Alert Dialog',
              description: 'Native alert dialogs with adaptive styling',
              page: const AlertDialogDemoPage(),
            ),

            _DemoItem(
              icon: PlatformInfo.isIOS
                  ? CupertinoIcons.ellipsis_circle_fill
                  : Icons.more_horiz,
              title: 'Popup Menu',
              description: 'Native popup menus with adaptive styling',
              page: const PopupMenuDemoPage(),
            ),

            _DemoItem(
              icon: Icons.tune,
              title: 'Slider',
              description: 'Native sliders with adaptive styling',
              page: const SliderDemoPage(),
            ),
            _DemoItem(
              icon: Icons.toggle_on,
              title: 'Switch',
              description: 'Native switches with adaptive styling',
              page: const SwitchDemoPage(),
            ),
            _DemoItem(
              icon: PlatformInfo.isIOS
                  ? CupertinoIcons.checkmark_square
                  : Icons.check_box,
              title: 'Checkbox',
              description: 'Native checkboxes with adaptive styling',
              page: const CheckboxDemoPage(),
            ),
            _DemoItem(
              icon: PlatformInfo.isIOS
                  ? CupertinoIcons.circle
                  : Icons.radio_button_checked,
              title: 'Radio',
              description: 'Radio button groups with adaptive styling',
              page: const RadioDemoPage(),
            ),
            _DemoItem(
              icon: PlatformInfo.isIOS
                  ? CupertinoIcons.rectangle_on_rectangle
                  : Icons.credit_card,
              title: 'Card',
              description: 'Adaptive cards with platform-specific styling',
              page: const CardDemoPage(),
            ),
            _DemoItem(
              icon: PlatformInfo.isIOS
                  ? CupertinoIcons.number_circle_fill
                  : Icons.notifications_active,
              title: 'Badge',
              description: 'Notification badges with adaptive styling',
              page: const BadgeDemoPage(),
            ),
            _DemoItem(
              icon: PlatformInfo.isIOS
                  ? CupertinoIcons.info_circle
                  : Icons.info_outline,
              title: 'Tooltip',
              description: 'Platform-specific tooltips',
              page: const TooltipDemoPage(),
            ),
            _DemoItem(
              icon: PlatformInfo.isIOS
                  ? CupertinoIcons.square_split_2x2
                  : Icons.segment,
              title: 'Segmented Control',
              description: 'Native segmented controls with adaptive styling',
              page: const SegmentedControlDemoPage(),
            ),
          ],
        ),

        const SizedBox(height: 24),
        _buildInfoCard(context),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: PlatformInfo.isIOS
              ? [
                  CupertinoColors.systemBlue,
                  CupertinoColors.systemBlue.withValues(alpha: 0.7),
                ]
              : [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            PlatformInfo.isIOS
                ? CupertinoIcons.device_phone_portrait
                : Icons.phone_iphone,
            color: Colors.white,
            size: 40,
          ),
          const SizedBox(height: 12),
          const Text(
            'Adaptive Platform UI',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Cross-platform Flutter widgets that adapt to iOS 26+, iOS <26 (iOS 18 and below), and Android',
            style: TextStyle(color: Colors.white, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required List<_DemoItem> items,
  }) {
    final isDark = PlatformInfo.isIOS
        ? MediaQuery.platformBrightnessOf(context) == Brightness.dark
        : Theme.of(context).brightness == Brightness.dark;

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
                  ? (isDark ? CupertinoColors.white : CupertinoColors.black)
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
      final isDark = MediaQuery.platformBrightnessOf(context) == Brightness.dark;

      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        child: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => _navigateToPage(context, item.page),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark
                  ? CupertinoColors.darkBackgroundGray
                  : CupertinoColors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark
                    ? CupertinoColors.systemGrey4
                    : CupertinoColors.separator,
                width: 0.5,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    item.icon,
                    color: CupertinoColors.systemBlue,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? CupertinoColors.white
                              : CupertinoColors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.description,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark
                              ? CupertinoColors.systemGrey
                              : CupertinoColors.systemGrey2,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
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
        onTap: () => _navigateToPage(context, item.page),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  item.icon,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.description,
                      style: TextStyle(
                        fontSize: 14,
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

  Widget _buildInfoCard(BuildContext context) {
    final isDark = PlatformInfo.isIOS
        ? MediaQuery.platformBrightnessOf(context) == Brightness.dark
        : Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: PlatformInfo.isIOS
            ? (isDark
                ? CupertinoColors.darkBackgroundGray
                : CupertinoColors.white)
            : Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: PlatformInfo.isIOS
            ? Border.all(
                color: isDark
                    ? CupertinoColors.systemGrey4
                    : CupertinoColors.separator,
                width: 0.5,
              )
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                PlatformInfo.isIOS
                    ? CupertinoIcons.info_circle_fill
                    : Icons.info,
                color: PlatformInfo.isIOS
                    ? CupertinoColors.systemBlue
                    : Theme.of(context).colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'About',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: PlatformInfo.isIOS
                      ? (isDark
                          ? CupertinoColors.white
                          : CupertinoColors.black)
                      : Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'This package provides adaptive widgets that automatically render platform-specific designs based on the user\'s device and OS version.',
            style: TextStyle(
              fontSize: 14,
              color: PlatformInfo.isIOS
                  ? (isDark
                      ? CupertinoColors.systemGrey
                      : CupertinoColors.systemGrey2)
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          _buildFeatureRow(
            context,
            icon: PlatformInfo.isIOS
                ? CupertinoIcons.checkmark_circle_fill
                : Icons.check_circle,
            text: 'iOS 26+ native designs with Liquid Glass effects',
          ),
          const SizedBox(height: 8),
          _buildFeatureRow(
            context,
            icon: PlatformInfo.isIOS
                ? CupertinoIcons.checkmark_circle_fill
                : Icons.check_circle,
            text:
                'Traditional Cupertino widgets for iOS <26 (iOS 18 and below)',
          ),
          const SizedBox(height: 8),
          _buildFeatureRow(
            context,
            icon: PlatformInfo.isIOS
                ? CupertinoIcons.checkmark_circle_fill
                : Icons.check_circle,
            text: 'Material Design 3 for Android',
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureRow(
    BuildContext context, {
    required IconData icon,
    required String text,
  }) {
    final isDark = PlatformInfo.isIOS
        ? MediaQuery.platformBrightnessOf(context) == Brightness.dark
        : Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: PlatformInfo.isIOS
              ? CupertinoColors.systemGreen
              : Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: PlatformInfo.isIOS
                  ? (isDark
                      ? CupertinoColors.systemGrey
                      : CupertinoColors.systemGrey2)
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }

  void _navigateToPage(BuildContext context, Widget page) {
    if (PlatformInfo.isIOS) {
      Navigator.of(
        context,
      ).push(CupertinoPageRoute(builder: (context) => page));
    } else {
      Navigator.of(context).push(MaterialPageRoute(builder: (context) => page));
    }
  }
}

class _DemoItem {
  final IconData icon;
  final String title;
  final String description;
  final Widget page;

  const _DemoItem({
    required this.icon,
    required this.title,
    required this.description,
    required this.page,
  });
}
