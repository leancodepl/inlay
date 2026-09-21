import 'package:inlay_gen/src/generators/dart/dart_routes_generator.dart';
import 'package:inlay_gen/src/generators/kotlin/kotlin_routes_generator.dart';
import 'package:inlay_gen/src/generators/kotlin/kotlin_serialization.dart';
import 'package:inlay_gen/src/generators/swift/swift_routes_generator.dart';
import 'package:inlay_gen/src/models/route_definition.dart';
import 'package:inlay_gen/src/models/schema.dart';
import 'package:inlay_gen/src/models/type_info.dart';
import 'package:inlay_gen/src/parser/type_resolver.dart';
import 'package:test/test.dart';

void main() {
  group('Kotlin decode', () {
    final typeGraph = <String, TypeDefinition>{
      'GreetingStyle': const EnumType(
        name: 'GreetingStyle',
        values: ['formal', 'casual'],
      ),
      'Badge': const DataClassType(
        name: 'Badge',
        fields: [
          FieldInfo(
            name: 'label',
            type: TypeInfo(name: 'String', isNullable: false),
            isRequired: true,
          ),
        ],
      ),
    };

    test(
      'nullable enum casts against the wire type (Number), not the enum',
      () {
        final decode = generateKotlinDecode(
          'list[1]',
          const TypeInfo(name: 'GreetingStyle', isNullable: true),
          typeGraph,
        );

        // Regression: `as? GreetingStyle` on an Int ordinal is always null.
        expect(decode, isNot(contains('as? GreetingStyle')));
        expect(
          decode,
          '(list[1] as? Number)?.let { GreetingStyle.entries[it.toInt()] }',
        );
      },
    );

    test('nullable custom class casts against the wire type (List)', () {
      final decode = generateKotlinDecode(
        'list[0]',
        const TypeInfo(name: 'Badge', isNullable: true),
        typeGraph,
      );

      expect(decode, isNot(contains('as? Badge')));
      expect(decode, contains('as? List<*>'));
      expect(decode, contains('Badge.fromList'));
    });

    test('int decodes through Number (wire delivers Int32 or Int64)', () {
      expect(
        generateKotlinDecode(
          'list[0]',
          const TypeInfo(name: 'int', isNullable: false),
          typeGraph,
        ),
        '(list[0] as Number).toLong()',
      );
      expect(
        generateKotlinDecode(
          'list[0]',
          const TypeInfo(name: 'int', isNullable: true),
          typeGraph,
        ),
        '(list[0] as? Number)?.toLong()',
      );
    });

    test('non-nullable enum decodes ordinal through Number', () {
      expect(
        generateKotlinDecode(
          'list[1]',
          const TypeInfo(name: 'GreetingStyle', isNullable: false),
          typeGraph,
        ),
        'GreetingStyle.entries[(list[1] as Number).toInt()]',
      );
    });
  });

  group('Dart routes', () {
    test('parameterless routes produce a single statement terminator', () {
      final output = generateDartRoutes(
        schema: const Schema(
          flutterRoutes: [
            RouteDefinition(
              className: 'SettingsPage',
              routeType: RouteType.flutter,
              routeName: '/settings',
              path: '/settings',
              fields: [],
            ),
          ],
        ),
        typeGraph: {},
        schemaFingerprint: 'testfp',
      );

      // Regression: the empty-fields encode already ended with `;`, so the
      // generated file contained `;;` and did not parse.
      expect(output, contains('List<Object?> encode() => <Object?>[];'));
      expect(output, isNot(contains(';;')));
    });

    test('generated Dart is exempt from dart format', () {
      final output = generateDartRoutes(
        schema: const Schema(),
        typeGraph: {},
        schemaFingerprint: 'testfp',
      );

      expect(output, startsWith('// dart format off\n'));
    });
  });

  group('Kotlin routes', () {
    test(
      'parameterless routes are plain classes (data classes need a field)',
      () {
        final output = generateKotlinRoutes(
          schema: const Schema(
            flutterRoutes: [
              RouteDefinition(
                className: 'SettingsPage',
                routeType: RouteType.flutter,
                routeName: '/settings',
                path: '/settings',
                fields: [],
              ),
            ],
          ),
          typeGraph: {},
          packageName: 'com.example',
          schemaFingerprint: 'testfp',
        );

        expect(output, contains('class SettingsPage() : FlutterRoute {'));
        expect(output, isNot(contains('data class SettingsPage')));
      },
    );
  });

  group('Swift route encoding', () {
    Schema schemaWithRoute() => const Schema(
      flutterRoutes: [
        RouteDefinition(
          className: 'GreetingPage',
          routeType: RouteType.flutter,
          routeName: '/greeting/:name',
          path: '/greeting/:name',
          fields: [
            FieldInfo(
              name: 'name',
              type: TypeInfo(name: 'String', isNullable: false),
              isRequired: true,
            ),
            FieldInfo(
              name: 'note',
              type: TypeInfo(name: 'String', isNullable: true),
              isRequired: false,
            ),
          ],
        ),
      ],
    );

    test('parameterless routes produce an empty dictionary literal', () {
      final output = generateSwiftRoutes(
        schema: const Schema(
          flutterRoutes: [
            RouteDefinition(
              className: 'SettingsPage',
              routeType: RouteType.flutter,
              routeName: '/settings',
              path: '/settings',
              fields: [],
            ),
          ],
        ),
        typeGraph: {},
        schemaFingerprint: 'testfp',
      );

      // Regression: `[` + `]` is an empty *array* literal, which does not
      // compile as `[String: String]`.
      expect(
        output,
        contains('func toDict() -> [String: String] {\n        [:]\n    }'),
      );
    });

    test('optional fields get an init with nil defaults', () {
      final output = generateSwiftRoutes(
        schema: schemaWithRoute(),
        typeGraph: {},
        schemaFingerprint: 'testfp',
      );

      // The synthesized memberwise init would force callers to pass `note:`.
      expect(
        output,
        contains('        name: String,\n        note: String? = nil\n    ) {'),
      );
      expect(output, contains('        self.note = note'));
    });

    test('uses the cross-platform character set, not urlQueryAllowed', () {
      final output = generateSwiftRoutes(
        schema: schemaWithRoute(),
        typeGraph: {},
        schemaFingerprint: 'testfp',
      );

      // Regression: .urlQueryAllowed leaves & and = unencoded inside values;
      // .urlPathAllowed leaves / unencoded.
      expect(output, isNot(contains('urlQueryAllowed')));
      expect(output, isNot(contains('urlPathAllowed')));
      expect(output, contains('_inlayEncode(name)'));
      expect(output, contains('_inlayEncode(noteVal)'));
      expect(
        output,
        contains(
          '"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_.~!*\'()"',
        ),
      );
    });
  });
}
