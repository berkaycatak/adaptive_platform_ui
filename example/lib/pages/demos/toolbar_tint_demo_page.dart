import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';

class ToolbarTintDemoPage extends StatefulWidget {
  const ToolbarTintDemoPage({super.key});

  @override
  State<ToolbarTintDemoPage> createState() => _ToolbarTintDemoPageState();
}

class _ToolbarTintDemoPageState extends State<ToolbarTintDemoPage> {
  int _selectedColorIndex = 0;
  int _checkmarkTintIndex = 2; // Green by default
  int _heartTintIndex = 1; // Red by default

  static const _tintOptions = <_TintOption>[
    _TintOption(name: 'Blue', color: Colors.blue),
    _TintOption(name: 'Red', color: Colors.red),
    _TintOption(name: 'Green', color: Colors.green),
    _TintOption(name: 'Orange', color: Colors.orange),
    _TintOption(name: 'Purple', color: Colors.purple),
    _TintOption(name: 'System Default', color: null),
  ];

  Color? get _currentTint => _tintOptions[_selectedColorIndex].color;
  Color? get _checkmarkTint => _tintOptions[_checkmarkTintIndex].color;
  Color? get _heartTint => _tintOptions[_heartTintIndex].color;

  @override
  Widget build(BuildContext context) {
    return AdaptiveScaffold(
      appBar: AdaptiveAppBar(
        title: '',
        useNativeToolbar: true,
        tintColor: _currentTint,
        actions: [
          // Standard action — inherits global tint
          AdaptiveAppBarAction(
            iosSymbol: 'star',
            icon: Icons.star_outline,
            onPressed: () {},
          ),
          // Prominent action — glass bubble style
          AdaptiveAppBarAction(
            iosSymbol: 'plus',
            icon: Icons.add,
            prominent: true,
            onPressed: () {},
          ),
          // Per-action tint override
          AdaptiveAppBarAction(
            iosSymbol: 'checkmark.circle',
            icon: Icons.check_circle_outline,
            tintColor: _checkmarkTint,
            onPressed: () {},
          ),
          // Prominent + per-action tint
          AdaptiveAppBarAction(
            iosSymbol: 'heart.fill',
            icon: Icons.favorite,
            prominent: true,
            tintColor: _heartTint,
            onPressed: () {},
          ),
        ],
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    final isDark = PlatformInfo.isIOS
        ? MediaQuery.platformBrightnessOf(context) == Brightness.dark
        : Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      top: false,
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 120, 16, 32),
        children: [
          _buildSectionHeader(context, 'Global Tint Color', isDark),
          const SizedBox(height: 8),
          _buildDescription(
            context,
            'Tap a color to change the toolbar\'s global tintColor. '
            'All actions without a per-action tint will update.',
            isDark,
          ),
          const SizedBox(height: 12),
          _buildColorPicker(context, isDark),
          const SizedBox(height: 24),
          _buildSectionHeader(context, 'Toolbar Actions', isDark),
          const SizedBox(height: 8),
          _buildActionInfo(
            context,
            icon: Icons.star_outline,
            title: 'Star — Standard',
            description: 'Inherits the global tint color.',
            isDark: isDark,
          ),
          _buildActionInfo(
            context,
            icon: Icons.add,
            title: 'Plus — Prominent',
            description:
                'Uses prominent: true for a glass bubble style (iOS 26+).',
            isDark: isDark,
          ),
          _buildActionInfoWithPicker(
            context,
            icon: Icons.check_circle_outline,
            title: 'Checkmark — Per-action tint',
            description: 'Per-action tintColor override, ignoring global tint.',
            isDark: isDark,
            selectedIndex: _checkmarkTintIndex,
            onChanged: (i) => setState(() => _checkmarkTintIndex = i),
          ),
          _buildActionInfoWithPicker(
            context,
            icon: Icons.favorite,
            title: 'Heart — Prominent + per-action tint',
            description:
                'Combines prominent: true with per-action tintColor.',
            isDark: isDark,
            selectedIndex: _heartTintIndex,
            onChanged: (i) => setState(() => _heartTintIndex = i),
          ),
          const SizedBox(height: 24),
          _buildSectionHeader(context, 'Platform Behavior', isDark),
          const SizedBox(height: 8),
          _buildPlatformInfo(context, isDark),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    bool isDark,
  ) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
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
    );
  }

  Widget _buildDescription(
    BuildContext context,
    String text,
    bool isDark,
  ) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          color: PlatformInfo.isIOS
              ? (isDark
                    ? CupertinoColors.systemGrey
                    : CupertinoColors.systemGrey2)
              : Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildColorPicker(BuildContext context, bool isDark) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: List.generate(_tintOptions.length, (index) {
        final option = _tintOptions[index];
        final isSelected = _selectedColorIndex == index;
        final displayColor = option.color ??
            (PlatformInfo.isIOS
                ? CupertinoColors.systemBlue
                : Theme.of(context).colorScheme.primary);

        return GestureDetector(
          onTap: () => setState(() => _selectedColorIndex = index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? displayColor.withValues(alpha: 0.2)
                  : (isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.black.withValues(alpha: 0.04)),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? displayColor
                    : (isDark
                          ? Colors.white.withValues(alpha: 0.1)
                          : Colors.black.withValues(alpha: 0.1)),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (option.color != null)
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: option.color,
                      shape: BoxShape.circle,
                    ),
                  )
                else
                  Icon(
                    PlatformInfo.isIOS
                        ? CupertinoIcons.circle
                        : Icons.circle_outlined,
                    size: 16,
                    color: isDark ? Colors.white54 : Colors.black45,
                  ),
                const SizedBox(width: 8),
                Text(
                  option.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    color: isSelected
                        ? displayColor
                        : (isDark ? Colors.white : Colors.black87),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildActionInfo(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required bool isDark,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark
            ? (PlatformInfo.isIOS
                  ? CupertinoColors.darkBackgroundGray
                  : Theme.of(context).colorScheme.surfaceContainerHighest)
            : (PlatformInfo.isIOS
                  ? CupertinoColors.white
                  : Theme.of(context).colorScheme.surfaceContainerHighest),
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
      child: Row(
        children: [
          Icon(icon, size: 24, color: _currentTint ?? Colors.blue),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white54 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionInfoWithPicker(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required bool isDark,
    required int selectedIndex,
    required ValueChanged<int> onChanged,
  }) {
    final actionColor = _tintOptions[selectedIndex].color ?? Colors.blue;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark
            ? (PlatformInfo.isIOS
                  ? CupertinoColors.darkBackgroundGray
                  : Theme.of(context).colorScheme.surfaceContainerHighest)
            : (PlatformInfo.isIOS
                  ? CupertinoColors.white
                  : Theme.of(context).colorScheme.surfaceContainerHighest),
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
              Icon(icon, size: 24, color: actionColor),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.white54 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildMiniColorPicker(
            context,
            isDark: isDark,
            selectedIndex: selectedIndex,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildMiniColorPicker(
    BuildContext context, {
    required bool isDark,
    required int selectedIndex,
    required ValueChanged<int> onChanged,
  }) {
    return Row(
      children: List.generate(_tintOptions.length, (index) {
        final option = _tintOptions[index];
        final isSelected = selectedIndex == index;
        final color = option.color;

        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: GestureDetector(
            onTap: () => onChanged(index),
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color ?? (isDark ? Colors.grey.shade700 : Colors.grey.shade300),
                border: Border.all(
                  color: isSelected
                      ? (isDark ? Colors.white : Colors.black87)
                      : Colors.transparent,
                  width: 2.5,
                ),
              ),
              child: color == null
                  ? Icon(
                      Icons.block,
                      size: 14,
                      color: isDark ? Colors.white54 : Colors.black45,
                    )
                  : null,
            ),
          ),
        );
      }),
    );
  }

  Widget _buildPlatformInfo(BuildContext context, bool isDark) {
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
          _buildPlatformRow(
            'iOS 26+',
            'Native UINavigationBar tintColor + prominent style',
            isDark,
          ),
          const SizedBox(height: 8),
          _buildPlatformRow(
            'iOS <26',
            'Cupertino app bar (tint/prominent ignored)',
            isDark,
          ),
          const SizedBox(height: 8),
          _buildPlatformRow(
            'Android',
            'Material app bar (tint/prominent ignored)',
            isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildPlatformRow(String platform, String info, bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 6,
          height: 6,
          margin: const EdgeInsets.only(top: 6),
          decoration: BoxDecoration(
            color: isDark ? Colors.white54 : Colors.black45,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
              children: [
                TextSpan(
                  text: '$platform: ',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                TextSpan(text: info),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _TintOption {
  final String name;
  final Color? color;
  const _TintOption({required this.name, required this.color});
}
