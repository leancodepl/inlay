import 'package:inlay_gen/src/generators/dart/dart_routes_generator.dart';
import 'package:inlay_gen/src/generators/dart/dart_store_generator.dart';
import 'package:inlay_gen/src/generators/kotlin/kotlin_routes_generator.dart';
import 'package:inlay_gen/src/generators/kotlin/kotlin_store_generator.dart';
import 'package:inlay_gen/src/generators/swift/swift_routes_generator.dart';
import 'package:inlay_gen/src/generators/swift/swift_store_generator.dart';
import 'package:inlay_gen/src/parser/annotation_parser.dart';
import 'package:inlay_gen/src/parser/type_resolver.dart';
import 'package:inlay_gen/src/utils/naming.dart';
import 'package:test/test.dart';

const _routesSource = '''
import 'package:inlay/inlay.dart';

@InlayFlutterRoute()
class ContactDetailsPage {
  const ContactDetailsPage({required this.contactId, this.settings});

  final String contactId;
  final ContactSettings? settings;
}

@InlayFlutterRoute('sounds-notifications')
class SoundsNotificationsPage {
  const SoundsNotificationsPage({required this.contactId});

  final String contactId;
}

@InlayNativeRoute(name: 'edit-profile')
class NativeEditProfilePage {
  const NativeEditProfilePage({required this.contactId});

  final String contactId;
}

class ContactSettings {
  const ContactSettings({required this.notifications, this.theme});

  final bool notifications;
  final String? theme;
}

enum MediaType { image, video, audio }
''';

const _storesSource = '''
import 'package:inlay/inlay.dart';

@InlayStore(key: 'sounds_notifications')
class SoundsNotificationsStore {
  const SoundsNotificationsStore({
    @InlayStoreKey() required this.contactId,
    this.mute = false,
    this.showPreviews = true,
    this.sound = 'Default',
    this.behavior = NotificationBehavior.defaultBehavior,
  });

  final String contactId;
  final bool mute;
  final bool showPreviews;
  final String sound;
  final NotificationBehavior behavior;
}

@InlayStore()
class UserPreferencesStore {
  const UserPreferencesStore({
    this.darkMode = false,
    this.locale,
  });

  final bool darkMode;
  final String? locale;
}

enum NotificationBehavior { defaultBehavior, muted, mentionsOnly }
''';

const _nestedTypesSource = '''
import 'package:inlay/inlay.dart';

@InlayFlutterRoute()
class MediaViewerPage {
  const MediaViewerPage({
    required this.mediaId,
    required this.mediaType,
    this.tags,
    this.metadata,
  });

  final String mediaId;
  final MediaType mediaType;
  final List<String>? tags;
  final Map<String, String>? metadata;
}

@InlayFlutterRoute()
class DeepNestedPage {
  const DeepNestedPage({required this.items});

  final List<NestedItem> items;
}

class NestedItem {
  const NestedItem({required this.name, this.children});

  final String name;
  final List<NestedItem>? children;
}

enum MediaType { image, video, audio }
''';

const _enhancedEnumRoutesSource = '''
import 'package:inlay/inlay.dart';

@InlayFlutterRoute()
class EnhancedEnumPage {
  const EnhancedEnumPage({required this.channel});

  final DeliveryChannel channel;
}

enum DeliveryChannel {
  push('push', true),
  sms('sms', false);

  const DeliveryChannel(this.code, this.supportsPreview);

  final String code;
  final bool supportsPreview;

  bool get isFallback => !supportsPreview;
}
''';

const _storeKeyTypesSource = '''
import 'package:inlay/inlay.dart';

@InlayStore(key: 'thread_preferences')
class ThreadPreferencesStore {
  const ThreadPreferencesStore({
    @InlayStoreKey() required this.threadId,
    this.unreadCount = 0,
    this.behavior = NotificationBehavior.defaultBehavior,
  });

  final int threadId;
  final int unreadCount;
  final NotificationBehavior behavior;
}

@InlayStore(key: 'category_preferences')
class CategoryPreferencesStore {
  const CategoryPreferencesStore({
    @InlayStoreKey() required this.category,
    this.label = 'General',
  });

  final ConversationCategory category;
  final String label;
}

enum NotificationBehavior { defaultBehavior, muted }

enum ConversationCategory {
  direct('direct'),
  group('group');

  const ConversationCategory(this.code);

  final String code;
}
''';

const _dialogRoutesSource = '''
import 'package:inlay/inlay.dart';

@InlayFlutterDialog('/confirm-action/:action')
class ConfirmActionDialog {
  const ConfirmActionDialog({required this.action, this.message});

  final String action;
  final String? message;
}

@InlayFlutterDialog('/theme-picker/:userId')
class ThemePickerDialog {
  const ThemePickerDialog({required this.userId});

  final String userId;
}
''';

const _resultRoutesSource = '''
import 'package:inlay/inlay.dart';

@InlayFlutterRoute('/counter', result: int)
class CounterPage {
  const CounterPage({this.seed});

  final int? seed;
}

@InlayFlutterDialog('/confirm-action/:action', result: bool)
class ConfirmActionDialog {
  const ConfirmActionDialog({required this.action});

  final String action;
}
''';

const _invalidStoreMultipleKeysSource = '''
import 'package:inlay/inlay.dart';

@InlayStore(key: 'invalid_store')
class InvalidStore {
  const InvalidStore({
    @InlayStoreKey() required this.contactId,
    @InlayStoreKey() required this.threadId,
    this.value = true,
  });

  final String contactId;
  final int threadId;
  final bool value;
}
''';

const _invalidStoreUnsupportedKeySource = '''
import 'package:inlay/inlay.dart';

@InlayStore(key: 'invalid_store')
class InvalidStore {
  const InvalidStore({
    @InlayStoreKey() required this.keyValue,
    this.value = true,
  });

  final double keyValue;
  final bool value;
}
''';

const _invalidStoreOptionalKeySource = '''
import 'package:inlay/inlay.dart';

@InlayStore(key: 'invalid_store')
class InvalidStore {
  const InvalidStore({
    @InlayStoreKey() this.contactId = 'default',
    this.value = true,
  });

  final String contactId;
  final bool value;
}
''';

const _complexStoreSource = '''
import 'package:inlay/inlay.dart';

@InlayStore(key: 'complex_store')
class ComplexStore {
  const ComplexStore({
    @InlayStoreKey() required this.contactId,
    this.tags = const [],
    this.preferences,
  });

  final String contactId;
  final List<String> tags;
  final NotificationPreferences? preferences;
}

class NotificationPreferences {
  const NotificationPreferences({required this.sound, this.muted = false});

  final String sound;
  final bool muted;
}
''';

const _invalidComplexStoreSource = '''
import 'package:inlay/inlay.dart';

@InlayStore(key: 'invalid_store')
class InvalidStore {
  const InvalidStore({
    required this.items,
  });

  final List<String> items;
}
''';

void main() {
  late AnnotationParser parser;

  setUp(() {
    parser = AnnotationParser();
  });

  group('AnnotationParser', () {
    test('parses flutter route annotations', () {
      final schema = parser.parse(_routesSource);

      expect(schema.flutterRoutes, hasLength(2));

      final contactDetails = schema.flutterRoutes[0];
      expect(contactDetails.className, 'ContactDetailsPage');
      expect(contactDetails.routeName, 'contactDetails');
      expect(contactDetails.fields, hasLength(2));

      final soundsNotifications = schema.flutterRoutes[1];
      expect(soundsNotifications.className, 'SoundsNotificationsPage');
      expect(soundsNotifications.routeName, 'sounds-notifications');
    });

    test('parses native route annotations', () {
      final schema = parser.parse(_routesSource);

      expect(schema.nativeRoutes, hasLength(1));

      final editProfile = schema.nativeRoutes[0];
      expect(editProfile.className, 'NativeEditProfilePage');
      expect(editProfile.routeName, 'edit-profile');
    });

    test('parses data classes without annotations', () {
      final schema = parser.parse(_routesSource);

      expect(schema.dataClasses, hasLength(1));

      final contactSettings = schema.dataClasses[0];
      expect(contactSettings.className, 'ContactSettings');
      expect(contactSettings.fields, hasLength(2));
    });

    test('parses enums', () {
      final schema = parser.parse(_routesSource);

      expect(schema.enums, hasLength(1));

      final mediaType = schema.enums[0];
      expect(mediaType.name, 'MediaType');
      expect(mediaType.values, ['image', 'video', 'audio']);
    });

    test('parses store annotations', () {
      final schema = parser.parse(_storesSource);

      expect(schema.stores, hasLength(2));

      final soundsStore = schema.stores[0];
      expect(soundsStore.className, 'SoundsNotificationsStore');
      expect(soundsStore.storeKey, 'sounds_notifications');
      expect(soundsStore.keyFields, hasLength(1));
      expect(soundsStore.keyFields[0].name, 'contactId');
      expect(soundsStore.keyFields[0].isStoreKey, isTrue);
      expect(soundsStore.valueFields, hasLength(4));

      final userPrefsStore = schema.stores[1];
      expect(userPrefsStore.className, 'UserPreferencesStore');
      expect(userPrefsStore.storeKey, 'user_preferences');
      expect(userPrefsStore.keyFields, isEmpty);
      expect(userPrefsStore.valueFields, hasLength(2));
    });

    test('parses nullable fields correctly', () {
      final schema = parser.parse(_routesSource);

      final contactDetails = schema.flutterRoutes[0];
      final settingsField = contactDetails.fields.firstWhere(
        (f) => f.name == 'settings',
      );

      expect(settingsField.type.isNullable, isTrue);
      expect(settingsField.type.baseName, 'ContactSettings');
      expect(settingsField.isRequired, isFalse);
    });

    test('parses default values', () {
      final schema = parser.parse(_storesSource);

      final soundsStore = schema.stores[0];
      final muteField = soundsStore.valueFields.firstWhere(
        (f) => f.name == 'mute',
      );

      expect(muteField.hasDefault, isTrue);
      expect(muteField.defaultValue, 'false');

      final showPreviewsField = soundsStore.valueFields.firstWhere(
        (f) => f.name == 'showPreviews',
      );

      expect(showPreviewsField.hasDefault, isTrue);
      expect(showPreviewsField.defaultValue, 'true');
    });

    test('parses key fields with int and enum types', () {
      final schema = parser.parse(_storeKeyTypesSource);

      expect(schema.stores, hasLength(2));

      final threadStore = schema.stores[0];
      expect(threadStore.keyFields, hasLength(1));
      expect(threadStore.keyFields[0].name, 'threadId');
      expect(threadStore.keyFields[0].type.baseName, 'int');

      final categoryStore = schema.stores[1];
      expect(categoryStore.keyFields, hasLength(1));
      expect(categoryStore.keyFields[0].name, 'category');
      expect(categoryStore.keyFields[0].type.baseName, 'ConversationCategory');
    });

    test('parses nested types and generics', () {
      final schema = parser.parse(_nestedTypesSource);

      final mediaViewer = schema.flutterRoutes[0];

      final tagsField = mediaViewer.fields.firstWhere((f) => f.name == 'tags');
      expect(tagsField.type.baseName, 'List');
      expect(tagsField.type.isNullable, isTrue);
      expect(tagsField.type.typeArguments, hasLength(1));
      expect(tagsField.type.typeArguments[0].baseName, 'String');

      final metadataField = mediaViewer.fields.firstWhere(
        (f) => f.name == 'metadata',
      );
      expect(metadataField.type.baseName, 'Map');
      expect(metadataField.type.typeArguments, hasLength(2));
    });

    test('parses flutter dialog annotations', () {
      final schema = parser.parse(_dialogRoutesSource);

      expect(schema.flutterDialogRoutes, hasLength(2));

      final confirmAction = schema.flutterDialogRoutes[0];
      expect(confirmAction.className, 'ConfirmActionDialog');
      expect(confirmAction.routeName, 'confirmActionDialog');
      expect(confirmAction.routeType.name, 'flutterDialog');
      expect(confirmAction.path, '/confirm-action/:action');
      expect(confirmAction.fields, hasLength(2));

      final themePicker = schema.flutterDialogRoutes[1];
      expect(themePicker.className, 'ThemePickerDialog');
      expect(themePicker.routeName, 'themePickerDialog');
      expect(themePicker.path, '/theme-picker/:userId');
      expect(themePicker.fields, hasLength(1));
    });

    test('parses enhanced enum declarations', () {
      final schema = parser.parse(_enhancedEnumRoutesSource);

      expect(schema.enums, hasLength(1));
      final enumDef = schema.enums.first;
      expect(enumDef.name, 'DeliveryChannel');
      expect(enumDef.values, ['push', 'sms']);
    });
  });

  group('TypeResolver', () {
    test('validates known types', () {
      final schema = parser.parse(_routesSource);
      final resolver = TypeResolver();
      final result = resolver.resolve(schema);

      expect(result.isValid, isTrue);
      expect(result.errors, isEmpty);
    });

    test('detects unknown types', () {
      const source = '''
@InlayFlutterRoute()
class InvalidPage {
  const InvalidPage({required this.data});

  final UnknownType data;
}
''';

      final schema = parser.parse(source);
      final resolver = TypeResolver();
      final result = resolver.resolve(schema);

      expect(result.isValid, isFalse);
      expect(result.errors, isNotEmpty);
      expect(result.errors.first.message, contains('Unknown type'));
    });

    test('detects duplicate route names', () {
      const source = '''
@InlayFlutterRoute('same-name')
class FirstPage {
  const FirstPage();
}

@InlayFlutterRoute('same-name')
class SecondPage {
  const SecondPage();
}
''';

      final schema = parser.parse(source);
      final resolver = TypeResolver();
      final result = resolver.resolve(schema);

      expect(result.isValid, isFalse);
      expect(
        result.errors.any((e) => e.message.contains('Duplicate route name')),
        isTrue,
      );
    });

    test('validates store key and enum value types', () {
      final schema = parser.parse(_storesSource);
      final resolver = TypeResolver();
      final result = resolver.resolve(schema);

      expect(result.isValid, isTrue);
      expect(result.errors, isEmpty);
    });

    test('allows int and enum store keys', () {
      final schema = parser.parse(_storeKeyTypesSource);
      final resolver = TypeResolver();
      final result = resolver.resolve(schema);

      expect(result.isValid, isTrue);
      expect(result.errors, isEmpty);
    });

    test('rejects multiple store keys', () {
      final schema = parser.parse(_invalidStoreMultipleKeysSource);
      final resolver = TypeResolver();
      final result = resolver.resolve(schema);

      expect(result.isValid, isFalse);
      expect(
        result.errors.any(
          (e) => e.message.contains('at most one field annotated'),
        ),
        isTrue,
      );
    });

    test('rejects unsupported store key type', () {
      final schema = parser.parse(_invalidStoreUnsupportedKeySource);
      final resolver = TypeResolver();
      final result = resolver.resolve(schema);

      expect(result.isValid, isFalse);
      expect(
        result.errors.any(
          (e) => e.message.contains('must be String, int, or enum'),
        ),
        isTrue,
      );
    });

    test('rejects non-required store key', () {
      final schema = parser.parse(_invalidStoreOptionalKeySource);
      final resolver = TypeResolver();
      final result = resolver.resolve(schema);

      expect(result.isValid, isFalse);
      expect(
        result.errors.any(
          (e) => e.message.contains('must be a required constructor parameter'),
        ),
        isTrue,
      );
    });

    test('accepts complex store value types', () {
      final schema = parser.parse(_complexStoreSource);
      final resolver = TypeResolver();
      final result = resolver.resolve(schema);

      expect(result.isValid, isTrue);
      expect(result.errors, isEmpty);
    });

    test('rejects non-nullable complex store field without default', () {
      final schema = parser.parse(_invalidComplexStoreSource);
      final resolver = TypeResolver();
      final result = resolver.resolve(schema);

      expect(result.isValid, isFalse);
      expect(
        result.errors.any(
          (e) => e.message.contains('Non-nullable complex store field'),
        ),
        isTrue,
      );
    });
  });

  group('Dart code generation', () {
    test('generates routes with serialization', () {
      final schema = parser.parse(_routesSource);
      final resolver = TypeResolver();
      final result = resolver.resolve(schema);

      final code = generateDartRoutes(
        schemaFingerprint: 'testfp',
        schema: schema,
        typeGraph: result.typeGraph,
      );

      expect(code, contains('class ContactDetailsPage extends FlutterRoute'));
      expect(code, contains('List<Object?> encode()'));
      expect(
        code,
        contains('static ContactDetailsPage decode(List<Object?> list)'),
      );
      expect(
        code,
        contains("static const String routeName = 'contactDetails'"),
      );
    });

    test('generates stores with typed accessors', () {
      final schema = parser.parse(_storesSource);
      final resolver = TypeResolver();
      final result = resolver.resolve(schema);

      expect(result.isValid, isTrue);

      final code = generateDartStores(
        schema: schema,
        typeGraph: result.typeGraph,
      );

      expect(code, contains('class SoundsNotificationsStore'));
      expect(code, contains('{required this.contactId'));
      expect(
        code,
        contains(
          r"String _key(String field) => 'sounds_notifications/$contactId/$field';",
        ),
      );
      expect(code, contains('Future<bool> getMute()'));
      expect(code, contains('Future<void> setMute(bool value)'));
      expect(code, contains('Future<NotificationBehavior> getBehavior()'));
      expect(code, contains('NotificationBehavior.values[int.parse(value)]'));
      expect(code, contains('value.index.toString()'));
      expect(code, contains('UserPreferencesStore(this._storage);'));
      expect(
        code,
        contains('Stream<SoundsNotificationsStoreSnapshot> get stream'),
      );
    });

    test('generates route serialization for enhanced enum fields', () {
      final schema = parser.parse(_enhancedEnumRoutesSource);
      final resolver = TypeResolver();
      final result = resolver.resolve(schema);

      expect(result.isValid, isTrue);

      final code = generateDartRoutes(
        schemaFingerprint: 'testfp',
        schema: schema,
        typeGraph: result.typeGraph,
      );

      expect(code, contains('enum DeliveryChannel {'));
      expect(code, contains('push,'));
      expect(code, contains('sms,'));
      expect(code, contains('channel.index'));
      expect(code, contains('DeliveryChannel.values[list[0] as int]'));
    });

    test('generates dialog routes with sealed class and decoder', () {
      final schema = parser.parse(_dialogRoutesSource);
      final resolver = TypeResolver();
      final result = resolver.resolve(schema);

      final code = generateDartRoutes(
        schemaFingerprint: 'testfp',
        schema: schema,
        typeGraph: result.typeGraph,
      );

      expect(
        code,
        contains(
          'sealed class FlutterDialogRoute extends FlutterDialogRouteBase',
        ),
      );
      expect(
        code,
        contains('class ConfirmActionDialog extends FlutterDialogRoute'),
      );
      expect(
        code,
        contains('class ThemePickerDialog extends FlutterDialogRoute'),
      );
      expect(code, contains('decodeFlutterDialogRouteData'));
      expect(code, contains('decodeInlayRouteData'));
    });

    test('generates combined decoder for pages and dialogs', () {
      final routesSchema = parser.parse(_routesSource);
      final dialogSchema = parser.parse(_dialogRoutesSource);
      final merged = routesSchema.merge(dialogSchema);
      final resolver = TypeResolver();
      final result = resolver.resolve(merged);

      final code = generateDartRoutes(
        schemaFingerprint: 'testfp',
        schema: merged,
        typeGraph: result.typeGraph,
      );

      expect(code, contains('decodeFlutterRouteData'));
      expect(code, contains('decodeFlutterDialogRouteData'));
      expect(code, contains('InlayRoute? decodeInlayRouteData'));
      expect(
        code,
        contains(
          'return decodeFlutterRouteData(settings) ?? decodeFlutterDialogRouteData(settings);',
        ),
      );
    });

    test('generates Dart stores with complex fields', () {
      final schema = parser.parse(_complexStoreSource);
      final resolver = TypeResolver();
      final result = resolver.resolve(schema);

      expect(result.isValid, isTrue);

      final code = generateDartStores(
        schema: schema,
        typeGraph: result.typeGraph,
      );

      expect(code, contains("import 'dart:convert';"));
      expect(code, contains('class NotificationPreferences {'));
      expect(code, contains('Future<List<String>> getTags()'));
      expect(code, contains('jsonDecode'));
      expect(code, contains('jsonEncode'));
      expect(code, contains('Future<void> setTags(List<String> value)'));
      expect(
        code,
        contains('Future<NotificationPreferences?> getPreferences()'),
      );
      expect(
        code,
        contains('Future<void> setPreferences(NotificationPreferences? value)'),
      );
    });

    test('generates Dart key helpers for int and enum keys', () {
      final schema = parser.parse(_storeKeyTypesSource);
      final resolver = TypeResolver();
      final result = resolver.resolve(schema);

      expect(result.isValid, isTrue);

      final code = generateDartStores(
        schema: schema,
        typeGraph: result.typeGraph,
      );

      expect(
        code,
        contains(
          r"String _key(String field) => 'thread_preferences/$threadId/$field';",
        ),
      );
      expect(
        code,
        contains(
          r"String _key(String field) => 'category_preferences/${category.name}/$field';",
        ),
      );
    });
  });

  group('Kotlin code generation', () {
    test('generates data classes with serialization', () {
      final schema = parser.parse(_routesSource);
      final resolver = TypeResolver();
      final result = resolver.resolve(schema);

      final code = generateKotlinRoutes(
        schemaFingerprint: 'testfp',
        schema: schema,
        typeGraph: result.typeGraph,
        packageName: 'com.example.generated',
      );

      expect(code, contains('package com.example.generated'));
      expect(code, contains('data class ContactDetailsPage('));
      expect(code, contains('fun toList(): List<Any?>'));
      expect(code, contains('fun fromList(list: List<Any?>)'));
    });

    test('generates stores with properties', () {
      final schema = parser.parse(_storesSource);
      final resolver = TypeResolver();
      final result = resolver.resolve(schema);

      final code = generateKotlinStores(
        schema: schema,
        typeGraph: result.typeGraph,
        packageName: 'com.example.generated',
      );

      expect(code, contains('class SoundsNotificationsStore'));
      expect(code, contains('private val contactId: String'));
      expect(code, contains('var mute: Boolean'));
      expect(code, contains('var showPreviews: Boolean'));
      expect(code, contains('var behavior: NotificationBehavior'));
      expect(
        code,
        contains(
          'set(value) = storage.put(key("behavior"), value.ordinal.toString())',
        ),
      );
    });

    test('generates dialog route data classes with FlutterDialogRoute', () {
      final schema = parser.parse(_dialogRoutesSource);
      final resolver = TypeResolver();
      final result = resolver.resolve(schema);

      final code = generateKotlinRoutes(
        schemaFingerprint: 'testfp',
        schema: schema,
        typeGraph: result.typeGraph,
        packageName: 'com.example.generated',
      );

      expect(code, contains('import co.leancode.inlay.FlutterDialogRoute'));
      expect(code, contains('data class ConfirmActionDialog('));
      expect(code, contains(') : FlutterDialogRoute {'));
      expect(code, contains('override fun toPageSettings()'));
    });

    test('generates typed WithResult interfaces for result routes', () {
      final schema = parser.parse(_resultRoutesSource);
      final resolver = TypeResolver();
      final result = resolver.resolve(schema);

      final code = generateKotlinRoutes(
        schemaFingerprint: 'testfp',
        schema: schema,
        typeGraph: result.typeGraph,
        packageName: 'com.example.generated',
      );

      expect(code, contains('import co.leancode.inlay.FlutterRouteWithResult'));
      expect(
        code,
        contains('import co.leancode.inlay.FlutterDialogRouteWithResult'),
      );
      expect(code, contains(') : FlutterRouteWithResult<Long> {'));
      expect(code, contains(') : FlutterDialogRouteWithResult<Boolean> {'));
      expect(
        code,
        contains(
          'override fun decodeResult(raw: Any?): Long? = '
          'Companion.decodeResult(raw)',
        ),
      );
      expect(
        code,
        contains(
          'override fun decodeResult(raw: Any?): Boolean? = '
          'Companion.decodeResult(raw)',
        ),
      );
    });

    test('generates Kotlin stores with complex fields', () {
      final schema = parser.parse(_complexStoreSource);
      final resolver = TypeResolver();
      final result = resolver.resolve(schema);

      expect(result.isValid, isTrue);

      final code = generateKotlinStores(
        schema: schema,
        typeGraph: result.typeGraph,
        packageName: 'com.example.generated',
      );

      expect(code, contains('import org.json.JSONArray'));
      expect(code, contains('fun jsonToKotlin'));
      expect(code, contains('data class NotificationPreferences('));
      expect(code, contains('var tags: List<String>'));
      expect(code, contains('var preferences: NotificationPreferences?'));
      expect(code, contains('JSONArray'));
    });

    test('generates Kotlin key helpers for int and enum keys', () {
      final schema = parser.parse(_storeKeyTypesSource);
      final resolver = TypeResolver();
      final result = resolver.resolve(schema);

      expect(result.isValid, isTrue);

      final code = generateKotlinStores(
        schema: schema,
        typeGraph: result.typeGraph,
        packageName: 'com.example.generated',
      );

      expect(
        code,
        contains(
          r'private fun key(field: String) = "thread_preferences/$threadId/$field"',
        ),
      );
      expect(
        code,
        contains(
          r'private fun key(field: String) = "category_preferences/${category.name}/$field"',
        ),
      );
    });
  });

  group('Swift code generation', () {
    test('generates structs with serialization', () {
      final schema = parser.parse(_routesSource);
      final resolver = TypeResolver();
      final result = resolver.resolve(schema);

      final code = generateSwiftRoutes(
        schemaFingerprint: 'testfp',
        schema: schema,
        typeGraph: result.typeGraph,
      );

      expect(code, contains('struct ContactDetailsPage: FlutterRoute {'));
      expect(code, contains('func toList() -> [Any?]'));
      expect(code, contains('static func fromList(_ list: [Any?])'));
      expect(code, contains('static let routeName = "contactDetails"'));
    });

    test('generates dialog route structs with FlutterDialogRoute', () {
      final schema = parser.parse(_dialogRoutesSource);
      final resolver = TypeResolver();
      final result = resolver.resolve(schema);

      final code = generateSwiftRoutes(
        schemaFingerprint: 'testfp',
        schema: schema,
        typeGraph: result.typeGraph,
      );

      expect(
        code,
        contains('struct ConfirmActionDialog: FlutterDialogRoute {'),
      );
      expect(code, contains('func toPageSettings() -> PageSettings'));
    });

    test('generates typed WithResult conformance for result routes', () {
      final schema = parser.parse(_resultRoutesSource);
      final resolver = TypeResolver();
      final result = resolver.resolve(schema);

      final code = generateSwiftRoutes(
        schemaFingerprint: 'testfp',
        schema: schema,
        typeGraph: result.typeGraph,
      );

      expect(code, contains('struct CounterPage: FlutterRouteWithResult {'));
      expect(
        code,
        contains('struct ConfirmActionDialog: FlutterDialogRouteWithResult {'),
      );
      expect(code, contains('static func decodeResult(_ raw: Any?) -> Int64?'));
      expect(code, contains('static func decodeResult(_ raw: Any?) -> Bool?'));
    });

    test('generates Swift stores with complex fields', () {
      final schema = parser.parse(_complexStoreSource);
      final resolver = TypeResolver();
      final result = resolver.resolve(schema);

      expect(result.isValid, isTrue);

      final code = generateSwiftStores(
        schema: schema,
        typeGraph: result.typeGraph,
      );

      expect(code, contains('struct NotificationPreferences {'));
      expect(code, contains('var tags: [String]'));
      expect(code, contains('var preferences: NotificationPreferences?'));
      expect(code, contains('JSONSerialization'));
    });

    test('generates enums with raw values', () {
      final schema = parser.parse(_routesSource);
      final resolver = TypeResolver();
      final result = resolver.resolve(schema);

      final code = generateSwiftRoutes(
        schemaFingerprint: 'testfp',
        schema: schema,
        typeGraph: result.typeGraph,
      );

      expect(code, contains('enum MediaType: Int {'));
      expect(code, contains('case image = 0'));
    });
  });

  group('Naming utilities', () {
    test('routeIdFromClassName strips Page suffix', () {
      expect(routeIdFromClassName('ContactDetailsPage'), 'contactDetails');
      expect(
        routeIdFromClassName('NativeEditProfilePage'),
        'nativeEditProfile',
      );
      expect(routeIdFromClassName('SimplePage'), 'simple');
    });

    test('storeKeyFromClassName converts to snake_case', () {
      expect(
        storeKeyFromClassName('SoundsNotificationsStore'),
        'sounds_notifications',
      );
      expect(storeKeyFromClassName('UserPreferencesStore'), 'user_preferences');
      expect(storeKeyFromClassName('SimpleStore'), 'simple');
    });

    test('toSnakeCase converts properly', () {
      expect(toSnakeCase('SoundsNotifications'), 'sounds_notifications');
      expect(toSnakeCase('contactId'), 'contact_id');
      expect(toSnakeCase('ABC'), 'a_b_c');
    });
  });
}
