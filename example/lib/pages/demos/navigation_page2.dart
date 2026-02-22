import 'package:adaptive_platform_ui_example/service/router/router_service.dart';
import 'package:flutter/material.dart';
import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';

class NavigationPage2 extends StatelessWidget {
  const NavigationPage2({super.key});

  @override
  Widget build(BuildContext context) {
    return AdaptiveScaffold(
      appBar: AdaptiveAppBar(title: 'Page 2'),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.looks_two, size: 64, color: Colors.orange),
            const SizedBox(height: 24),
            const Text(
              'Page 2',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text('Second page in navigation chain'),
            const SizedBox(height: 32),
            AdaptiveButton(
              onPressed: () {
                RouterService.pushNamed(
                  context: context,
                  route: RouterService.routes.navigationPage3,
                );
              },
              label: 'Go to Page 3',
            ),
          ],
        ),
      ),
    );
  }
}
