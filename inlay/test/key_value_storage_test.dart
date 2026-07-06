import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inlay/inlay.dart';
import 'package:inlay/src/storage/key_value_storage.g.dart';

/// Tests the real [KeyValueStorage] wrapper over mocked Pigeon channels -
/// the in-memory map below plays the role of the platform-side store.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final platformStore = <String, String>{};

  BasicMessageChannel<Object?> channel(String method) =>
      BasicMessageChannel<Object?>(
        'dev.flutter.pigeon.inlay.KeyValueStorageHostApi.$method',
        KeyValueStorageHostApi.pigeonChannelCodec,
      );

  void mockHostMethod(
    String method,
    Object? Function(List<Object?> args) handler,
  ) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockDecodedMessageHandler<Object?>(channel(method), (
          message,
        ) async {
          return <Object?>[handler((message ?? const []) as List<Object?>)];
        });
  }

  setUp(() {
    platformStore.clear();
    mockHostMethod('put', (args) {
      final entry = args.first! as StorageEntry;
      platformStore[entry.key] = entry.value;
      return null;
    });
    mockHostMethod('get', (args) {
      final key = args.first! as String;
      final value = platformStore[key];
      return value == null ? null : StorageEntry(key: key, value: value);
    });
    mockHostMethod('getAll', (args) {
      return [
        for (final e in platformStore.entries)
          StorageEntry(key: e.key, value: e.value),
      ];
    });
    mockHostMethod('remove', (args) {
      return platformStore.remove(args.first! as String) != null;
    });
  });

  group('typed accessors', () {
    test('putBool/getBool round trip through string encoding', () async {
      await KeyValueStorage.instance.putBool('flag', value: true);

      expect(platformStore['flag'], 'true');
      expect(await KeyValueStorage.instance.getBool('flag'), isTrue);
    });

    test(
      'getBool treats anything but "true" as false, missing as null',
      () async {
        platformStore['flag'] = 'nonsense';

        expect(await KeyValueStorage.instance.getBool('flag'), isFalse);
        expect(await KeyValueStorage.instance.getBool('missing'), isNull);
      },
    );

    test('putJson/getJson round trip', () async {
      await KeyValueStorage.instance.putJson('prefs', {
        'sound': 'Chime',
        'volume': 3,
      });

      expect(await KeyValueStorage.instance.getJson('prefs'), {
        'sound': 'Chime',
        'volume': 3,
      });
    });

    test('getJson returns null for invalid JSON instead of throwing', () async {
      platformStore['prefs'] = '{not json';

      expect(await KeyValueStorage.instance.getJson('prefs'), isNull);
    });
  });

  group('change stream', () {
    test('onStorageChanged pushes entries to listeners', () async {
      final events = <List<StorageEntry>>[];
      final sub = KeyValueStorage.instance.stream.listen(events.add);

      KeyValueStorage.instance.onStorageChanged(
        StorageChangeEvent(
          entries: [StorageEntry(key: 'k', value: 'v')],
        ),
      );
      await Future<void>.delayed(Duration.zero);

      expect(events, hasLength(1));
      expect(events.single.single.key, 'k');
      await sub.cancel();
    });

    test('resume emits a full sync when the platform store has data', () async {
      platformStore['a'] = '1';
      final events = <List<StorageEntry>>[];
      final sub = KeyValueStorage.instance.stream.listen(events.add);

      KeyValueStorage.instance.didChangeAppLifecycleState(
        AppLifecycleState.resumed,
      );
      await Future<void>.delayed(Duration.zero);

      expect(events, hasLength(1));
      expect(events.single.single.key, 'a');
      await sub.cancel();
    });

    test('resume with an empty platform store emits nothing', () async {
      final events = <List<StorageEntry>>[];
      final sub = KeyValueStorage.instance.stream.listen(events.add);

      KeyValueStorage.instance.didChangeAppLifecycleState(
        AppLifecycleState.resumed,
      );
      await Future<void>.delayed(Duration.zero);

      expect(events, isEmpty);
      await sub.cancel();
    });

    test('non-resume lifecycle changes do not trigger a sync', () async {
      platformStore['a'] = '1';
      final events = <List<StorageEntry>>[];
      final sub = KeyValueStorage.instance.stream.listen(events.add);

      KeyValueStorage.instance.didChangeAppLifecycleState(
        AppLifecycleState.paused,
      );
      await Future<void>.delayed(Duration.zero);

      expect(events, isEmpty);
      await sub.cancel();
    });
  });
}
