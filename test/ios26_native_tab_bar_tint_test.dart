import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  final channels = <MethodChannel>[];
  final nativeCalls = <MethodCall>[];
  final creations = <Map<dynamic, dynamic>>[];

  setUp(() {
    nativeCalls.clear();
    creations.clear();
    messenger.setMockMethodCallHandler(SystemChannels.platform_views, (
      call,
    ) async {
      if (call.method == 'create') {
        final arguments = call.arguments as Map;
        final bytes = arguments['params'] as Uint8List;
        creations.add(
          const StandardMessageCodec().decodeMessage(
                ByteData.sublistView(bytes),
              )
              as Map,
        );
        final channel = MethodChannel(
          'adaptive_platform_ui/ios26_tab_bar_${arguments['id']}',
        );
        channels.add(channel);
        messenger.setMockMethodCallHandler(channel, (call) async {
          nativeCalls.add(call);
          if (call.method == 'getIntrinsicSize') {
            return <String, double>{'width': 320, 'height': 50};
          }
          return null;
        });
      }
      return null;
    });
  });

  tearDown(() {
    messenger.setMockMethodCallHandler(SystemChannels.platform_views, null);
    for (final channel in channels) {
      messenger.setMockMethodCallHandler(channel, null);
    }
    channels.clear();
  });

  Future<void> pumpBar(
    WidgetTester tester, {
    bool useNativeSystemTint = false,
    Color? tint,
    Color themeTint = const Color(0xFF112233),
    Brightness brightness = Brightness.light,
    int selectedIndex = 0,
  }) async {
    await tester.pumpWidget(
      CupertinoApp(
        theme: CupertinoThemeData(primaryColor: themeTint),
        home: MediaQuery(
          data: MediaQueryData(platformBrightness: brightness),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: IOS26NativeTabBar(
              useNativeSystemTint: useNativeSystemTint,
              tint: tint,
              destinations: const [
                AdaptiveNavigationDestination(icon: 'house', label: 'Home'),
                AdaptiveNavigationDestination(
                  icon: 'gearshape',
                  label: 'Settings',
                ),
              ],
              selectedIndex: selectedIndex,
              onTap: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  List<Object?> sentTints() => nativeCalls
      .where((call) => call.method == 'setStyle')
      .map((call) => (call.arguments as Map)['tint'])
      .where((tint) => tint != null)
      .toList();

  testWidgets(
    'system tint survives creation, initial sync, and theme changes',
    (tester) async {
      await pumpBar(
        tester,
        useNativeSystemTint: true,
        tint: const Color(0xFFFF0000),
      );

      expect(creations.single['tint'], 'systemBlue');
      expect(creations.single.containsKey('unselectedItemTint'), isFalse);
      expect(creations.single.containsKey('backgroundColor'), isFalse);
      expect(sentTints(), isNotEmpty);
      expect(sentTints(), everyElement('systemBlue'));

      nativeCalls.clear();
      await pumpBar(
        tester,
        useNativeSystemTint: true,
        tint: const Color(0xFF00FF00),
        themeTint: const Color(0xFF445566),
        brightness: Brightness.dark,
        selectedIndex: 1,
      );

      expect(creations, hasLength(1));
      expect(sentTints(), isEmpty);
      expect(
        nativeCalls
            .where((call) => call.method == 'setSelectedIndex')
            .last
            .arguments,
        {'index': 1},
      );
      expect(
        nativeCalls
            .where((call) => call.method == 'setBrightness')
            .last
            .arguments,
        {'isDark': true},
      );
    },
    variant: const TargetPlatformVariant({TargetPlatform.iOS}),
  );

  testWidgets(
    'switches between native, explicit, and theme tint on the same bar',
    (tester) async {
      const customTint = Color(0xFF0A95F0);
      const themeTint = Color(0xFF075293);
      await pumpBar(tester, tint: customTint);
      expect(creations.single['tint'], customTint.toARGB32());

      nativeCalls.clear();
      await pumpBar(tester, useNativeSystemTint: true, tint: customTint);
      expect(sentTints(), ['systemBlue']);

      nativeCalls.clear();
      await pumpBar(tester, tint: customTint);
      expect(sentTints(), [customTint.toARGB32()]);

      nativeCalls.clear();
      await pumpBar(tester, useNativeSystemTint: true);
      expect(sentTints(), ['systemBlue']);

      nativeCalls.clear();
      await pumpBar(tester, themeTint: themeTint);
      expect(sentTints(), [themeTint.toARGB32()]);
      expect(creations, hasLength(1));
    },
    variant: const TargetPlatformVariant({TargetPlatform.iOS}),
  );

  testWidgets('restores dynamic tint variants after turning system tint off', (
    tester,
  ) async {
    const tint = CupertinoDynamicColor.withBrightness(
      color: Color(0xFF075293),
      darkColor: Color(0xFF0A95F0),
    );
    await pumpBar(tester, tint: tint);
    final originalTint = creations.single['tint'] as Map;
    expect(originalTint['light'], tint.color.toARGB32());
    expect(originalTint['dark'], tint.darkColor.toARGB32());
    expect(originalTint, hasLength(8));

    await pumpBar(tester, tint: tint, useNativeSystemTint: true);
    nativeCalls.clear();
    await pumpBar(tester, tint: tint);

    expect(sentTints(), [originalTint]);
    expect(creations, hasLength(1));
  }, variant: const TargetPlatformVariant({TargetPlatform.iOS}));

  testWidgets('keeps the theme tint when the native option is omitted', (
    tester,
  ) async {
    const themeTint = Color(0xFF123456);
    await pumpBar(tester, themeTint: themeTint);

    expect(creations.single['tint'], themeTint.toARGB32());
    expect(sentTints(), isNotEmpty);
    expect(sentTints(), everyElement(themeTint.toARGB32()));
  }, variant: const TargetPlatformVariant({TargetPlatform.iOS}));
}
