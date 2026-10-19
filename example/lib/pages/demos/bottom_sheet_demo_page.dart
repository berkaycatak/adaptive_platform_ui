import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class BottomSheetDemoPage extends StatefulWidget {
  const BottomSheetDemoPage({super.key});

  @override
  State<BottomSheetDemoPage> createState() => _BottomSheetDemoPageState();
}

class _BottomSheetDemoPageState extends State<BottomSheetDemoPage> {
  String? _lastResult;

  void _showResult(String? result) {
    setState(() => _lastResult = result ?? 'Dismissed');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = PlatformInfo.isIOS
        ? MediaQuery.platformBrightnessOf(context) == Brightness.dark
        : Theme.of(context).brightness == Brightness.dark;

    return AdaptiveScaffold(
      appBar: AdaptiveAppBar(title: 'Bottom Sheet'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 100),
          _buildInfoCard(isDark),
          const SizedBox(height: 24),
          _buildSection(
            isDark,
            title: 'Medium and Large',
            description:
                'Opens at half height; drag the grabber up for full height '
                'or down to dismiss',
            child: AdaptiveButton(
              label: 'Show Share Sheet',
              style: AdaptiveButtonStyle.tinted,
              onPressed: () async {
                final result = await AdaptiveBottomSheet.show<String>(
                  context: context,
                  detents: const [
                    AdaptiveSheetDetent.medium,
                    AdaptiveSheetDetent.large,
                  ],
                  builder: (context) => const _ShareSheet(),
                );
                _showResult(result);
              },
            ),
          ),
          const SizedBox(height: 24),
          _buildSection(
            isDark,
            title: 'Full Height',
            description: 'A single large detent: the system page sheet on iOS',
            child: AdaptiveButton(
              label: 'Show Full Height Sheet',
              style: AdaptiveButtonStyle.tinted,
              onPressed: () async {
                final result = await AdaptiveBottomSheet.show<String>(
                  context: context,
                  builder: (context) => const _ShareSheet(),
                );
                _showResult(result);
              },
            ),
          ),
          const SizedBox(height: 24),
          _buildSection(
            isDark,
            title: 'Custom Height, Not Dismissible',
            description:
                'A 35% detent that only closes from its own buttons '
                '(isDismissible: false)',
            child: AdaptiveButton(
              label: 'Show Confirmation',
              style: AdaptiveButtonStyle.tinted,
              onPressed: () async {
                final result = await AdaptiveBottomSheet.show<String>(
                  context: context,
                  detents: const [AdaptiveSheetDetent.fraction(0.35)],
                  isDismissible: false,
                  builder: (context) => const _ConfirmSheet(),
                );
                _showResult(result);
              },
            ),
          ),
          if (_lastResult != null) ...[
            const SizedBox(height: 24),
            AdaptiveCard(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Last result: $_lastResult',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoCard(bool isDark) {
    final String text;
    if (PlatformInfo.isIOS26OrHigher()) {
      text =
          'iOS 26+ draws a floating Liquid Glass sheet on a native '
          'UIVisualEffectView; it meets the screen edges at full height';
    } else if (PlatformInfo.isIOS) {
      text =
          'iOS 18 and below use showCupertinoSheet at full height and the '
          'opaque iOS sheet at smaller detents';
    } else {
      text = 'Android uses a Material 3 modal bottom sheet';
    }

    return AdaptiveCard(
      padding: const EdgeInsets.all(16),
      color: isDark
          ? (PlatformInfo.isIOS
                ? CupertinoColors.systemBlue.darkColor.withValues(alpha: 0.2)
                : Colors.blue.shade900.withValues(alpha: 0.3))
          : (PlatformInfo.isIOS
                ? CupertinoColors.systemBlue.color.withValues(alpha: 0.1)
                : Colors.blue.shade50),
      child: Row(
        children: [
          Icon(
            PlatformInfo.isIOS ? CupertinoIcons.info_circle_fill : Icons.info,
            color: PlatformInfo.isIOS
                ? CupertinoColors.systemBlue
                : Colors.blue.shade700,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    bool isDark, {
    required String title,
    required String description,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          description,
          style: TextStyle(
            fontSize: 14,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
        const SizedBox(height: 16),
        child,
      ],
    );
  }
}

class _ShareSheet extends StatelessWidget {
  const _ShareSheet();

  static const _options = [
    ('Copy Link', CupertinoIcons.link, Icons.link),
    ('Messages', CupertinoIcons.chat_bubble, Icons.message),
    ('Mail', CupertinoIcons.mail, Icons.mail_outline),
    ('Add to Favorites', CupertinoIcons.star, Icons.star_outline),
    (
      'Add to Reading List',
      CupertinoIcons.eyeglasses,
      Icons.chrome_reader_mode,
    ),
    ('Print', CupertinoIcons.printer, Icons.print),
    ('Save to Files', CupertinoIcons.folder, Icons.folder_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.only(
        bottom: MediaQuery.paddingOf(context).bottom + 16,
      ),
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: Text(
            'Share',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
        ),
        for (final (title, iosIcon, androidIcon) in _options)
          AdaptiveListTile(
            leading: Icon(PlatformInfo.isIOS ? iosIcon : androidIcon),
            title: Text(title),
            backgroundColor: Colors.transparent,
            onTap: () => Navigator.of(context).pop(title),
          ),
      ],
    );
  }
}

class _ConfirmSheet extends StatelessWidget {
  const _ConfirmSheet();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        MediaQuery.paddingOf(context).bottom + 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Delete 3 photos?',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          const Text('They are moved to Recently Deleted for 30 days.'),
          const Spacer(),
          AdaptiveButton(
            label: 'Delete',
            onPressed: () => Navigator.of(context).pop('Deleted'),
          ),
          const SizedBox(height: 8),
          AdaptiveButton(
            label: 'Cancel',
            style: AdaptiveButtonStyle.plain,
            onPressed: () => Navigator.of(context).pop('Cancelled'),
          ),
        ],
      ),
    );
  }
}
