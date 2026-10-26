import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// A picture and a count on toolbar actions: the profile avatar and the bell
/// that apps keep at the top corner.
class ToolbarPictureDemoPage extends StatefulWidget {
  const ToolbarPictureDemoPage({super.key});

  @override
  State<ToolbarPictureDemoPage> createState() => _ToolbarPictureDemoPageState();
}

class _ToolbarPictureDemoPageState extends State<ToolbarPictureDemoPage> {
  Uint8List? _photo;
  bool _showPhoto = true;
  int _unread = 3;

  @override
  void initState() {
    super.initState();
    _drawPhoto().then((bytes) {
      if (mounted) setState(() => _photo = bytes);
    });
  }

  /// A stand-in for a profile photo: a gradient with initials, as PNG bytes,
  /// the way an app would hand over a decoded or downloaded picture.
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
    return AdaptiveScaffold(
      appBar: AdaptiveAppBar(
        leading: PlatformInfo.isIOS26OrHigher() ? _popButton(context) : null,
        title: 'Toolbar Picture',
        actions: [
          AdaptiveAppBarAction(
            iosSymbol: 'bell',
            icon: Icons.notifications_outlined,
            label: 'Notifications',
            badgeCount: _unread,
            onPressed: () => setState(() => _unread = 0),
          ),
          AdaptiveAppBarAction(
            // Until the picture is ready, or when there is none.
            iosSymbol: 'person.crop.circle',
            icon: Icons.person_outline,
            iconImage: _showPhoto ? _photo : null,
            label: 'My profile',
            onPressed: () {},
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(16, PlatformInfo.isIOS ? 130 : 16, 16, 16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Picture and count',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'iconImage shows a picture in place of the symbol, round '
                    'and untinted. badgeCount puts a count on the item. On '
                    'iOS 26 both are drawn by the native toolbar.',
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Show the picture'),
                    value: _showPhoto,
                    onChanged: (value) => setState(() => _showPhoto = value),
                  ),
                  Text('Unread: $_unread'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      ElevatedButton(
                        onPressed: () => setState(() => _unread++),
                        child: const Text('New notification'),
                      ),
                      OutlinedButton(
                        onPressed: () => setState(() => _unread = 0),
                        child: const Text('Mark all as read'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _popButton(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 8),
      width: 40,
      height: 40,
      child: AdaptiveButton.sfSymbol(
        onPressed: () => context.pop(),
        sfSymbol: SFSymbol('chevron.backward'),
      ),
    );
  }
}
