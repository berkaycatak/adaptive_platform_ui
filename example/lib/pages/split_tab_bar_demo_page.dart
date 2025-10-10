import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';

/// Demo page showing iOS 26 Tab Bar Minimize Behavior (Liquid Glass feature)
class SplitTabBarDemoPage extends StatefulWidget {
  const SplitTabBarDemoPage({super.key});

  @override
  State<SplitTabBarDemoPage> createState() => _SplitTabBarDemoPageState();
}

class _SplitTabBarDemoPageState extends State<SplitTabBarDemoPage> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    if (!PlatformInfo.isIOS26OrHigher()) {
      // Show message for non-iOS 26 platforms
      return AdaptiveScaffold(
        title: 'Tab Bar Minimize',
        destinations: const [],
        selectedIndex: 0,
        onDestinationSelected: (_) {},
        children: [
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      PlatformInfo.isIOS
                          ? CupertinoIcons.info_circle
                          : Icons.info_outline,
                      size: 64,
                      color: PlatformInfo.isIOS
                          ? CupertinoColors.systemGrey
                          : Colors.grey,
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Tab Bar Minimize',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      PlatformInfo.isIOS
                          ? 'This feature requires iOS 26 or higher.\n\nTab bar minimize behavior is part of the Liquid Glass design system.'
                          : 'Tab bar minimize behavior is only available on iOS 26+',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: PlatformInfo.isIOS
                            ? CupertinoColors.systemGrey
                            : Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    }

    // iOS 26+ Tab Bar Minimize Demo using AdaptiveScaffold
    return AdaptiveScaffold(
      title: 'Tab Bar Minimize Demo',
      destinations: const [
        AdaptiveNavigationDestination(
          icon: 'house',
          selectedIcon: 'house.fill',
          label: 'Home',
        ),
        AdaptiveNavigationDestination(
          icon: 'books.vertical',
          selectedIcon: 'books.vertical.fill',
          label: 'Library',
        ),
        AdaptiveNavigationDestination(
          icon: 'magnifyingglass',
          label: 'Search',
          isSearch: true,
        ),
        AdaptiveNavigationDestination(icon: 'gear', label: 'Settings'),
      ],
      selectedIndex: _selectedIndex,
      onDestinationSelected: (index) {
        setState(() {
          _selectedIndex = index;
        });
      },
      // iOS 26+ Tab Bar Minimize Behavior
      minimizeBehavior: TabBarMinimizeBehavior.onScrollUp,
      actions: [
        CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Text(
            'iOS 26+',
            style: TextStyle(fontSize: 12, color: CupertinoColors.systemGreen),
          ),
          onPressed: () {},
        ),
      ],
      children: [
        _buildHomePage(),
        _buildLibraryPage(),
        _buildSearchPage(),
        _buildSettingsPage(),
      ],
    );
  }

  Widget _buildHomePage() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildInfoCard(
          'Tab Bar Minimize',
          'iOS 26 Liquid Glass minimize behavior',
          CupertinoIcons.arrow_down_to_line,
          CupertinoColors.systemBlue,
        ),
        const SizedBox(height: 24),
        _buildDescriptionSection(),
        const SizedBox(height: 24),
        _buildFeatureList(),
      ],
    );
  }

  Widget _buildDescriptionSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'About Tab Bar Minimize',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          const Text(
            'Tab bar minimize behavior is part of iOS 26\'s Liquid Glass design system. The tab bar automatically minimizes when you scroll down, providing more screen space for content.',
            style: TextStyle(fontSize: 15),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: CupertinoColors.systemBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: CupertinoColors.systemBlue.withValues(alpha: 0.3),
              ),
            ),
            child: const Row(
              children: [
                Icon(
                  CupertinoIcons.info_circle_fill,
                  color: CupertinoColors.systemBlue,
                  size: 20,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Scroll down on any tab to see the tab bar minimize. Scroll up to expand it again.',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: CupertinoColors.systemGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: CupertinoColors.systemGreen.withValues(alpha: 0.3),
              ),
            ),
            child: const Row(
              children: [
                Icon(
                  CupertinoIcons.checkmark_circle_fill,
                  color: CupertinoColors.systemGreen,
                  size: 20,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'This demo uses AdaptiveScaffold with minimizeBehavior: TabBarMinimizeBehavior.onScrollDown',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Features',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        _buildFeatureItem(
          'Liquid Glass Effect',
          'Translucent blur background with iOS 26 styling',
          CupertinoIcons.sparkles,
        ),
        _buildFeatureItem(
          'Scroll-based Minimize',
          'Tab bar minimizes automatically when scrolling down',
          CupertinoIcons.arrow_down_to_line,
        ),
        _buildFeatureItem(
          'Multiple Behaviors',
          'Never, onScrollDown, onScrollUp, or automatic',
          CupertinoIcons.slider_horizontal_3,
        ),
        _buildFeatureItem(
          'Native UITabBar',
          'Powered by native iOS UIKit components',
          CupertinoIcons.device_phone_portrait,
        ),
        _buildFeatureItem(
          'AdaptiveScaffold API',
          'Simple minimizeBehavior parameter',
          CupertinoIcons.checkmark_circle,
        ),
      ],
    );
  }

  Widget _buildFeatureItem(String title, String description, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: CupertinoColors.systemBlue, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 13,
                    color: CupertinoColors.systemGrey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLibraryPage() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildInfoCard(
          'Library',
          'Your content library',
          CupertinoIcons.book,
          CupertinoColors.systemPurple,
        ),
        const SizedBox(height: 16),
        ...List.generate(5, (index) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: CupertinoColors.systemGrey6,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemPurple,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    CupertinoIcons.book_fill,
                    color: CupertinoColors.white,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Item ${index + 1}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Text(
                        'Description',
                        style: TextStyle(
                          fontSize: 13,
                          color: CupertinoColors.systemGrey,
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
          );
        }),
      ],
    );
  }

  Widget _buildSearchPage() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildInfoCard(
          'Search',
          'Find what you\'re looking for',
          CupertinoIcons.search,
          CupertinoColors.systemOrange,
        ),
        const SizedBox(height: 16),
        const CupertinoSearchTextField(placeholder: 'Search...'),
      ],
    );
  }

  Widget _buildSettingsPage() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildInfoCard(
          'Settings',
          'Pinned on the right side',
          CupertinoIcons.gear,
          CupertinoColors.systemGrey,
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: CupertinoColors.systemGreen.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: CupertinoColors.systemGreen.withValues(alpha: 0.3),
            ),
          ),
          child: const Row(
            children: [
              Icon(
                CupertinoIcons.checkmark_circle_fill,
                color: CupertinoColors.systemGreen,
                size: 24,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Settings tab - scroll up or down to see tab bar minimize behavior',
                  style: TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ...['Account', 'Notifications', 'Privacy', 'Help'].map((title) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: CupertinoColors.systemGrey6,
              borderRadius: BorderRadius.circular(12),
            ),
            child: CupertinoListTile(
              title: Text(title),
              trailing: const CupertinoListTileChevron(),
              onTap: () {},
            ),
          );
        }),
      ],
    );
  }

  Widget _buildInfoCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 32, color: CupertinoColors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 14,
                    color: CupertinoColors.systemGrey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
