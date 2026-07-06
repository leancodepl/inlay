import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inlay/inlay.dart';
import 'package:inlay/testing.dart';

void main() {
  late FakeInlayNavigator navigator;
  late BuildContext childContext;

  setUp(() {
    navigator = FakeInlayNavigator();
    InlayNavigator.instance = navigator;
  });

  Future<void> pumpObserver(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: InlayNativePopGestureObserver(
          child: Builder(
            builder: (context) {
              childContext = context;
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('enables the native gesture at root on iOS', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

    await pumpObserver(tester);

    expect(navigator.nativePopGestureEnabled, isTrue);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('disables the gesture while Flutter can handle pop', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    await pumpObserver(tester);

    const NavigationNotification(canHandlePop: true).dispatch(childContext);
    await tester.pump();

    expect(navigator.nativePopGestureEnabled, isFalse);

    const NavigationNotification(canHandlePop: false).dispatch(childContext);
    await tester.pump();

    expect(navigator.nativePopGestureEnabled, isTrue);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('does nothing on Android (gesture is iOS-only)', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;

    await pumpObserver(tester);
    const NavigationNotification(canHandlePop: true).dispatch(childContext);
    await tester.pump();

    expect(navigator.nativePopGestureEnabled, isNull);
    debugDefaultTargetPlatformOverride = null;
  });
}
