import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Regression tests for in-place scaffold updates (#84, #144). They run on
/// the Material path, which is what the host machine resolves to.
void main() {
  testWidgets('app bar actions added and removed within the page show up', (
    tester,
  ) async {
    var showAction = false;
    late StateSetter setOuterState;
    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            setOuterState = setState;
            return AdaptiveScaffold(
              appBar: AdaptiveAppBar(
                title: 'Page',
                actions: showAction
                    ? [
                        AdaptiveAppBarAction(
                          icon: Icons.add,
                          label: 'Add',
                          onPressed: () {},
                        ),
                      ]
                    : null,
              ),
              body: const SizedBox(),
            );
          },
        ),
      ),
    );
    expect(find.byIcon(Icons.add), findsNothing);

    setOuterState(() => showAction = true);
    await tester.pump();
    expect(find.byIcon(Icons.add), findsOneWidget);

    setOuterState(() => showAction = false);
    await tester.pump();
    expect(find.byIcon(Icons.add), findsNothing);
  });

  testWidgets('extendBody reaches the Material scaffold', (tester) async {
    Widget build({required bool extendBody}) => MaterialApp(
      home: AdaptiveScaffold(
        extendBody: extendBody,
        body: const SizedBox.expand(),
        bottomNavigationBar: AdaptiveBottomNavigationBar(
          selectedIndex: 0,
          onTap: (_) {},
          items: const [
            AdaptiveNavigationDestination(icon: Icons.home, label: 'Home'),
            AdaptiveNavigationDestination(icon: Icons.info, label: 'Info'),
          ],
          bottomNavigationBar: const SizedBox(height: 80),
        ),
      ),
    );

    await tester.pumpWidget(build(extendBody: false));
    final screen = tester.getSize(find.byType(AdaptiveScaffold));
    expect(
      tester.getSize(find.byType(SizedBox).first).height,
      screen.height - 80,
    );

    await tester.pumpWidget(build(extendBody: true));
    expect(tester.getSize(find.byType(SizedBox).first).height, screen.height);
  });

  testWidgets('backgroundColor reaches the Material scaffold', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: AdaptiveScaffold(
          backgroundColor: Color(0xFF123456),
          body: SizedBox(),
        ),
      ),
    );
    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).last);
    expect(scaffold.backgroundColor, const Color(0xFF123456));
  });

  testWidgets('popup menu icon button applies iconSize', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AdaptivePopupMenuButton.icon<String>(
            icon: Icons.more_vert,
            iconSize: 31,
            items: [AdaptivePopupMenuItem<String>(label: 'One', value: 'one')],
            onSelected: (_, __) {},
          ),
        ),
      ),
    );
    final icon = tester.widget<Icon>(find.byIcon(Icons.more_vert));
    expect(icon.size, 31);
  });

  testWidgets('an opaque dark backgroundColor requests light status icons', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: AdaptiveScaffold(backgroundColor: Colors.black, body: SizedBox()),
      ),
    );
    final region = tester.widget<AnnotatedRegion<SystemUiOverlayStyle>>(
      find.byType(AnnotatedRegion<SystemUiOverlayStyle>).first,
    );
    expect(region.value.statusBarIconBrightness, Brightness.light);

    await tester.pumpWidget(
      const MaterialApp(home: AdaptiveScaffold(body: SizedBox())),
    );
    expect(find.byType(AnnotatedRegion<SystemUiOverlayStyle>), findsNothing);
  });
}
