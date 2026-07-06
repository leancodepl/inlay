import 'package:example_module/src/generated/routes.g.dart';
import 'package:example_module/src/screens/greeting_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inlay/inlay.dart';
import 'package:inlay/testing.dart';
import 'package:package_info_plus/package_info_plus.dart';

void main() {
  late FakeInlayNavigator navigator;

  setUp(() {
    navigator = FakeInlayNavigator();
    InlayNavigator.instance = navigator;
    PackageInfo.setMockInitialValues(
      appName: 'Test Host',
      packageName: 'co.test.host',
      version: '9.9.9',
      buildNumber: '1',
      buildSignature: '',
    );
  });

  Future<void> pumpGreeting(WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: GreetingScreen(name: 'Test', style: GreetingStyle.casual),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('renders host app info fetched via package_info_plus', (
    tester,
  ) async {
    await pumpGreeting(tester);

    expect(
      find.text('Host app: Test Host 9.9.9+1 (co.test.host)'),
      findsOneWidget,
    );
  });

  testWidgets('pushes Counter on a new engine through InlayNavigator', (
    tester,
  ) async {
    await pumpGreeting(tester);

    await tester.tap(find.text('Open Counter (new engine/container)'));

    expect(navigator.pushedRoutes.single, isA<CounterPage>());
  });

  testWidgets('opens the native About screen with the real app version', (
    tester,
  ) async {
    await pumpGreeting(tester);

    await tester.tap(find.text('Open native About screen'));

    final page = navigator.pushedPages.single;
    expect(page.routeId, NativeAboutPage.routeId);
    expect(
      NativeAboutPage.decode(
        (page.params! as List<Object?>).cast<Object?>(),
      ).appVersion,
      '9.9.9',
    );
  });
}
