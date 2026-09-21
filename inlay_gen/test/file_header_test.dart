import 'dart:io';

import 'package:inlay_gen/src/core/code_generator.dart';
import 'package:inlay_gen/src/core/generation_result.dart';
import 'package:inlay_gen/src/generators/dart/dart_routes_generator.dart';
import 'package:inlay_gen/src/generators/java/java_routes_generator.dart';
import 'package:inlay_gen/src/generators/kotlin/kotlin_routes_generator.dart';
import 'package:inlay_gen/src/generators/kotlin/kotlin_store_generator.dart';
import 'package:inlay_gen/src/generators/swift/swift_routes_generator.dart';
import 'package:inlay_gen/src/models/route_definition.dart';
import 'package:inlay_gen/src/models/schema.dart';
import 'package:inlay_gen/src/models/store_definition.dart';
import 'package:inlay_gen/src/models/type_info.dart';
import 'package:inlay_gen/src/utils/file_header.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

const _header = [
  'CHECKSTYLE.OFF: LineLength|MagicNumber',
  '// already prefixed',
  '',
];
const _rendered =
    '// CHECKSTYLE.OFF: LineLength|MagicNumber\n// already prefixed\n//\n';

const _schema = Schema(
  flutterRoutes: [
    RouteDefinition(
      className: 'SettingsPage',
      routeType: RouteType.flutter,
      routeName: '/settings',
      path: '/settings',
      fields: [],
    ),
  ],
  nativeRoutes: [
    RouteDefinition(
      className: 'NativeAboutPage',
      routeType: RouteType.native,
      routeName: 'nativeAbout',
      fields: [],
    ),
  ],
  stores: [
    StoreDefinition(
      className: 'CounterStore',
      storeKey: 'counter',
      keyFields: [],
      valueFields: [
        FieldInfo(
          name: 'count',
          type: TypeInfo(name: 'int', isNullable: false),
          isRequired: false,
          defaultValue: '0',
        ),
      ],
    ),
  ],
);

void main() {
  group('renderFileHeader', () {
    test('prefixes every line once and keeps empty lines as bare //', () {
      expect(renderFileHeader(_header), _rendered);
    });

    test('is empty when no header is configured', () {
      expect(renderFileHeader(const []), '');
    });
  });

  group('generated files open with the configured header', () {
    test('Dart', () {
      final output = generateDartRoutes(
        schema: _schema,
        typeGraph: {},
        schemaFingerprint: 'fp',
        header: _header,
      );

      // The format-off directive stays first; the header follows it.
      expect(
        output,
        startsWith('// dart format off\n$_rendered// GENERATED CODE'),
      );
    });

    test('Kotlin routes and stores', () {
      final routes = generateKotlinRoutes(
        schema: _schema,
        typeGraph: {},
        packageName: 'com.example',
        schemaFingerprint: 'fp',
        header: _header,
      );
      final stores = generateKotlinStores(
        schema: _schema,
        typeGraph: {},
        packageName: 'com.example',
        header: _header,
      );

      expect(routes, startsWith('$_rendered// GENERATED CODE'));
      expect(stores, startsWith('$_rendered// GENERATED CODE'));
    });

    test('Swift', () {
      final output = generateSwiftRoutes(
        schema: _schema,
        typeGraph: {},
        schemaFingerprint: 'fp',
        header: _header,
      );

      expect(output, startsWith('$_rendered// GENERATED CODE'));
    });

    test('Java - every file, including the helpers', () {
      final files = generateJavaRoutes(
        schema: _schema,
        typeGraph: {},
        packageName: 'com.example',
        schemaFingerprint: 'fp',
        header: _header,
      );

      expect(files, isNotEmpty);
      for (final MapEntry(key: name, value: content) in files.entries) {
        expect(
          content,
          startsWith('$_rendered// GENERATED CODE'),
          reason: name,
        );
      }
    });

    test('nothing is prepended without a header', () {
      final output = generateSwiftRoutes(
        schema: _schema,
        typeGraph: {},
        schemaFingerprint: 'fp',
      );

      expect(output, startsWith('// GENERATED CODE'));
    });
  });

  group('writeNativeFiles (Java)', () {
    late Directory dir;

    setUp(() {
      dir = Directory.systemTemp.createTempSync('inlay_gen_java_');
    });

    tearDown(() {
      dir.deleteSync(recursive: true);
    });

    GenerationResult result(Schema schema) => GenerationResult(
      schema: schema,
      typeGraph: const {},
      javaRoutesCode: generateJavaRoutes(
        schema: schema,
        typeGraph: {},
        packageName: 'com.example',
        schemaFingerprint: 'fp',
        header: _header,
      ),
    );

    test('removes generated files for routes that no longer exist', () {
      final config = NativeOutputConfig(
        javaOutput: dir.path,
        javaPackage: 'com.example',
      );
      // A hand-written file in the same package must never be touched.
      File(
        p.join(dir.path, 'HandWritten.java'),
      ).writeAsStringSync('class HandWritten {}\n');

      writeNativeFiles(result(_schema), config);
      expect(
        File(p.join(dir.path, 'NativeAboutPage.java')).existsSync(),
        isTrue,
      );
      expect(
        File(p.join(dir.path, 'NativeRouteHandler.java')).existsSync(),
        isTrue,
      );

      writeNativeFiles(
        result(const Schema(flutterRoutes: [_schemaSettingsRoute])),
        config,
      );

      // Header lines precede the banner, so detection must scan past them.
      expect(
        File(p.join(dir.path, 'NativeAboutPage.java')).existsSync(),
        isFalse,
      );
      expect(
        File(p.join(dir.path, 'NativeRouteHandler.java')).existsSync(),
        isFalse,
      );
      expect(File(p.join(dir.path, 'SettingsPage.java')).existsSync(), isTrue);
      expect(File(p.join(dir.path, 'HandWritten.java')).existsSync(), isTrue);
    });
  });
}

const _schemaSettingsRoute = RouteDefinition(
  className: 'SettingsPage',
  routeType: RouteType.flutter,
  routeName: '/settings',
  path: '/settings',
  fields: [],
);
