import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:adaptive_platform_ui/src/widgets/ios26/ios26_glass_capsule.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const _items = [
  GlassCapsuleItem(symbol: 'house', label: 'Home'),
  GlassCapsuleItem(symbol: 'play.rectangle', label: 'Reels'),
  GlassCapsuleItem(symbol: 'paperplane', label: 'Direct'),
  GlassCapsuleItem(symbol: 'magnifyingglass', label: 'Explore'),
  GlassCapsuleItem(symbol: 'person.crop.circle', label: 'Profile'),
];

const _destinations = [
  AdaptiveNavigationDestination(icon: 'house', label: 'Home'),
  AdaptiveNavigationDestination(icon: 'bubble.left', label: 'Chat'),
  AdaptiveNavigationDestination(icon: 'clock', label: 'History'),
];

/// The compact capsule, as the iPhone Duo column lays it out: 44 a tab.
const _compact = Size(52, 5 * 44 + 2 * IOS26GlassCapsule.tabsInset);

/// What the native capsule reports when the lens is taken ([active]) or let go.
Future<void> _lensDrag(WidgetTester tester, {required bool active}) async {
  final id = _lastCreatedId;
  final data = const StandardMethodCodec().encodeMethodCall(
    MethodCall('onLensDrag', {'active': active}),
  );
  await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
    'adaptive_platform_ui/ios26_glass_capsule_$id',
    data,
    (_) {},
  );
}

/// The id of the last native view created, whose channel the native side
/// talks on.
int? _lastCreatedId;

/// Pumps [child], answering the platform views channel as the engine would.
Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  bool reduceMotion = false,
}) async {
  _lastCreatedId = null;
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    SystemChannels.platform_views,
    (call) async {
      if (call.method == 'create') {
        _lastCreatedId = (call.arguments as Map)['id'] as int;
      }
      return null;
    },
  );
  addTearDown(
    () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform_views,
      null,
    ),
  );
  await tester.pumpWidget(
    MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: reduceMotion),
        child: Center(child: child),
      ),
    ),
  );
  await tester.pump();
  expect(_lastCreatedId, isNotNull, reason: 'the native view was created');
}

Widget _capsule({bool expandOnLensDrag = true}) => SizedBox.fromSize(
  size: _compact,
  child: IOS26GlassCapsule(
    items: _items,
    selectedIndex: 0,
    inset: IOS26GlassCapsule.tabsInset,
    expandOnLensDrag: expandOnLensDrag,
    onTap: (_) {},
  ),
);

Size _viewSize(WidgetTester tester) => tester.getSize(find.byType(UiKitView));

void main() {
  group('IOS26GlassCapsule grows while its lens is held', () {
    final ios = TargetPlatformVariant.only(TargetPlatform.iOS);

    test('to the width of a labeled capsule, a little taller a tab', () {
      final expanded = IOS26GlassCapsule.lensExpandedSize(_compact, 5);
      expect(expanded.width, IOS26GlassCapsule.labeledWidth);
      expect(
        expanded.height,
        _compact.height + 5 * IOS26GlassCapsule.lensItemGrowth,
      );
      // Never narrower than it already is.
      expect(
        IOS26GlassCapsule.lensExpandedSize(const Size(90, 200), 3).width,
        90,
      );
    });

    testWidgets('tells the native view it may show the labels then', (
      tester,
    ) async {
      await _pump(tester, _capsule());

      final view = tester.widget<UiKitView>(find.byType(UiKitView));
      expect((view.creationParams as Map)['expandOnLensDrag'], isTrue);
    }, variant: ios);

    testWidgets('says nothing of it unless asked for', (tester) async {
      await _pump(tester, _capsule(expandOnLensDrag: false));

      final view = tester.widget<UiKitView>(find.byType(UiKitView));
      expect(
        (view.creationParams as Map).containsKey('expandOnLensDrag'),
        isFalse,
      );
    }, variant: ios);

    testWidgets('grows around its place, without moving what is beside it', (
      tester,
    ) async {
      await _pump(tester, _capsule());
      final place = tester.getCenter(find.byType(IOS26GlassCapsule));
      expect(_viewSize(tester), _compact);

      await _lensDrag(tester, active: true);
      await tester.pumpAndSettle();

      expect(
        _viewSize(tester),
        IOS26GlassCapsule.lensExpandedSize(_compact, _items.length),
      );
      expect(tester.getCenter(find.byType(UiKitView)), place);
      // Its slot in the column keeps the compact size.
      expect(tester.getSize(find.byType(IOS26GlassCapsule)), _compact);
    }, variant: ios);

    testWidgets('animates to the larger size, not in one jump', (tester) async {
      await _pump(tester, _capsule());

      await _lensDrag(tester, active: true);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));

      final size = _viewSize(tester);
      final expanded = IOS26GlassCapsule.lensExpandedSize(
        _compact,
        _items.length,
      );
      expect(size.width, greaterThan(_compact.width));
      expect(size.width, lessThan(expanded.width));
    }, variant: ios);

    testWidgets('goes back to its size when the lens is let go', (
      tester,
    ) async {
      await _pump(tester, _capsule());
      await _lensDrag(tester, active: true);
      await tester.pumpAndSettle();

      await _lensDrag(tester, active: false);
      await tester.pumpAndSettle();

      expect(_viewSize(tester), _compact);
    }, variant: ios);

    testWidgets('stays as it is when not asked to grow', (tester) async {
      await _pump(tester, _capsule(expandOnLensDrag: false));

      await _lensDrag(tester, active: true);
      await tester.pumpAndSettle();

      expect(_viewSize(tester), _compact);
    }, variant: ios);

    testWidgets('with Reduce Motion it changes size at once', (tester) async {
      await _pump(tester, _capsule(), reduceMotion: true);

      await _lensDrag(tester, active: true);
      await tester.pump();

      expect(
        _viewSize(tester),
        IOS26GlassCapsule.lensExpandedSize(_compact, _items.length),
      );
    }, variant: ios);
  });

  group('the iPhone Duo tab bars grow while the lens is held', () {
    testWidgets('AdaptiveTabCapsule passes expandOnLensDrag on', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: AdaptiveTabCapsule(
              destinations: _destinations,
              selectedIndex: 0,
              onDestinationSelected: (_) {},
              itemExtent: 44,
              expandOnLensDrag: true,
            ),
          ),
        ),
      );

      final capsule = tester.widget<IOS26GlassCapsule>(
        find.byType(IOS26GlassCapsule),
      );
      expect(capsule.expandOnLensDrag, isTrue);
    });

    testWidgets('AdaptiveTabCapsule leaves it off by default (the rail)', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: AdaptiveTabCapsule(
              destinations: _destinations,
              selectedIndex: 0,
              onDestinationSelected: (_) {},
            ),
          ),
        ),
      );

      final capsule = tester.widget<IOS26GlassCapsule>(
        find.byType(IOS26GlassCapsule),
      );
      expect(capsule.expandOnLensDrag, isFalse);
    });
  });
}
