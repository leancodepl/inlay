import 'package:leancode_add2app_gen/src/generators/dart/dart_routes_generator.dart';
import 'package:leancode_add2app_gen/src/generators/dart/dart_store_generator.dart';
import 'package:leancode_add2app_gen/src/generators/kotlin/kotlin_routes_generator.dart';
import 'package:leancode_add2app_gen/src/generators/kotlin/kotlin_store_generator.dart';
import 'package:leancode_add2app_gen/src/generators/swift/swift_routes_generator.dart';
import 'package:leancode_add2app_gen/src/parser/annotation_parser.dart';
import 'package:leancode_add2app_gen/src/parser/type_resolver.dart';
import 'package:leancode_add2app_gen/src/utils/naming.dart';
import 'package:test/test.dart';

const _routesSource = '''
import 'package:leancode_add2app/leancode_add2app.dart';

@Add2AppFlutterRoute()
class ContactDetailsPage {
  const ContactDetailsPage({required this.contactId, this.settings});

  final String contactId;
  final ContactSettings? settings;
}

@Add2AppFlutterRoute('sounds-notifications')
class SoundsNotificationsPage {
  const SoundsNotificationsPage({required this.contactId});

  final String contactId;
}

@Add2AppNativeRoute('edit-profile')
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
import 'package:leancode_add2app/leancode_add2app.dart';

@Add2AppStore(key: 'sounds_notifications')
class SoundsNotificationsStore {
  const SoundsNotificationsStore({
    required this.contactId,
    this.mute = false,
    this.showPreviews = true,
    this.sound = 'Default',
  });

  final String contactId;
  final bool mute;
  final bool showPreviews;
  final String sound;
}

@Add2AppStore()
class UserPreferencesStore {
  const UserPreferencesStore({
    this.darkMode = false,
    this.locale,
  });

  final bool darkMode;
  final String? locale;
}
''';

const _nestedTypesSource = '''
import 'package:leancode_add2app/leancode_add2app.dart';

@Add2AppFlutterRoute()
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

@Add2AppFlutterRoute()
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
      expect(soundsStore.scopeFields, hasLength(1));
      expect(soundsStore.scopeFields[0].name, 'contactId');
      expect(soundsStore.valueFields, hasLength(3));

      final userPrefsStore = schema.stores[1];
      expect(userPrefsStore.className, 'UserPreferencesStore');
      expect(userPrefsStore.storeKey, 'user_preferences');
      expect(userPrefsStore.scopeFields, isEmpty);
      expect(userPrefsStore.valueFields, hasLength(2));
    });

    test('parses nullable fields correctly', () {
      final schema = parser.parse(_routesSource);

      final contactDetails = schema.flutterRoutes[0];
      final settingsField = contactDetails.fields
          .firstWhere((f) => f.name == 'settings');
      
      expect(settingsField.type.isNullable, isTrue);
      expect(settingsField.type.baseName, 'ContactSettings');
      expect(settingsField.isRequired, isFalse);
    });

    test('parses default values', () {
      final schema = parser.parse(_storesSource);

      final soundsStore = schema.stores[0];
      final muteField = soundsStore.valueFields
          .firstWhere((f) => f.name == 'mute');
      
      expect(muteField.hasDefault, isTrue);
      expect(muteField.defaultValue, 'false');

      final showPreviewsField = soundsStore.valueFields
          .firstWhere((f) => f.name == 'showPreviews');
      
      expect(showPreviewsField.hasDefault, isTrue);
      expect(showPreviewsField.defaultValue, 'true');
    });

    test('parses nested types and generics', () {
      final schema = parser.parse(_nestedTypesSource);

      final mediaViewer = schema.flutterRoutes[0];
      
      final tagsField = mediaViewer.fields
          .firstWhere((f) => f.name == 'tags');
      expect(tagsField.type.baseName, 'List');
      expect(tagsField.type.isNullable, isTrue);
      expect(tagsField.type.typeArguments, hasLength(1));
      expect(tagsField.type.typeArguments[0].baseName, 'String');

      final metadataField = mediaViewer.fields
          .firstWhere((f) => f.name == 'metadata');
      expect(metadataField.type.baseName, 'Map');
      expect(metadataField.type.typeArguments, hasLength(2));
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
@Add2AppFlutterRoute()
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
@Add2AppFlutterRoute('same-name')
class FirstPage {
  const FirstPage();
}

@Add2AppFlutterRoute('same-name')
class SecondPage {
  const SecondPage();
}
''';

      final schema = parser.parse(source);
      final resolver = TypeResolver();
      final result = resolver.resolve(schema);

      expect(result.isValid, isFalse);
      expect(result.errors.any((e) => e.message.contains('Duplicate route name')),
          isTrue);
    });
  });

  group('Dart code generation', () {
    test('generates routes with serialization', () {
      final schema = parser.parse(_routesSource);
      final resolver = TypeResolver();
      final result = resolver.resolve(schema);

      final code = generateDartRoutes(
        schema: schema,
        typeGraph: result.typeGraph,
      );

      expect(code, contains('class ContactDetailsPage extends FlutterRouteBase'));
      expect(code, contains('List<Object?> encode()'));
      expect(code, contains('static ContactDetailsPage decode(List<Object?> list)'));
      expect(code, contains("static const String routeName = 'contactDetails'"));
    });

    test('generates stores with typed accessors', () {
      final schema = parser.parse(_storesSource);

      final code = generateDartStores(schema: schema);

      expect(code, contains('class SoundsNotificationsStore'));
      expect(code, contains('Future<bool> getMute()'));
      expect(code, contains('Future<void> setMute(bool value)'));
      expect(code, contains('Stream<SoundsNotificationsStoreSnapshot> get stream'));
    });
  });

  group('Kotlin code generation', () {
    test('generates data classes with serialization', () {
      final schema = parser.parse(_routesSource);
      final resolver = TypeResolver();
      final result = resolver.resolve(schema);

      final code = generateKotlinRoutes(
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

      final code = generateKotlinStores(
        schema: schema,
        packageName: 'com.example.generated',
      );

      expect(code, contains('class SoundsNotificationsStore'));
      expect(code, contains('var mute: Boolean'));
      expect(code, contains('var showPreviews: Boolean'));
    });
  });

  group('Swift code generation', () {
    test('generates structs with serialization', () {
      final schema = parser.parse(_routesSource);
      final resolver = TypeResolver();
      final result = resolver.resolve(schema);

      final code = generateSwiftRoutes(
        schema: schema,
        typeGraph: result.typeGraph,
      );

      expect(code, contains('struct ContactDetailsPage {'));
      expect(code, contains('func toList() -> [Any?]'));
      expect(code, contains('static func fromList(_ list: [Any?])'));
      expect(code, contains('static let routeName = "contactDetails"'));
    });

    test('generates enums with raw values', () {
      final schema = parser.parse(_routesSource);
      final resolver = TypeResolver();
      final result = resolver.resolve(schema);

      final code = generateSwiftRoutes(
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
      expect(routeIdFromClassName('NativeEditProfilePage'), 'nativeEditProfile');
      expect(routeIdFromClassName('SimplePage'), 'simple');
    });

    test('storeKeyFromClassName converts to snake_case', () {
      expect(storeKeyFromClassName('SoundsNotificationsStore'), 'sounds_notifications');
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
