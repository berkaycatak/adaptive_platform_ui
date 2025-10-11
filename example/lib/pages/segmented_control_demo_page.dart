import 'package:flutter/cupertino.dart';
import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';

class SegmentedControlDemoPage extends StatefulWidget {
  const SegmentedControlDemoPage({super.key});

  @override
  State<SegmentedControlDemoPage> createState() =>
      _SegmentedControlDemoPageState();
}

class _SegmentedControlDemoPageState extends State<SegmentedControlDemoPage> {
  int _basicSegmentedControlIndex = 0;
  int _coloredSegmentedControlIndex = 1;
  int _shrinkWrappedSegmentedControlIndex = 0;
  int _iconSegmentedControlIndex = 0;

  @override
  Widget build(BuildContext context) {
    return AdaptiveScaffold(
      title: 'Segmented Control',
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(
            left: 24.0,
            right: 24.0,
            top: 100.0,
            bottom: 16.0,
          ),
          children: [
            Row(
              children: [
                const Text('Basic'),
                const Spacer(),
                Text('Selected: ${_basicSegmentedControlIndex + 1}'),
              ],
            ),
            const SizedBox(height: 12),
            AdaptiveSegmentedControl(
              labels: const ['One', 'Two', 'Three'],
              selectedIndex: _basicSegmentedControlIndex,
              onValueChanged: (i) =>
                  setState(() => _basicSegmentedControlIndex = i),
            ),

            const SizedBox(height: 48),

            Row(
              children: [
                const Text('Colored'),
                const Spacer(),
                Text('Selected: ${_shrinkWrappedSegmentedControlIndex + 1}'),
              ],
            ),
            const SizedBox(height: 12),
            AdaptiveSegmentedControl(
              labels: const ['One', 'Two', 'Three'],
              selectedIndex: _shrinkWrappedSegmentedControlIndex,
              color: CupertinoColors.systemPink,
              onValueChanged: (i) =>
                  setState(() => _shrinkWrappedSegmentedControlIndex = i),
            ),

            const SizedBox(height: 48),

            Row(
              children: [
                const Text('Shrink wrap'),
                const Spacer(),
                Text('Selected: ${_coloredSegmentedControlIndex + 1}'),
              ],
            ),
            const SizedBox(height: 12),
            AdaptiveSegmentedControl(
              labels: const ['One', 'Two', 'Three'],
              selectedIndex: _coloredSegmentedControlIndex,
              onValueChanged: (i) =>
                  setState(() => _coloredSegmentedControlIndex = i),
              shrinkWrap: true,
            ),

            const SizedBox(height: 48),

            Row(
              children: [
                const Text('Icons'),
                const Spacer(),
                Text('Selected: ${_iconSegmentedControlIndex + 1}'),
              ],
            ),
            const SizedBox(height: 12),
            Center(
              child: AdaptiveSegmentedControl(
                labels: const [],
                sfSymbols: const [
                  'house.fill',
                  'leaf.arrow.trianglehead.clockwise',
                  'figure.walk.diamond',
                ],
                selectedIndex: _iconSegmentedControlIndex,
                iconColor: CupertinoColors.systemBlue,
                shrinkWrap: true,
                onValueChanged: (i) =>
                    setState(() => _iconSegmentedControlIndex = i),
                height: 48,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
