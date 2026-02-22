import 'package:adaptive_platform_ui_example/service/router/router_service.dart';
import 'package:flutter/material.dart';
import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';

class NavigationPage1 extends StatelessWidget {
  const NavigationPage1({super.key});

  @override
  Widget build(BuildContext context) {
    return AdaptiveScaffold(
      useHeroBackButton: true,
      appBar: AdaptiveAppBar(title: 'Page 1'),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.looks_one, size: 64, color: Colors.blue),
            const SizedBox(height: 24),
            const Text(
              'Page 1',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text('First page in navigation chain'),
            const SizedBox(height: 32),
            AdaptiveButton(
              onPressed: () {
                RouterService.pushNamed(
                  context: context,
                  route: RouterService.routes.navigationPage2,
                );
              },
              label: 'Go to Page 2',
            ),
          ],
        ),
      ),
    );
  }
}
