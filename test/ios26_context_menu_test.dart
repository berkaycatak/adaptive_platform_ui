import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final platformViewCalls = <String>[];

  setUp(() {
    platformViewCalls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform_views, (call) async {
          if (call.method == 'acceptGesture' ||
              call.method == 'rejectGesture') {
            platformViewCalls.add(call.method);
          }
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform_views, null);
  });

  Future<void> pumpMenu(WidgetTester tester, Widget child) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: SizedBox(
            width: 200,
            height: 100,
            child: IOS26ContextMenu(
              actions: [
                AdaptiveContextMenuAction(title: 'Copy', onPressed: () {}),
              ],
              child: child,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.byType(UiKitView), findsOneWidget);
  }

  testWidgets('a tap goes to the child and the native view lets it go', (
    tester,
  ) async {
    var taps = 0;
    await pumpMenu(
      tester,
      GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => taps++,
        child: const SizedBox.expand(),
      ),
    );

    await tester.tap(find.byType(IOS26ContextMenu));
    await tester.pump();

    expect(taps, 1);
    expect(platformViewCalls, ['rejectGesture']);
  });

  testWidgets('a double tap above the menu still wins', (tester) async {
    var taps = 0;
    var doubleTaps = 0;
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: GestureDetector(
            onDoubleTap: () => doubleTaps++,
            child: SizedBox(
              width: 200,
              height: 100,
              child: IOS26ContextMenu(
                actions: [
                  AdaptiveContextMenuAction(title: 'Copy', onPressed: () {}),
                ],
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => taps++,
                  child: const SizedBox.expand(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final center = tester.getCenter(find.byType(IOS26ContextMenu));
    await tester.tapAt(center);
    await tester.pump(kDoubleTapMinTime);
    await tester.tapAt(center);
    await tester.pumpAndSettle();

    expect(doubleTaps, 1);
    expect(taps, 0);
  });

  testWidgets('a long press goes to the native view', (tester) async {
    var taps = 0;
    await pumpMenu(
      tester,
      GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => taps++,
        child: const SizedBox.expand(),
      ),
    );

    await tester.longPress(find.byType(IOS26ContextMenu));
    await tester.pump();

    expect(taps, 0);
    expect(platformViewCalls, ['acceptGesture']);
  });
}
