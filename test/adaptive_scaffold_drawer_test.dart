import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';

void main() {
  group('AdaptiveScaffold drawer support', () {
    testWidgets('renders drawer when provided', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AdaptiveScaffold(
            drawer: const Drawer(child: Text('Drawer Content')),
            body: const Text('Body'),
          ),
        ),
      );

      // Drawer should not be visible initially
      expect(find.text('Drawer Content'), findsNothing);

      // Open drawer via ScaffoldState
      final scaffoldState = tester.firstState<ScaffoldState>(
        find.byType(Scaffold),
      );
      scaffoldState.openDrawer();
      await tester.pumpAndSettle();

      expect(find.text('Drawer Content'), findsOneWidget);
    });

    testWidgets('renders endDrawer when provided', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AdaptiveScaffold(
            endDrawer: const Drawer(child: Text('End Drawer Content')),
            body: const Text('Body'),
          ),
        ),
      );

      expect(find.text('End Drawer Content'), findsNothing);

      final scaffoldState = tester.firstState<ScaffoldState>(
        find.byType(Scaffold),
      );
      scaffoldState.openEndDrawer();
      await tester.pumpAndSettle();

      expect(find.text('End Drawer Content'), findsOneWidget);
    });

    testWidgets('no extra Scaffold wrapper when no drawer provided', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(home: AdaptiveScaffold(body: const Text('Body'))),
      );

      // Should have exactly one Scaffold (the Android path Scaffold)
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('onDrawerChanged callback fires', (WidgetTester tester) async {
      bool? drawerOpened;

      await tester.pumpWidget(
        MaterialApp(
          home: AdaptiveScaffold(
            drawer: const Drawer(child: Text('Drawer Content')),
            onDrawerChanged: (isOpened) {
              drawerOpened = isOpened;
            },
            body: const Text('Body'),
          ),
        ),
      );

      final scaffoldState = tester.firstState<ScaffoldState>(
        find.byType(Scaffold),
      );
      scaffoldState.openDrawer();
      await tester.pumpAndSettle();

      expect(drawerOpened, isTrue);
    });

    testWidgets('constructor accepts all drawer parameters', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AdaptiveScaffold(
            drawer: const Drawer(child: Text('Drawer')),
            endDrawer: const Drawer(child: Text('End Drawer')),
            drawerScrimColor: Colors.red,
            onDrawerChanged: (_) {},
            onEndDrawerChanged: (_) {},
            drawerEnableOpenDragGesture: false,
            endDrawerEnableOpenDragGesture: false,
            body: const Text('Body'),
          ),
        ),
      );

      expect(find.text('Body'), findsOneWidget);
    });

    testWidgets('drawer works with appBar', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AdaptiveScaffold(
            appBar: AdaptiveAppBar(title: 'Test'),
            drawer: const Drawer(child: Text('Drawer Content')),
            body: const Text('Body'),
          ),
        ),
      );

      final scaffoldState = tester.firstState<ScaffoldState>(
        find.byType(Scaffold),
      );
      scaffoldState.openDrawer();
      await tester.pumpAndSettle();

      expect(find.text('Drawer Content'), findsOneWidget);
    });
  });
}
