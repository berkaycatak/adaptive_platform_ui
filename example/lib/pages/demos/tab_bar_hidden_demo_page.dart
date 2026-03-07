import 'package:flutter/material.dart';
import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:adaptive_platform_ui_example/utils/global_variables.dart';

/// Demo page to test AdaptiveScaffold.tabBarHidden.
/// Uses the app-level tabBarHiddenNotifier to control the root tab bar.
class TabBarHiddenDemoPage extends StatefulWidget {
  const TabBarHiddenDemoPage({super.key});

  @override
  State<TabBarHiddenDemoPage> createState() => _TabBarHiddenDemoPageState();
}

class _TabBarHiddenDemoPageState extends State<TabBarHiddenDemoPage> {
  void _toggleHidden() {
    tabBarHiddenNotifier.value = !tabBarHiddenNotifier.value;
  }

  void _showBottomSheetWithHide() {
    tabBarHiddenNotifier.value = true;

    showModalBottomSheet(
      context: context,
      builder: (ctx) => SizedBox(
        height: 300,
        child: Center(
          child: Text(
            'Tab bar is hidden — no bleed-through',
            style: Theme.of(ctx).textTheme.titleMedium,
          ),
        ),
      ),
    ).whenComplete(() {
      tabBarHiddenNotifier.value = false;
    });
  }

  void _showBottomSheetWithoutHide() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SizedBox(
        height: 300,
        child: Center(
          child: Text(
            'Tab bar bleeds through behind this sheet',
            style: Theme.of(ctx).textTheme.titleMedium,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AdaptiveScaffold(
      appBar: AdaptiveAppBar(title: 'setHidden Demo'),
      body: Center(
        child: ValueListenableBuilder<bool>(
          valueListenable: tabBarHiddenNotifier,
          builder: (context, isHidden, _) => Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Root tab bar is ${isHidden ? "HIDDEN" : "VISIBLE"}'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _toggleHidden,
                child: Text(isHidden ? 'Show Tab Bar' : 'Hide Tab Bar'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _showBottomSheetWithHide,
                child: const Text('Open Bottom Sheet (hides tab bar)'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _showBottomSheetWithoutHide,
                child: const Text('Open Bottom Sheet (with tab bar)'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
