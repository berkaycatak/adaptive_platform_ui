import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';

class ScaffoldDemoPage extends StatefulWidget {
  const ScaffoldDemoPage({super.key});

  @override
  State<ScaffoldDemoPage> createState() => _ScaffoldDemoPageState();
}

class _ScaffoldDemoPageState extends State<ScaffoldDemoPage> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return AdaptiveScaffold(
      title: 'Adaptive Scaffold',
      destinations: const [
        AdaptiveNavigationDestination(
          icon: 'house',
          selectedIcon: 'house.fill',
          label: 'Home',
        ),
        AdaptiveNavigationDestination(
          icon: 'magnifyingglass',
          label: 'Search',
        ),
        AdaptiveNavigationDestination(
          icon: 'heart',
          selectedIcon: 'heart.fill',
          label: 'Favorites',
        ),
        AdaptiveNavigationDestination(
          icon: 'person',
          selectedIcon: 'person.fill',
          label: 'Profile',
        ),
      ],
      selectedIndex: _selectedIndex,
      onDestinationSelected: (index) {
        setState(() {
          _selectedIndex = index;
        });
      },
      actions: [
        if (PlatformInfo.isIOS)
          CupertinoButton(
            padding: EdgeInsets.zero,
            child: const Icon(CupertinoIcons.add),
            onPressed: () {
              _showAddDialog(context);
            },
          )
        else
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              _showAddDialog(context);
            },
          ),
      ],
      children: [
        _buildHomePage(),
        _buildSearchPage(),
        _buildFavoritesPage(),
        _buildProfilePage(),
      ],
    );
  }

  Widget _buildHomePage() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildInfoCard(
          'Home Tab',
          'This is the home page using AdaptiveScaffold',
          PlatformInfo.isIOS ? CupertinoIcons.house_fill : Icons.home,
        ),
        const SizedBox(height: 16),
        _buildFeatureCard(
          'iOS 26+',
          'Native UITabBar with Liquid Glass effect',
          CupertinoColors.systemBlue,
        ),
        const SizedBox(height: 12),
        _buildFeatureCard(
          'iOS <26',
          'CupertinoTabScaffold with standard iOS styling',
          CupertinoColors.systemIndigo,
        ),
        const SizedBox(height: 12),
        _buildFeatureCard(
          'Android',
          'Material NavigationBar with Material 3 design',
          CupertinoColors.systemGreen,
        ),
      ],
    );
  }

  Widget _buildSearchPage() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildInfoCard(
          'Search Tab',
          'Search functionality would go here',
          PlatformInfo.isIOS ? CupertinoIcons.search : Icons.search,
        ),
        const SizedBox(height: 16),
        if (PlatformInfo.isIOS)
          const CupertinoSearchTextField(
            placeholder: 'Search...',
          )
        else
          const TextField(
            decoration: InputDecoration(
              hintText: 'Search...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
          ),
      ],
    );
  }

  Widget _buildFavoritesPage() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildInfoCard(
          'Favorites Tab',
          'Your favorite items would appear here',
          PlatformInfo.isIOS ? CupertinoIcons.heart_fill : Icons.favorite,
        ),
        const SizedBox(height: 16),
        ...List.generate(5, (index) {
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: Icon(
                PlatformInfo.isIOS ? CupertinoIcons.heart_fill : Icons.favorite,
                color: Colors.red,
              ),
              title: Text('Favorite Item ${index + 1}'),
              subtitle: const Text('Tap to view details'),
              trailing: Icon(
                PlatformInfo.isIOS
                    ? CupertinoIcons.chevron_right
                    : Icons.chevron_right,
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildProfilePage() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildInfoCard(
          'Profile Tab',
          'User profile and settings',
          PlatformInfo.isIOS ? CupertinoIcons.person_fill : Icons.person,
        ),
        const SizedBox(height: 24),
        Center(
          child: Column(
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: PlatformInfo.isIOS
                      ? CupertinoColors.systemBlue
                      : Colors.blue,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  PlatformInfo.isIOS
                      ? CupertinoIcons.person_fill
                      : Icons.person,
                  size: 50,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'John Doe',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'john.doe@example.com',
                style: TextStyle(
                  fontSize: 16,
                  color: PlatformInfo.isIOS
                      ? CupertinoColors.systemGrey
                      : Colors.grey,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        _buildSettingsTile(
          'Account Settings',
          PlatformInfo.isIOS ? CupertinoIcons.gear : Icons.settings,
        ),
        _buildSettingsTile(
          'Notifications',
          PlatformInfo.isIOS ? CupertinoIcons.bell : Icons.notifications,
        ),
        _buildSettingsTile(
          'Privacy',
          PlatformInfo.isIOS ? CupertinoIcons.lock : Icons.lock,
        ),
        _buildSettingsTile(
          'Help & Support',
          PlatformInfo.isIOS ? CupertinoIcons.question_circle : Icons.help,
        ),
      ],
    );
  }

  Widget _buildInfoCard(String title, String subtitle, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: PlatformInfo.isIOS
            ? CupertinoColors.systemGrey6
            : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, size: 40, color: CupertinoColors.systemBlue),
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
                  style: TextStyle(
                    fontSize: 14,
                    color: PlatformInfo.isIOS
                        ? CupertinoColors.systemGrey
                        : Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(String title, String description, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: PlatformInfo.isIOS
                        ? CupertinoColors.systemGrey
                        : Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile(String title, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: PlatformInfo.isIOS
            ? CupertinoColors.systemGrey6
            : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        trailing: Icon(
          PlatformInfo.isIOS
              ? CupertinoIcons.chevron_right
              : Icons.chevron_right,
        ),
        onTap: () {},
      ),
    );
  }

  void _showAddDialog(BuildContext context) {
    if (PlatformInfo.isIOS) {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Add Item'),
          content: const Text('This would show an add item dialog'),
          actions: [
            CupertinoDialogAction(
              child: const Text('Cancel'),
              onPressed: () => Navigator.pop(context),
            ),
            CupertinoDialogAction(
              isDefaultAction: true,
              child: const Text('Add'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Add Item'),
          content: const Text('This would show an add item dialog'),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.pop(context),
            ),
            TextButton(
              child: const Text('Add'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
    }
  }
}
