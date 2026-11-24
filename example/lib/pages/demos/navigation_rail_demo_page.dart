import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// The rail of wide windows (an iPad, a phone turned sideways): native glass
/// on iOS 26, with labels under the icons, a bell with its count and an
/// avatar at the foot. The content scrolls under it, so the glass has
/// something to show.
class NavigationRailDemoPage extends StatefulWidget {
  const NavigationRailDemoPage({super.key});

  @override
  State<NavigationRailDemoPage> createState() => _NavigationRailDemoPageState();
}

class _NavigationRailDemoPageState extends State<NavigationRailDemoPage> {
  static const _destinations = [
    AdaptiveNavigationDestination(
      icon: 'house',
      selectedIcon: 'house.fill',
      label: 'Home',
    ),
    AdaptiveNavigationDestination(
      icon: 'bubble.left.and.bubble.right',
      selectedIcon: 'bubble.left.and.bubble.right.fill',
      label: 'Chat',
    ),
    AdaptiveNavigationDestination(
      icon: 'clock',
      selectedIcon: 'clock.fill',
      label: 'History',
    ),
    AdaptiveNavigationDestination(
      icon: 'banknote',
      selectedIcon: 'banknote.fill',
      label: 'Savings',
    ),
    AdaptiveNavigationDestination(
      icon: 'ellipsis.circle',
      selectedIcon: 'ellipsis.circle.fill',
      label: 'More',
    ),
  ];

  static const _colors = [
    Color(0xFFEF5350),
    Color(0xFFFFA726),
    Color(0xFFFFEE58),
    Color(0xFF66BB6A),
    Color(0xFF26C6DA),
    Color(0xFF42A5F5),
    Color(0xFF7E57C2),
    Color(0xFFEC407A),
  ];

  int _selected = 0;
  int _unread = 3;
  bool _labels = true;
  Uint8List? _photo;

  @override
  void initState() {
    super.initState();
    _drawPhoto().then((bytes) {
      if (mounted) setState(() => _photo = bytes);
    });
  }

  /// A stand-in for a profile photo, as PNG bytes.
  Future<Uint8List> _drawPhoto() async {
    const side = 240.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, side, side),
      Paint()
        ..shader = ui.Gradient.linear(
          Offset.zero,
          const Offset(side, side),
          const [Color(0xFF42A5F5), Color(0xFF7E57C2)],
        ),
    );
    final text = TextPainter(
      text: const TextSpan(
        text: 'AB',
        style: TextStyle(
          color: Colors.white,
          fontSize: 96,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    text.paint(
      canvas,
      Offset((side - text.width) / 2, (side - text.height) / 2),
    );
    final image = await recorder.endRecording().toImage(
      side.toInt(),
      side.toInt(),
    );
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data!.buffer.asUint8List();
  }

  @override
  Widget build(BuildContext context) {
    final railWidth = AdaptiveNavigationRail.widthFor(showLabels: _labels);
    final leading = MediaQuery.paddingOf(context).left + railWidth;

    return Scaffold(
      body: Stack(
        children: [
          // Bands of colour under the rail, so the glass refracts something.
          ListView.builder(
            padding: EdgeInsets.zero,
            itemCount: 40,
            itemBuilder: (context, index) => Container(
              height: 72,
              color: _colors[index % _colors.length],
              padding: EdgeInsets.only(left: leading + 16),
              alignment: Alignment.centerLeft,
              child: Text(
                index == 0
                    ? '${_destinations[_selected].label} · $_unread unread'
                    : 'Row $index',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: AdaptiveNavigationRail(
              destinations: _destinations,
              selectedIndex: _selected,
              showLabels: _labels,
              onDestinationSelected: (index) =>
                  setState(() => _selected = index),
              actions: [
                AdaptiveAppBarAction(
                  iosSymbol: 'bell',
                  icon: Icons.notifications_outlined,
                  label: 'Notifications',
                  badgeCount: _unread,
                  onPressed: () => setState(() => _unread = 0),
                ),
                AdaptiveAppBarAction(
                  iosSymbol: 'person.crop.circle',
                  icon: Icons.person_outline,
                  iconImage: _photo,
                  label: 'My profile',
                  onPressed: () {},
                ),
              ],
            ),
          ),
          Positioned(
            right: 16,
            bottom: 16,
            child: SafeArea(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Labels'),
                      Switch(
                        value: _labels,
                        onChanged: (value) => setState(() => _labels = value),
                      ),
                      TextButton(
                        onPressed: () => setState(() => _unread++),
                        child: const Text('+1 unread'),
                      ),
                      TextButton(
                        onPressed: () => context.pop(),
                        child: const Text('Back'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
