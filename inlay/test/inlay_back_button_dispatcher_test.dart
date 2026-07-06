import 'package:flutter_test/flutter_test.dart';
import 'package:inlay/inlay.dart';
import 'package:inlay/testing.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeInlayNavigator navigator;

  setUp(() {
    navigator = FakeInlayNavigator();
    InlayNavigator.instance = navigator;
  });

  test('closes the native container when no route handles back', () async {
    final dispatcher = InlayBackButtonDispatcher();

    final handled = await dispatcher.didPopRoute();

    expect(handled, isTrue);
    expect(navigator.popCount, 1);
  });

  test('leaves the container alone when a callback handles back', () async {
    final dispatcher = InlayBackButtonDispatcher()
      ..addCallback(() async => true);

    final handled = await dispatcher.didPopRoute();

    expect(handled, isTrue);
    expect(navigator.popCount, 0);
  });

  test('falls through to the container when callbacks decline', () async {
    final dispatcher = InlayBackButtonDispatcher()
      ..addCallback(() async => false);

    final handled = await dispatcher.didPopRoute();

    expect(handled, isTrue);
    expect(navigator.popCount, 1);
  });
}
