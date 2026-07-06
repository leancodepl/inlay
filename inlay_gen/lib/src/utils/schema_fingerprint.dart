import 'package:inlay_gen/src/models/schema.dart';
import 'package:inlay_gen/src/models/type_info.dart';

/// Computes a stable fingerprint of the wire contract described by [schema].
///
/// The generated Dart compiles into the Flutter module while the generated
/// Kotlin/Swift compile into the native hosts, so the two sides can be built
/// from different schema revisions. Serialization is positional, which makes
/// such drift a silent-corruption or crash risk. The fingerprint is emitted
/// as a constant into every language's output; the host registers its copy
/// with `InlayNavigator.setSchemaFingerprint(...)` and the Dart side checks
/// it at engine startup via `InlayNavigator.verifySchemaFingerprint(...)`.
///
/// The fingerprint covers everything that affects the wire format: route
/// ids, path templates, field order/names/types/nullability, store keys,
/// data-class shapes, and enum value order (values travel as ordinals).
/// Declaration order of routes/stores/types does not affect it.
String computeSchemaFingerprint(Schema schema) {
  final buffer = StringBuffer();

  void writeFields(List<FieldInfo> fields) {
    for (final field in fields) {
      buffer.write('${field.name}:${field.type.toSource()};');
    }
  }

  for (final route in [
    ...schema.allRoutes,
  ]..sort((a, b) => a.routeName.compareTo(b.routeName))) {
    buffer.write(
      'route ${route.routeName} path=${route.path} '
      'result=${route.resultType?.toSource()}(',
    );
    writeFields(route.fields);
    buffer.write(')\n');
  }

  for (final store in [
    ...schema.stores,
  ]..sort((a, b) => a.storeKey.compareTo(b.storeKey))) {
    buffer.write('store ${store.storeKey}(');
    writeFields(store.allFields);
    buffer.write(')\n');
  }

  for (final dataClass in [
    ...schema.dataClasses,
  ]..sort((a, b) => a.className.compareTo(b.className))) {
    buffer.write('class ${dataClass.className}(');
    writeFields(dataClass.fields);
    buffer.write(')\n');
  }

  for (final enumDef in [
    ...schema.enums,
  ]..sort((a, b) => a.name.compareTo(b.name))) {
    buffer.write('enum ${enumDef.name}(${enumDef.values.join(',')})\n');
  }

  return _fnv1a64(buffer.toString());
}

/// FNV-1a 64-bit over the UTF-16 code units, returned as 16 hex chars.
///
/// Uses BigInt so the arithmetic is identical on every Dart platform.
String _fnv1a64(String input) {
  final prime = BigInt.parse('100000001b3', radix: 16);
  final mask = (BigInt.one << 64) - BigInt.one;
  var hash = BigInt.parse('cbf29ce484222325', radix: 16);
  for (final codeUnit in input.codeUnits) {
    hash = hash ^ BigInt.from(codeUnit);
    hash = (hash * prime) & mask;
  }
  return hash.toRadixString(16).padLeft(16, '0');
}
