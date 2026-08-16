import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AppBarTitleDemoPage extends StatefulWidget {
  const AppBarTitleDemoPage({super.key});

  @override
  State<AppBarTitleDemoPage> createState() => _AppBarTitleDemoPageState();
}

enum _TitleMode { plain, subtitle, custom }

class _AppBarTitleDemoPageState extends State<AppBarTitleDemoPage> {
  _TitleMode _mode = _TitleMode.subtitle;

  AdaptiveAppBar _buildAppBar() {
    switch (_mode) {
      case _TitleMode.plain:
        return AdaptiveAppBar(title: 'App Bar Title');
      case _TitleMode.subtitle:
        return AdaptiveAppBar(
          title: 'App Bar Title',
          subtitle: '12 unread messages',
        );
      case _TitleMode.custom:
        return AdaptiveAppBar(
          title: 'App Bar Title',
          titleWidget: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                PlatformInfo.isIOS
                    ? CupertinoIcons.person_crop_circle_fill
                    : Icons.account_circle,
                size: 24,
              ),
              const SizedBox(width: 8),
              const Text(
                'Custom Widget',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdaptiveScaffold(
      appBar: _buildAppBar(),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 110),
          Text(
            'Title Mode',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: PlatformInfo.isIOS
                  ? CupertinoColors.label
                  : Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          AdaptiveSegmentedControl(
            labels: const ['Plain', 'Subtitle', 'Custom'],
            selectedIndex: _mode.index,
            onValueChanged: (value) {
              setState(() => _mode = _TitleMode.values[value]);
            },
          ),
          const SizedBox(height: 24),
          Text(
            'The app bar above updates live:\n\n'
            '• Plain — a regular string title\n'
            '• Subtitle — title with a smaller subtitle below it\n'
            '• Custom — a titleWidget replacing the title area entirely\n\n'
            'On iOS 26+ the subtitle/custom widget is overlaid centered on '
            'the native Liquid Glass toolbar; on iOS <26 it becomes the '
            'CupertinoNavigationBar middle; on Android it is the AppBar title.',
            style: TextStyle(
              fontSize: 15,
              color: PlatformInfo.isIOS
                  ? CupertinoColors.secondaryLabel
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
