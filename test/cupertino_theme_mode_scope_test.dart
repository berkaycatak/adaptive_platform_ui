import 'package:adaptive_platform_ui/src/widgets/adaptive_app.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_test/flutter_test.dart';

void main() {
  // How AdaptiveApp builds the iOS app: the light theme as `theme:`, the
  // chosen mode applied by the scope in `builder:`.
  Widget app(ThemeMode mode) => CupertinoApp(
    theme: const CupertinoThemeData(brightness: Brightness.light),
    builder: (context, child) => CupertinoThemeModeScope(
      themeMode: mode,
      lightTheme: const CupertinoThemeData(brightness: Brightness.light),
      darkTheme: const CupertinoThemeData(brightness: Brightness.dark),
      child: child!,
    ),
    home: const CupertinoPageScaffold(child: Center(child: Text('plain'))),
  );

  Color plainTextColour(WidgetTester tester) =>
      tester.widget<RichText>(find.byType(RichText)).text.style!.color!;

  testWidgets('plain text turns light in dark mode', (tester) async {
    await tester.pumpWidget(app(ThemeMode.dark));
    expect(plainTextColour(tester).computeLuminance(), greaterThan(0.5));
  });

  testWidgets('plain text stays dark in light mode', (tester) async {
    await tester.pumpWidget(app(ThemeMode.light));
    expect(plainTextColour(tester).computeLuminance(), lessThan(0.5));
  });

  testWidgets('dark mode reaches MediaQuery', (tester) async {
    late Brightness seen;
    await tester.pumpWidget(
      CupertinoApp(
        builder: (context, child) => CupertinoThemeModeScope(
          themeMode: ThemeMode.dark,
          lightTheme: const CupertinoThemeData(brightness: Brightness.light),
          darkTheme: const CupertinoThemeData(brightness: Brightness.dark),
          child: child!,
        ),
        home: Builder(
          builder: (context) {
            seen = MediaQuery.platformBrightnessOf(context);
            return const SizedBox();
          },
        ),
      ),
    );
    expect(seen, Brightness.dark);
  });
}
