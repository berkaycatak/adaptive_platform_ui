import 'package:flutter/material.dart';
import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';

class NavigationPage3 extends StatelessWidget {
  const NavigationPage3({super.key});

  @override
  Widget build(BuildContext context) {
    return AdaptiveScaffold(
      appBar: AdaptiveAppBar(title: 'Page 3'),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.looks_3, size: 64, color: Colors.green),
            const SizedBox(height: 24),
            const Text(
              'Page 3',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text('Last page — use back button to go back'),
          ],
        ),
      ),
    );
  }
}
