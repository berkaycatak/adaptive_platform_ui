import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';

class ButtonDemoPage extends StatefulWidget {
  const ButtonDemoPage({super.key});

  @override
  State<ButtonDemoPage> createState() => _ButtonDemoPageState();
}

class _ButtonDemoPageState extends State<ButtonDemoPage> {
  int _pressCount = 0;
  AdaptiveButtonStyle _selectedStyle = AdaptiveButtonStyle.prominentGlass;
  AdaptiveButtonSize _selectedSize = AdaptiveButtonSize.medium;

  void _handlePress() => setState(() => _pressCount++);

  @override
  Widget build(BuildContext context) {
    // Use AdaptiveScaffold with single content (no tabs)
    return AdaptiveScaffold(
      title: 'AdaptiveButton Demo',
      destinations: const [],
      selectedIndex: 0,
      actions: [
        AdaptiveAppBarAction(
          iosSymbol: 'info.circle',
          androidIcon: Icons.info_outline,
          onPressed: () {
            showAboutDialog(
              context: context,
              applicationName: 'Adaptive Platform UI',
              applicationVersion: '1.0.0',
              applicationLegalese: '© 2024 Your Company',
            );
          },
        ),
      ],
      onDestinationSelected: (_) {},
      children: [_buildContent()],
    );
  }

  Widget _buildContent() {
    return ListView(
      padding: EdgeInsets.only(
        left: 16.0,
        right: 16.0,
        top: 16.0 + MediaQuery.of(context).padding.top + 52, // Toolbar height
        bottom: 16.0,
      ),
      children: [
        // Style Selector
        _buildSection(
          'Button Style',
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: AdaptiveButtonStyle.values.map((style) {
              return _buildChip(
                _getStyleName(style),
                _selectedStyle == style,
                () => setState(() => _selectedStyle = style),
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: 24),

        // Size Selector
        _buildSection(
          'Button Size',
          Wrap(
            spacing: 8,
            children: AdaptiveButtonSize.values.map((size) {
              return _buildChip(
                _getSizeName(size),
                _selectedSize == size,
                () => setState(() => _selectedSize = size),
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: 32),

        // Interactive Demo
        Center(
          child: Column(
            children: [
              AdaptiveButton(
                onPressed: _handlePress,
                style: _selectedStyle,
                size: _selectedSize,
                label: 'Press Me',
                textColor: Colors.white,
              ),
              const SizedBox(height: 16),
              Text(
                'Pressed $_pressCount times',
                style: TextStyle(
                  fontSize: 16,
                  color: PlatformInfo.isIOS
                      ? CupertinoColors.secondaryLabel
                      : Colors.black54,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 32),

        // All Styles Showcase
        _buildSection(
          'All Button Styles',
          Column(
            children: [
              _buildButtonRow('Filled', AdaptiveButtonStyle.filled),
              const SizedBox(height: 12),
              _buildButtonRow('Tinted', AdaptiveButtonStyle.tinted),
              const SizedBox(height: 12),
              _buildButtonRow('Gray', AdaptiveButtonStyle.gray),
              const SizedBox(height: 12),
              _buildButtonRow('Bordered', AdaptiveButtonStyle.bordered),
              const SizedBox(height: 12),
              _buildButtonRow('Plain', AdaptiveButtonStyle.plain),
              const SizedBox(height: 12),
              _buildButtonRow('Glass', AdaptiveButtonStyle.glass),
              const SizedBox(height: 12),
              _buildButtonRow(
                'Prominent Glass',
                AdaptiveButtonStyle.prominentGlass,
              ),
            ],
          ),
        ),

        const SizedBox(height: 32),

        // Child Mode Example
        _buildSection(
          'Child Mode',
          Column(
            children: [
              AdaptiveButton.child(
                onPressed: _handlePress,
                style: AdaptiveButtonStyle.prominentGlass,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Text('⭐', style: TextStyle(fontSize: 16)),
                    SizedBox(width: 8),
                    Text('Custom Widget'),
                    SizedBox(width: 8),
                    Text('⭐', style: TextStyle(fontSize: 16)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        _buildSection(
          'Icon Mode',
          Column(
            children: [
              AdaptiveButton.icon(
                onPressed: _handlePress,
                style: AdaptiveButtonStyle.prominentGlass,
                icon: CupertinoIcons.add_circled_solid,
              ),
            ],
          ),
        ),

        const SizedBox(height: 32),
        _buildSection(
          'SF Symbol Mode (iOS 26 Native)',
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              AdaptiveButton.sfSymbol(
                onPressed: _handlePress,
                style: AdaptiveButtonStyle.glass,
                sfSymbol: const SFSymbol('star.fill', size: 13),
              ),
              AdaptiveButton.sfSymbol(
                onPressed: _handlePress,
                style: AdaptiveButtonStyle.prominentGlass,
                sfSymbol: const SFSymbol('heart.fill', size: 14),
              ),
              AdaptiveButton.sfSymbol(
                onPressed: _handlePress,
                style: AdaptiveButtonStyle.filled,
                sfSymbol: const SFSymbol('plus.app.fill', size: 13),
              ),
              AdaptiveButton.sfSymbol(
                onPressed: _handlePress,
                style: AdaptiveButtonStyle.tinted,
                sfSymbol: const SFSymbol('trash.fill', size: 21),
              ),
              AdaptiveButton.sfSymbol(
                onPressed: _handlePress,
                style: AdaptiveButtonStyle.bordered,
                sfSymbol: const SFSymbol('square.and.arrow.up', size: 24),
              ),
            ],
          ),
        ),

        const SizedBox(height: 32),

        // Disabled State
        _buildSection(
          'Disabled State',
          Center(
            child: AdaptiveButton(
              onPressed: null,
              style: _selectedStyle,
              size: _selectedSize,
              label: 'Disabled',
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

  Widget _buildChip(String label, bool selected, VoidCallback onTap) {
    if (PlatformInfo.isIOS) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: selected
                ? CupertinoColors.systemBlue
                : CupertinoColors.systemGrey5,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: selected ? CupertinoColors.white : CupertinoColors.label,
            ),
          ),
        ),
      );
    }

    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
    );
  }

  Widget _buildButtonRow(String label, AdaptiveButtonStyle style) {
    return Row(
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: PlatformInfo.isIOS
                  ? CupertinoColors.secondaryLabel
                  : Colors.black54,
            ),
          ),
        ),
        Expanded(
          child: AdaptiveButton(
            onPressed: _handlePress,
            style: style,
            size: AdaptiveButtonSize.medium,
            label: label,
          ),
        ),
      ],
    );
  }

  String _getStyleName(AdaptiveButtonStyle style) {
    switch (style) {
      case AdaptiveButtonStyle.filled:
        return 'Filled';
      case AdaptiveButtonStyle.tinted:
        return 'Tinted';
      case AdaptiveButtonStyle.gray:
        return 'Gray';
      case AdaptiveButtonStyle.bordered:
        return 'Bordered';
      case AdaptiveButtonStyle.plain:
        return 'Plain';
      case AdaptiveButtonStyle.glass:
        return 'Glass';
      case AdaptiveButtonStyle.prominentGlass:
        return 'Prominent Glass';
    }
  }

  String _getSizeName(AdaptiveButtonSize size) {
    switch (size) {
      case AdaptiveButtonSize.small:
        return 'Small';
      case AdaptiveButtonSize.medium:
        return 'Medium';
      case AdaptiveButtonSize.large:
        return 'Large';
    }
  }
}
