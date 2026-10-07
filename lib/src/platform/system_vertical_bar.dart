import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Where the system places its vertical bar for this window, as a physical
/// side (`UITraitCollection.verticalBarEdge`, iOS 27.1).
enum SystemVerticalBarEdge {
  /// No reading: not iOS, iOS < 27.1, or the first reading has not arrived.
  unknown,

  /// The system keeps horizontal bars here.
  none,

  /// The system puts its vertical bar on the left edge.
  left,

  /// The system puts its vertical bar on the right edge.
  right;

  /// The edge for a value sent over the channel; anything unrecognised
  /// (including the native "unsupported") is [unknown].
  static SystemVerticalBarEdge fromWire(Object? value) => switch (value) {
    'none' => none,
    'left' => left,
    'right' => right,
    _ => unknown,
  };
}

/// The system's vertical bar edge, streamed from the native side.
///
/// One shared subscription: an [EventChannel] supports a single native
/// listener, and both the toolbar host and every scaffold without a host need
/// the value.
abstract final class SystemVerticalBar {
  static const EventChannel _channel = EventChannel(
    'adaptive_platform_ui/vertical_bar_edge',
  );
  static final ValueNotifier<SystemVerticalBarEdge> _edge = ValueNotifier(
    SystemVerticalBarEdge.unknown,
  );
  static StreamSubscription<Object?>? _sub;

  /// The current edge. Starts listening on first use, so only read it where
  /// the channel exists (iOS 26+); it stays [SystemVerticalBarEdge.unknown]
  /// until the first reading arrives.
  static ValueListenable<SystemVerticalBarEdge> get edge {
    _sub ??= _channel.receiveBroadcastStream().listen(
      (value) => _edge.value = SystemVerticalBarEdge.fromWire(value),
      onError: (Object _) {},
    );
    return _edge;
  }
}
