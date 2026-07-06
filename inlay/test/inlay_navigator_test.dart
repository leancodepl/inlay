import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inlay/inlay.dart';
import 'package:inlay/src/navigator/inlay_navigator.g.dart';

class _TestRoute extends FlutterRouteBase {
  const _TestRoute({this.fingerprint});

  final String? fingerprint;

  @override
  String get routeId => 'testRoute';

  @override
  Object? get params => ['a', 1];

  @override
  String? get schemaFingerprint => fingerprint;
}

class _TestDialogRoute extends FlutterDialogRouteBase {
  const _TestDialogRoute();

  @override
  String get routeId => 'testDialog';

  @override
  Object? get params => null;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('decodeInitialRoute', () {
    test('route id only', () {
      final settings = InlayNavigator.decodeInitialRoute('counter');

      expect(settings.routeId, 'counter');
      expect(settings.params, isNull);
    });

    test('query params are split and percent-decoded', () {
      final settings = InlayNavigator.decodeInitialRoute(
        'greeting?name=Marcin&style=casual',
      );

      expect(settings.routeId, 'greeting');
      expect(settings.params, {'name': 'Marcin', 'style': 'casual'});
    });

    test('values containing & = / and unicode survive the round trip', () {
      // Mirrors the fixture in the Android InlayNavigatorCodecTest so the
      // two platforms stay in sync on the wire format.
      const value = 'a&b=c d/ż';
      final encoded = Uri.encodeComponent(value);
      final settings = InlayNavigator.decodeInitialRoute('page?q=$encoded');

      expect(settings.params, {'q': value});
    });

    test('malformed pairs are skipped', () {
      final settings = InlayNavigator.decodeInitialRoute(
        'page?flag&=orphan&ok=1',
      );

      expect(settings.params, {'ok': '1'});
    });
  });

  group('route base classes', () {
    test('FlutterRouteBase.toPageSettings carries the schema fingerprint', () {
      final settings = const _TestRoute(fingerprint: 'fp123').toPageSettings();

      expect(settings.routeId, 'testRoute');
      expect(settings.params, ['a', 1]);
      expect(settings.schemaFingerprint, 'fp123');
    });

    test('fingerprint defaults to null (check disabled downstream)', () {
      expect(const _TestRoute().toPageSettings().schemaFingerprint, isNull);
    });

    test('route types map to the correct InlayRouteType', () {
      expect(const _TestRoute().type, InlayRouteType.flutter);
      expect(const _TestDialogRoute().type, InlayRouteType.flutterDialog);
      expect(
        NativeRouteWrapper(PageSettings(routeId: 'n')).type,
        InlayRouteType.native,
      );
    });

    test('NativeRouteWrapper passes its PageSettings through untouched', () {
      final page = PageSettings(routeId: 'n', params: [1]);

      expect(NativeRouteWrapper(page).toPageSettings(), same(page));
    });
  });

  group('fetchInitialRoute', () {
    const channelName =
        'dev.flutter.pigeon.inlay.InlayNavigatorHostApi.getInitialRouteData';

    void mockHostReply(List<Object?> reply) {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockDecodedMessageHandler<Object?>(
            const BasicMessageChannel<Object?>(
              channelName,
              InlayNavigatorHostApi.pigeonChannelCodec,
            ),
            (message) async => reply,
          );
    }

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockDecodedMessageHandler<Object?>(
            const BasicMessageChannel<Object?>(
              channelName,
              InlayNavigatorHostApi.pigeonChannelCodec,
            ),
            null,
          );
    });

    test('decodes the PageSettings the host stored for this engine', () async {
      mockHostReply([PageSettings(routeId: 'testRoute')]);

      final route = await InlayNavigator.fetchInitialRoute(
        (settings) =>
            settings?.routeId == 'testRoute' ? const _TestRoute() : null,
      );

      expect(route, isA<_TestRoute>());
    });

    test(
      'returns null when the host has no route data (prewarm engine)',
      () async {
        mockHostReply([null]);

        final route = await InlayNavigator.fetchInitialRoute(
          (settings) => settings == null ? null : const _TestRoute(),
        );

        expect(route, isNull);
      },
    );

    test('swallows ordinary decoder errors and returns null', () async {
      mockHostReply([PageSettings(routeId: 'testRoute')]);

      final route = await InlayNavigator.fetchInitialRoute<_TestRoute>(
        (settings) => throw StateError('bad decode'),
      );

      expect(route, isNull);
    });

    test(
      'rethrows InlaySchemaMismatchException (drift must fail loudly)',
      () async {
        mockHostReply([PageSettings(routeId: 'testRoute')]);

        await expectLater(
          InlayNavigator.fetchInitialRoute<_TestRoute>(
            (settings) => throw InlaySchemaMismatchException('drift'),
          ),
          throwsA(isA<InlaySchemaMismatchException>()),
        );
      },
    );

    test('swallows platform errors and returns null', () async {
      mockHostReply(['SOME_CODE', 'boom', null]);

      final route = await InlayNavigator.fetchInitialRoute(
        (settings) => const _TestRoute(),
      );

      expect(route, isNull);
    });
  });
}
