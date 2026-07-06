import 'package:inlay_gen/src/models/data_type_definition.dart';
import 'package:inlay_gen/src/models/route_definition.dart';
import 'package:inlay_gen/src/models/schema.dart';
import 'package:inlay_gen/src/models/type_info.dart';
import 'package:inlay_gen/src/utils/schema_fingerprint.dart';
import 'package:test/test.dart';

void main() {
  RouteDefinition route(String name, List<FieldInfo> fields) => RouteDefinition(
    className: name,
    routeType: RouteType.flutter,
    routeName: '/$name',
    path: '/$name',
    fields: fields,
  );

  const stringField = FieldInfo(
    name: 'id',
    type: TypeInfo(name: 'String', isNullable: false),
    isRequired: true,
  );
  const intField = FieldInfo(
    name: 'count',
    type: TypeInfo(name: 'int', isNullable: true),
    isRequired: false,
  );

  group('computeSchemaFingerprint', () {
    test('is stable for the same schema', () {
      final a = Schema(
        flutterRoutes: [
          route('a', [stringField, intField]),
        ],
      );
      final b = Schema(
        flutterRoutes: [
          route('a', [stringField, intField]),
        ],
      );

      expect(computeSchemaFingerprint(a), computeSchemaFingerprint(b));
    });

    test('ignores route declaration order', () {
      final a = Schema(
        flutterRoutes: [
          route('a', [stringField]),
          route('b', [intField]),
        ],
      );
      final b = Schema(
        flutterRoutes: [
          route('b', [intField]),
          route('a', [stringField]),
        ],
      );

      expect(computeSchemaFingerprint(a), computeSchemaFingerprint(b));
    });

    test('changes when a field type changes', () {
      final a = Schema(
        flutterRoutes: [
          route('a', [stringField]),
        ],
      );
      final b = Schema(
        flutterRoutes: [
          route('a', const [
            FieldInfo(
              name: 'id',
              type: TypeInfo(name: 'int', isNullable: false),
              isRequired: true,
            ),
          ]),
        ],
      );

      expect(computeSchemaFingerprint(a), isNot(computeSchemaFingerprint(b)));
    });

    test('changes when field order changes (positional wire format)', () {
      final a = Schema(
        flutterRoutes: [
          route('a', [stringField, intField]),
        ],
      );
      final b = Schema(
        flutterRoutes: [
          route('a', [intField, stringField]),
        ],
      );

      expect(computeSchemaFingerprint(a), isNot(computeSchemaFingerprint(b)));
    });

    test('changes when nullability changes', () {
      final a = Schema(
        flutterRoutes: [
          route('a', [stringField]),
        ],
      );
      final b = Schema(
        flutterRoutes: [
          route('a', const [
            FieldInfo(
              name: 'id',
              type: TypeInfo(name: 'String', isNullable: true),
              isRequired: false,
            ),
          ]),
        ],
      );

      expect(computeSchemaFingerprint(a), isNot(computeSchemaFingerprint(b)));
    });

    test('changes when enum values are reordered (ordinal wire format)', () {
      const a = Schema(
        enums: [
          EnumDefinition(name: 'E', values: ['x', 'y']),
        ],
      );
      const b = Schema(
        enums: [
          EnumDefinition(name: 'E', values: ['y', 'x']),
        ],
      );

      expect(computeSchemaFingerprint(a), isNot(computeSchemaFingerprint(b)));
    });
  });
}
