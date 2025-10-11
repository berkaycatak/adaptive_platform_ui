import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';

/// Demo page for iOS 26 Native Search Tab Bar
///
/// EXPERIMENTAL: This feature completely replaces Flutter's navigation
class NativeSearchTabDemoPage extends StatefulWidget {
  const NativeSearchTabDemoPage({super.key});

  @override
  State<NativeSearchTabDemoPage> createState() =>
      _NativeSearchTabDemoPageState();
}

class _NativeSearchTabDemoPageState extends State<NativeSearchTabDemoPage> {
  int _currentTab = 0;
  String _searchQuery = '';
  bool _isNativeEnabled = false;

  @override
  Widget build(BuildContext context) {
    return AdaptiveScaffold(
      title: 'Native Search Tab (iOS 26+)',
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    final topPadding = PlatformInfo.isIOS ? 130.0 : 16.0;

    return ListView(
      padding: EdgeInsets.only(
        left: 16.0,
        right: 16.0,
        top: topPadding,
        bottom: 16.0,
      ),
      children: [
        _buildWarningCard(),
        const SizedBox(height: 24),
        _buildStatusCard(),
        const SizedBox(height: 24),
        _buildControlsCard(),
        if (_searchQuery.isNotEmpty) ...[
          const SizedBox(height: 24),
          _buildSearchResultsCard(),
        ],
      ],
    );
  }

  Widget _buildWarningCard() {
    return AdaptiveCard(
      padding: const EdgeInsets.all(16),
      color: PlatformInfo.isIOS
          ? CupertinoColors.systemYellow.withValues(alpha: 0.15)
          : Colors.orange.withValues(alpha: 0.15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                PlatformInfo.isIOS
                    ? CupertinoIcons.exclamationmark_triangle_fill
                    : Icons.warning,
                color: PlatformInfo.isIOS
                    ? CupertinoColors.systemYellow
                    : Colors.orange,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'EXPERIMENTAL FEATURE',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: _getTextColor(context),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'This feature completely replaces Flutter\'s navigation system with a native UITabBarController. This may cause:\n\n'
            '• Widget lifecycle issues\n'
            '• State management problems\n'
            '• Hot reload may not work\n'
            '• Navigation stack loss\n\n'
            'Only for iOS 26+ testing!',
            style: TextStyle(
              fontSize: 14,
              color: _getSecondaryTextColor(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    return AdaptiveCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Status',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: _getTextColor(context),
            ),
          ),
          const SizedBox(height: 16),
          _buildStatusRow(
            'Native Tab Bar',
            _isNativeEnabled ? 'Enabled' : 'Disabled',
          ),
          _buildStatusRow('Current Tab', 'Tab $_currentTab'),
          if (_searchQuery.isNotEmpty)
            _buildStatusRow('Search Query', _searchQuery),
        ],
      ),
    );
  }

  Widget _buildStatusRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 15,
              color: _getSecondaryTextColor(context),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: _getTextColor(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlsCard() {
    return AdaptiveCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Controls',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: _getTextColor(context),
            ),
          ),
          const SizedBox(height: 16),
          if (!_isNativeEnabled) ...[
            SizedBox(
              width: double.infinity,
              height: 44,
              child: AdaptiveButton(
                style: PlatformInfo.isIOS26OrHigher()
                    ? AdaptiveButtonStyle.prominentGlass
                    : AdaptiveButtonStyle.filled,
                label: 'Enable Native Tab Bar',
                onPressed: _enableNativeTabBar,
                textColor: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'This will replace the entire app UI with native tabs',
              style: TextStyle(
                fontSize: 13,
                color: _getSecondaryTextColor(context),
              ),
              textAlign: TextAlign.center,
            ),
          ] else ...[
            SizedBox(
              width: double.infinity,
              height: 44,
              child: AdaptiveButton(
                style: AdaptiveButtonStyle.bordered,
                label: 'Disable Native Tab Bar',
                onPressed: _disableNativeTabBar,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: AdaptiveButton(
                style: AdaptiveButtonStyle.tinted,
                label: 'Show Search',
                onPressed: () => IOS26NativeSearchTabBar.showSearch(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSearchResultsCard() {
    return AdaptiveCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Search Results',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: _getTextColor(context),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Query: "$_searchQuery"',
            style: TextStyle(fontSize: 15, color: _getTextColor(context)),
          ),
          const SizedBox(height: 8),
          Text(
            'Search results would appear here...',
            style: TextStyle(
              fontSize: 14,
              color: _getSecondaryTextColor(context),
            ),
          ),
        ],
      ),
    );
  }

  void _enableNativeTabBar() async {
    await IOS26NativeSearchTabBar.enable(
      tabs: [
        const NativeTabConfig(title: 'Home', sfSymbol: 'house.fill'),
        const NativeTabConfig(title: 'Explore', sfSymbol: 'safari'),
        const NativeTabConfig(
          title: 'Search',
          sfSymbol: 'magnifyingglass',
          isSearchTab: true,
        ),
        const NativeTabConfig(title: 'Profile', sfSymbol: 'person.fill'),
      ],
      selectedIndex: 0,
      onTabSelected: (index) {
        setState(() {
          _currentTab = index;
        });
      },
      onSearchQueryChanged: (query) {
        setState(() {
          _searchQuery = query;
        });
      },
      onSearchSubmitted: (query) {
        debugPrint('Search submitted: $query');
      },
      onSearchCancelled: () {
        setState(() {
          _searchQuery = '';
        });
      },
    );

    setState(() {
      _isNativeEnabled = true;
    });
  }

  void _disableNativeTabBar() async {
    await IOS26NativeSearchTabBar.disable();
    setState(() {
      _isNativeEnabled = false;
      _searchQuery = '';
    });
  }

  Color _getTextColor(BuildContext context) {
    final isDark = PlatformInfo.isIOS
        ? MediaQuery.platformBrightnessOf(context) == Brightness.dark
        : Theme.of(context).brightness == Brightness.dark;

    return PlatformInfo.isIOS
        ? (isDark ? CupertinoColors.white : CupertinoColors.black)
        : Theme.of(context).colorScheme.onSurface;
  }

  Color _getSecondaryTextColor(BuildContext context) {
    final isDark = PlatformInfo.isIOS
        ? MediaQuery.platformBrightnessOf(context) == Brightness.dark
        : Theme.of(context).brightness == Brightness.dark;

    return PlatformInfo.isIOS
        ? (isDark ? CupertinoColors.systemGrey : CupertinoColors.systemGrey2)
        : Theme.of(context).colorScheme.onSurfaceVariant;
  }
}
