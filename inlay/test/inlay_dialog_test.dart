import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inlay/inlay.dart';
import 'package:inlay/testing.dart';

/// The dialog/bottom-sheet pages run inside a transparent native container;
/// dismissing the Flutter content must close that container via
/// `InlayNavigator.instance.pop()`.
void main() {
  late FakeInlayNavigator navigator;

  setUp(() {
    navigator = FakeInlayNavigator();
    InlayNavigator.instance = navigator;
  });

  Widget host(Page<void> page) => MaterialApp(
    home: Navigator(pages: [page], onDidRemovePage: (_) {}),
  );

  group('InlayDialogPage', () {
    testWidgets('shows the dialog content over a transparent page', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          InlayDialogPage<void>(
            builder: (_) => const AlertDialog(title: Text('Confirm?')),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Confirm?'), findsOneWidget);
      expect(navigator.popCount, 0);
    });

    testWidgets('dismissing the dialog closes the native container', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          InlayDialogPage<void>(
            builder: (_) => const AlertDialog(title: Text('Confirm?')),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap the barrier to dismiss.
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();

      expect(find.text('Confirm?'), findsNothing);
      expect(navigator.popCount, 1);
    });

    testWidgets('forwards the popped result through encodeResult', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          InlayDialogPage<bool>(
            encodeResult: (value) => value,
            builder: (dialogContext) => AlertDialog(
              title: const Text('Confirm?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  child: const Text('Confirm'),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();

      expect(navigator.poppedResults, [true]);
      expect(navigator.popCount, 1);
    });

    testWidgets('barrier dismiss forwards no result', (tester) async {
      await tester.pumpWidget(
        host(
          InlayDialogPage<bool>(
            encodeResult: (value) => value,
            builder: (_) => const AlertDialog(title: Text('Confirm?')),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();

      expect(navigator.popCount, 1);
      expect(navigator.poppedResults.single, isNull);
    });

    testWidgets('barrierDismissible: false keeps the dialog up', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          InlayDialogPage<void>(
            barrierDismissible: false,
            builder: (_) => const AlertDialog(title: Text('Confirm?')),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();

      expect(find.text('Confirm?'), findsOneWidget);
      expect(navigator.popCount, 0);
    });
  });

  group('InlayBottomSheetPage', () {
    testWidgets('shows the sheet and closes the container on dismiss', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          InlayBottomSheetPage<void>(
            builder: (_) =>
                const SizedBox(height: 200, child: Text('Pick a theme')),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Pick a theme'), findsOneWidget);

      // Tap the barrier above the sheet to dismiss.
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();

      expect(find.text('Pick a theme'), findsNothing);
      expect(navigator.popCount, 1);
    });
  });
}
