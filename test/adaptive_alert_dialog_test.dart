import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AdaptiveAlertDialogInput.show', () {
    testWidgets('show returns the value passed to Navigator.pop', (tester) async {
      late Future<bool?> result;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                result = AdaptiveAlertDialog.showWithResult<bool>(
                  context: context,
                  title: 'Confirm',
                  actionsBuilder: (context) => [
                    AlertAction(
                      title: 'Cancel',
                      style: AlertActionStyle.cancel,
                      onPressed: () => Navigator.of(context).pop(false),
                    ),
                    AlertAction(
                      title: 'OK',
                      style: AlertActionStyle.defaultAction,
                      onPressed: () => Navigator.of(context).pop(true),
                    ),
                  ],
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(await result, isTrue);
    });
  });
}
