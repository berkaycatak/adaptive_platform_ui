import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'pages/button_demo_page.dart';
import 'pages/switch_demo_page.dart';
import 'pages/slider_demo_page.dart';

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

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    // Use adaptive scaffold
    if (PlatformInfo.isIOS) {
      return CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          middle: const Text('Adaptive Platform UI'),
          trailing: Text(
            PlatformInfo.platformDescription,
            style: const TextStyle(fontSize: 12),
          ),
        ),
        child: SafeArea(child: _buildContent(context)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Adaptive Platform UI'),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Text(
                PlatformInfo.platformDescription,
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(child: _buildContent(context)),
    );
  }

  Widget _buildContent(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // Platform Info Card
        _buildInfoCard(),
        const SizedBox(height: 24),

        // Components List
        Text(
          'Components',
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
          icon: PlatformInfo.isIOS ? CupertinoIcons.slider_horizontal_3 : Icons.tune,
          onTap: () => _navigateToSliderDemo(context),
        ),

        const SizedBox(height: 12),
        _buildComponentTile(
          context,
          title: 'AdaptiveTabBar',
          description: 'Coming soon...',
          icon: PlatformInfo.isIOS ? CupertinoIcons.square_grid_2x2 : Icons.tab,
          onTap: null,
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
}
