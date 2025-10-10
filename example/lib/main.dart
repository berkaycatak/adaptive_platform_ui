import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'pages/button_demo_page.dart';
import 'pages/switch_demo_page.dart';
import 'pages/slider_demo_page.dart';
import 'pages/segmented_control_demo_page.dart';
import 'pages/alert_dialog_demo_page.dart';
import 'pages/popup_menu_demo_page.dart';
import 'pages/scaffold_demo_page.dart';
import 'pages/split_tab_bar_demo_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Use Material app for Android, Cupertino for iOS
    if (PlatformInfo.isIOS) {
      return const CupertinoApp(
        title: 'Adaptive Platform UI',
        theme: CupertinoThemeData(primaryColor: CupertinoColors.systemBlue),
        home: HomePage(),
      );
    }

    return MaterialApp(
      title: 'Adaptive Platform UI',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return AdaptiveScaffold(
      enableBlur: true,
      title: 'Adaptive Platform UI',
      destinations: const [
        AdaptiveNavigationDestination(
          icon: 'house',
          selectedIcon: 'house.fill',
          label: 'Components',
        ),
        AdaptiveNavigationDestination(
          icon: 'star',
          selectedIcon: 'star.fill',
          label: 'Examples',
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
      // iOS 26+ Tab Bar with minimize behavior
      minimizeBehavior: TabBarMinimizeBehavior.automatic,

      actions: [
        if (PlatformInfo.isIOS)
          CupertinoButton(
            padding: EdgeInsets.zero,
            child: Text(
              PlatformInfo.platformDescription,
              style: const TextStyle(fontSize: 11),
            ),
            onPressed: () {},
          )
        else
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 12.0),
              child: Text(
                PlatformInfo.platformDescription,
                style: const TextStyle(fontSize: 11),
              ),
            ),
          ),
      ],
      children: [
        _buildComponentsTab(context),
        _buildExamplesTab(context),
        _buildSearchTab(context),
        _buildSettingsTab(context),
      ],
    );
  }

  Widget _buildComponentsTab(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // Platform Info Card
        _buildInfoCard(),
        const SizedBox(height: 24),

        // Components List
        Text(
          'UI Components',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: PlatformInfo.isIOS ? CupertinoColors.label : Colors.black87,
          ),
        ),
        const SizedBox(height: 16),

        _buildComponentTile(
          context,
          title: 'AdaptiveButton',
          description: 'iOS 26 Liquid Glass buttons with adaptive styles',
          icon: PlatformInfo.isIOS
              ? CupertinoIcons.square_fill_on_square_fill
              : Icons.smart_button,
          onTap: () => _navigateToButtonDemo(context),
        ),

        const SizedBox(height: 12),
        _buildComponentTile(
          context,
          title: 'AdaptiveSlider',
          description: 'Native iOS 26 slider with drag support',
          icon: PlatformInfo.isIOS
              ? CupertinoIcons.slider_horizontal_3
              : Icons.tune,
          onTap: () => _navigateToSliderDemo(context),
        ),

        const SizedBox(height: 12),
        _buildComponentTile(
          context,
          title: 'AdaptiveSwitch',
          description: 'Native iOS 26 switch with adaptive styles',
          icon: PlatformInfo.isIOS
              ? CupertinoIcons.switch_camera_solid
              : Icons.toggle_on,
          onTap: () => _navigateToSwitchDemo(context),
        ),

        const SizedBox(height: 12),
        _buildComponentTile(
          context,
          title: 'AdaptiveSegmentedControl',
          description: 'Native iOS 26 segmented control with Liquid Glass',
          icon: PlatformInfo.isIOS
              ? CupertinoIcons.square_split_2x2
              : Icons.segment,
          onTap: () => _navigateToSegmentedControlDemo(context),
        ),

        const SizedBox(height: 12),
        _buildComponentTile(
          context,
          title: 'AdaptiveAlertDialog',
          description: 'Native iOS 26 alert dialog with Liquid Glass',
          icon: PlatformInfo.isIOS
              ? CupertinoIcons.bell_fill
              : Icons.notifications,
          onTap: () => _navigateToAlertDialogDemo(context),
        ),

        const SizedBox(height: 12),
        _buildComponentTile(
          context,
          title: 'AdaptivePopupMenuButton',
          description: 'Native iOS 26 popup menu with UIMenu support',
          icon: PlatformInfo.isIOS
              ? CupertinoIcons.ellipsis_circle
              : Icons.more_vert,
          onTap: () => _navigateToPopupMenuDemo(context),
        ),

        const SizedBox(height: 12),
        _buildComponentTile(
          context,
          title: 'AdaptiveScaffold',
          description: 'Native iOS 26 tab bar with adaptive navigation',
          icon: PlatformInfo.isIOS ? CupertinoIcons.square_grid_2x2 : Icons.tab,
          onTap: () => _navigateToScaffoldDemo(context),
        ),
      ],
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: PlatformInfo.isIOS
            ? CupertinoColors.systemGrey6
            : Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                PlatformInfo.isIOS
                    ? CupertinoIcons.device_phone_portrait
                    : Icons.phone_android,
                size: 24,
                color: PlatformInfo.isIOS
                    ? CupertinoColors.systemBlue
                    : Colors.blue,
              ),
              const SizedBox(width: 8),
              Text(
                'Platform: ${PlatformInfo.platformDescription}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            PlatformInfo.isIOS26OrHigher()
                ? '✨ Using iOS 26 native designs with Liquid Glass'
                : PlatformInfo.isIOS
                ? 'Using Cupertino widgets'
                : 'Using Material Design widgets',
            style: TextStyle(
              fontSize: 14,
              color: PlatformInfo.isIOS
                  ? CupertinoColors.secondaryLabel
                  : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComponentTile(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required VoidCallback? onTap,
  }) {
    final isEnabled = onTap != null;

    if (PlatformInfo.isIOS) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: CupertinoColors.systemGrey6,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: isEnabled
                    ? CupertinoColors.systemBlue
                    : CupertinoColors.systemGrey,
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
                        color: isEnabled
                            ? CupertinoColors.label
                            : CupertinoColors.systemGrey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 14,
                        color: CupertinoColors.secondaryLabel,
                      ),
                    ),
                  ],
                ),
              ),
              if (isEnabled)
                const Icon(
                  CupertinoIcons.chevron_right,
                  color: CupertinoColors.systemGrey,
                  size: 20,
                ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: ListTile(
        leading: Icon(icon, color: isEnabled ? Colors.blue : Colors.grey),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isEnabled ? Colors.black87 : Colors.grey,
          ),
        ),
        subtitle: Text(description),
        trailing: isEnabled
            ? const Icon(Icons.chevron_right, color: Colors.grey)
            : null,
        onTap: onTap,
        enabled: isEnabled,
      ),
    );
  }

  void _navigateToButtonDemo(BuildContext context) {
    if (PlatformInfo.isIOS) {
      Navigator.of(
        context,
      ).push(CupertinoPageRoute(builder: (_) => const ButtonDemoPage()));
    } else {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const ButtonDemoPage()));
    }
  }

  void _navigateToSwitchDemo(BuildContext context) {
    if (PlatformInfo.isIOS) {
      Navigator.of(
        context,
      ).push(CupertinoPageRoute(builder: (_) => const SwitchDemoPage()));
    } else {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const SwitchDemoPage()));
    }
  }

  void _navigateToSliderDemo(BuildContext context) {
    if (PlatformInfo.isIOS) {
      Navigator.of(
        context,
      ).push(CupertinoPageRoute(builder: (_) => const SliderDemoPage()));
    } else {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const SliderDemoPage()));
    }
  }

  void _navigateToSegmentedControlDemo(BuildContext context) {
    if (PlatformInfo.isIOS) {
      Navigator.of(context).push(
        CupertinoPageRoute(builder: (_) => const SegmentedControlDemoPage()),
      );
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const SegmentedControlDemoPage()),
      );
    }
  }

  void _navigateToAlertDialogDemo(BuildContext context) {
    if (PlatformInfo.isIOS) {
      Navigator.of(
        context,
      ).push(CupertinoPageRoute(builder: (_) => const AlertDialogDemoPage()));
    } else {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const AlertDialogDemoPage()));
    }
  }

  void _navigateToPopupMenuDemo(BuildContext context) {
    if (PlatformInfo.isIOS) {
      Navigator.of(
        context,
      ).push(CupertinoPageRoute(builder: (_) => const PopupMenuDemoPage()));
    } else {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const PopupMenuDemoPage()));
    }
  }

  void _navigateToScaffoldDemo(BuildContext context) {
    if (PlatformInfo.isIOS) {
      Navigator.of(
        context,
      ).push(CupertinoPageRoute(builder: (_) => const ScaffoldDemoPage()));
    } else {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const ScaffoldDemoPage()));
    }
  }

  void _navigateToSplitTabBarDemo(BuildContext context) {
    if (PlatformInfo.isIOS) {
      Navigator.of(
        context,
      ).push(CupertinoPageRoute(builder: (_) => const SplitTabBarDemoPage()));
    } else {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const SplitTabBarDemoPage()));
    }
  }

  Widget _buildExamplesTab(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        Text(
          'Examples',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: PlatformInfo.isIOS ? CupertinoColors.label : Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        _buildInfoCard(),
        const SizedBox(height: 24),
        _buildExampleCard(
          'Complete Scaffold Demo',
          'A full example using AdaptiveScaffold with tabs, navigation, and actions',
          PlatformInfo.isIOS ? CupertinoIcons.square_grid_2x2 : Icons.dashboard,
          () => _navigateToScaffoldDemo(context),
        ),
        const SizedBox(height: 12),
        _buildExampleCard(
          'Tab Bar Minimize (iOS 26)',
          'iOS 26 Liquid Glass tab bar minimize behavior',
          PlatformInfo.isIOS
              ? CupertinoIcons.arrow_down_to_line
              : Icons.keyboard_arrow_down,
          () => _navigateToSplitTabBarDemo(context),
        ),
        const SizedBox(height: 12),
        _buildExampleCard(
          'Form Example',
          'Coming soon: Complete form with adaptive inputs',
          PlatformInfo.isIOS ? CupertinoIcons.doc_text : Icons.description,
          null,
        ),
        const SizedBox(height: 12),
        _buildExampleCard(
          'List View Example',
          'Coming soon: Adaptive list with swipe actions',
          PlatformInfo.isIOS ? CupertinoIcons.list_bullet : Icons.list,
          null,
        ),
      ],
    );
  }

  Widget _buildSearchTab(BuildContext context) {
    final allComponents = [
      'AdaptiveButton',
      'AdaptiveSlider',
      'AdaptiveSwitch',
      'AdaptiveSegmentedControl',
      'AdaptiveAlertDialog',
      'AdaptivePopupMenuButton',
      'AdaptiveScaffold',
    ];

    final filteredComponents = _searchQuery.isEmpty
        ? allComponents
        : allComponents
              .where(
                (c) => c.toLowerCase().contains(_searchQuery.toLowerCase()),
              )
              .toList();

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        Text(
          'Search Components',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: PlatformInfo.isIOS ? CupertinoColors.label : Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        // Search field
        if (PlatformInfo.isIOS)
          CupertinoSearchTextField(
            placeholder: 'Search components...',
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          )
        else
          TextField(
            decoration: const InputDecoration(
              hintText: 'Search components...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: PlatformInfo.isIOS
                ? CupertinoColors.systemBlue.withOpacity(0.1)
                : Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                PlatformInfo.isIOS
                    ? CupertinoIcons.info_circle_fill
                    : Icons.info,
                color: PlatformInfo.isIOS
                    ? CupertinoColors.systemBlue
                    : Colors.blue,
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'This is a search tab (isSearch: true). In iOS 18+, search tabs are visually separated.',
                  style: TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Results (${filteredComponents.length})',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: PlatformInfo.isIOS
                ? CupertinoColors.secondaryLabel
                : Colors.black54,
          ),
        ),
        const SizedBox(height: 12),
        ...filteredComponents.map((component) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: PlatformInfo.isIOS
                  ? CupertinoColors.systemGrey6
                  : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  PlatformInfo.isIOS ? CupertinoIcons.cube_box : Icons.widgets,
                  color: PlatformInfo.isIOS
                      ? CupertinoColors.systemBlue
                      : Colors.blue,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    component,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Icon(
                  PlatformInfo.isIOS
                      ? CupertinoIcons.chevron_right
                      : Icons.chevron_right,
                  color: PlatformInfo.isIOS
                      ? CupertinoColors.systemGrey
                      : Colors.grey,
                  size: 20,
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildSettingsTab(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        Text(
          'Settings',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: PlatformInfo.isIOS ? CupertinoColors.label : Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: PlatformInfo.isIOS
                ? CupertinoColors.systemGrey6
                : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Icon(
                PlatformInfo.isIOS ? CupertinoIcons.gear : Icons.settings,
                size: 60,
                color: PlatformInfo.isIOS
                    ? CupertinoColors.systemBlue
                    : Colors.blue,
              ),
              const SizedBox(height: 16),
              const Text(
                'Adaptive Platform UI',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Version 1.0.0',
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
        const SizedBox(height: 24),
        _buildSettingSection('About', [
          _buildSettingTile(
            'Platform',
            PlatformInfo.platformDescription,
            PlatformInfo.isIOS
                ? CupertinoIcons.device_phone_portrait
                : Icons.phone_android,
          ),
          _buildSettingTile(
            'iOS Version',
            PlatformInfo.isIOS26OrHigher() ? 'iOS 26+' : 'iOS < 26',
            PlatformInfo.isIOS ? CupertinoIcons.info_circle : Icons.info,
          ),
          _buildSettingTile(
            'Design System',
            PlatformInfo.isIOS26OrHigher()
                ? 'Native Liquid Glass'
                : PlatformInfo.isIOS
                ? 'Cupertino'
                : 'Material Design 3',
            PlatformInfo.isIOS ? CupertinoIcons.paintbrush : Icons.palette,
          ),
        ]),
        const SizedBox(height: 24),
        _buildSettingSection('Links', [
          _buildSettingTile(
            'Documentation',
            'View package documentation',
            PlatformInfo.isIOS ? CupertinoIcons.book : Icons.book,
          ),
          _buildSettingTile(
            'GitHub',
            'View source code',
            PlatformInfo.isIOS ? CupertinoIcons.link : Icons.link,
          ),
          _buildSettingTile(
            'Report Issue',
            'Found a bug? Let us know',
            PlatformInfo.isIOS
                ? CupertinoIcons.exclamationmark_bubble
                : Icons.bug_report,
          ),
        ]),
      ],
    );
  }

  Widget _buildExampleCard(
    String title,
    String description,
    IconData icon,
    VoidCallback? onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: PlatformInfo.isIOS
              ? CupertinoColors.systemGrey6
              : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: onTap != null
                    ? (PlatformInfo.isIOS
                          ? CupertinoColors.systemBlue
                          : Colors.blue)
                    : (PlatformInfo.isIOS
                          ? CupertinoColors.systemGrey
                          : Colors.grey),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: onTap != null
                          ? (PlatformInfo.isIOS
                                ? CupertinoColors.label
                                : Colors.black87)
                          : (PlatformInfo.isIOS
                                ? CupertinoColors.systemGrey
                                : Colors.grey),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 13,
                      color: PlatformInfo.isIOS
                          ? CupertinoColors.secondaryLabel
                          : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              Icon(
                PlatformInfo.isIOS
                    ? CupertinoIcons.chevron_right
                    : Icons.chevron_right,
                color: PlatformInfo.isIOS
                    ? CupertinoColors.systemGrey
                    : Colors.grey,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: PlatformInfo.isIOS
                  ? CupertinoColors.systemGrey
                  : Colors.grey.shade700,
            ),
          ),
        ),
        ...children,
      ],
    );
  }

  Widget _buildSettingTile(String title, String subtitle, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: PlatformInfo.isIOS
            ? CupertinoColors.systemGrey6
            : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: PlatformInfo.isIOS
                ? CupertinoColors.systemBlue
                : Colors.blue,
          ),
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
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: PlatformInfo.isIOS
                        ? CupertinoColors.secondaryLabel
                        : Colors.grey.shade600,
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
