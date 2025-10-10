import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';

/// Native iOS 26 segmented control implementation using platform views
class iOS26SegmentedControl<T extends Object> extends StatefulWidget {
  const iOS26SegmentedControl({
    super.key,
    required this.children,
    required this.onValueChanged,
    this.groupValue,
  });

  final Map<T, Widget> children;
  final T? groupValue;
  final ValueChanged<T> onValueChanged;

  @override
  State<iOS26SegmentedControl<T>> createState() => _iOS26SegmentedControlState<T>();
}

class _iOS26SegmentedControlState<T extends Object> extends State<iOS26SegmentedControl<T>> {
  static int _nextId = 0;
  late final int _id;
  late final MethodChannel _channel;
  late final List<T> _keys;

  @override
  void initState() {
    super.initState();
    _id = _nextId++;
    _keys = widget.children.keys.toList();
    _channel = MethodChannel('adaptive_platform_ui/ios26_segmented_control_$_id');
    _channel.setMethodCallHandler(_handleMethod);
  }

  @override
  void dispose() {
    _channel.setMethodCallHandler(null);
    super.dispose();
  }

  Future<dynamic> _handleMethod(MethodCall call) async {
    if (call.method == 'valueChanged') {
      final index = call.arguments['index'] as int;
      if (index >= 0 && index < _keys.length) {
        widget.onValueChanged(_keys[index]);
      }
    }
  }

  @override
  void didUpdateWidget(iOS26SegmentedControl<T> oldWidget) {
    super.didUpdateWidget(oldWidget);

    final newIndex = widget.groupValue != null
        ? _keys.indexOf(widget.groupValue as T)
        : -1;

    _channel.invokeMethod('setSelectedIndex', {'index': newIndex});
  }

  Map<String, dynamic> _buildCreationParams() {
    final segments = widget.children.entries.map((e) {
      final child = e.value;
      if (child is Text) {
        return {'type': 'text', 'value': child.data ?? ''};
      }
      return {'type': 'text', 'value': 'Segment'};
    }).toList();

    final selectedIndex = widget.groupValue != null
        ? _keys.indexOf(widget.groupValue as T)
        : -1;

    return {
      'id': _id,
      'segments': segments,
      'selectedIndex': selectedIndex,
      'isDark': MediaQuery.platformBrightnessOf(context) == Brightness.dark,
    };
  }

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb && Platform.isIOS) {
      return SizedBox(
        height: 32,
        child: UiKitView(
          viewType: 'adaptive_platform_ui/ios26_segmented_control',
          creationParams: _buildCreationParams(),
          creationParamsCodec: const StandardMessageCodec(),
          gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
            Factory<TapGestureRecognizer>(() => TapGestureRecognizer()),
            Factory<HorizontalDragGestureRecognizer>(() => HorizontalDragGestureRecognizer()),
            Factory<PanGestureRecognizer>(() => PanGestureRecognizer()),
          },
        ),
      );
    }

    return CupertinoSegmentedControl<T>(
      children: widget.children,
      groupValue: widget.groupValue,
      onValueChanged: widget.onValueChanged,
    );
  }
}
