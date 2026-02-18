import 'package:leancode_add2app_gen/src/models/type_info.dart';
import 'package:leancode_add2app_gen/src/parser/type_resolver.dart';

/// Generates Dart code for encoding a value to a serializable form.
///
/// [value] is the expression to encode.
/// [type] is the type information.
/// [typeGraph] is the resolved type graph for looking up custom types.
String generateDartEncode(
  String value,
  TypeInfo type,
  Map<String, TypeDefinition> typeGraph,
) {
  final baseName = type.baseName;

  // Handle nullable - wrap in null check.
  if (type.isNullable) {
    final nonNullType = TypeInfo(
      name: baseName,
      isNullable: false,
      typeArguments: type.typeArguments,
    );
    return '$value != null ? ${generateDartEncode('$value!', nonNullType, typeGraph)} : null';
  }

  // Primitives - pass through directly.
  if (_isPrimitive(baseName)) {
    return value;
  }

  // Uint8List - pass through.
  if (baseName == 'Uint8List') {
    return value;
  }

  // List<T> - map each element.
  if (baseName == 'List' && type.typeArguments.isNotEmpty) {
    final elementType = type.typeArguments.first;
    if (_isPrimitive(elementType.baseName) && !elementType.isNullable) {
      // List of primitives - pass through.
      return value;
    }
    final elementEncode = generateDartEncode('e', elementType, typeGraph);
    return '$value.map((e) => $elementEncode).toList()';
  }

  // Map<K, V> - encode values if needed.
  if (baseName == 'Map' && type.typeArguments.length == 2) {
    final keyType = type.typeArguments[0];
    final valueType = type.typeArguments[1];
    if (_isPrimitive(keyType.baseName) && _isPrimitive(valueType.baseName)) {
      // Map of primitives - pass through.
      return value;
    }
    final valueEncode = generateDartEncode('v', valueType, typeGraph);
    return '$value.map((k, v) => MapEntry(k, $valueEncode))';
  }

  // Enum - encode as index.
  if (typeGraph[baseName] is EnumType) {
    return '$value.index';
  }

  // Custom class - call encode().
  if (typeGraph.containsKey(baseName)) {
    return '$value.encode()';
  }

  // Fallback - pass through (Object, dynamic).
  return value;
}

/// Generates Dart code for decoding a value from serialized form.
///
/// [expression] is the expression to decode (usually a list index like `list[0]`).
/// [type] is the target type.
/// [typeGraph] is the resolved type graph.
String generateDartDecode(
  String expression,
  TypeInfo type,
  Map<String, TypeDefinition> typeGraph,
) {
  final baseName = type.baseName;

  // Handle nullable.
  if (type.isNullable) {
    final nonNullType = TypeInfo(
      name: baseName,
      isNullable: false,
      typeArguments: type.typeArguments,
    );
    final nonNullDecode = generateDartDecode('v', nonNullType, typeGraph);

    // For simple types, we can use a simpler expression.
    if (_isPrimitive(baseName) || baseName == 'Uint8List') {
      return '$expression as ${type.toSource()}';
    }

    return '($expression as ${_rawType(type)}) != null ? '
        '(() { final v = $expression; return $nonNullDecode; })() : null';
  }

  // Primitives - direct cast.
  if (_isPrimitive(baseName)) {
    return '$expression as $baseName';
  }

  // Uint8List - direct cast.
  if (baseName == 'Uint8List') {
    return '$expression as Uint8List';
  }

  // List<T> - decode each element.
  if (baseName == 'List' && type.typeArguments.isNotEmpty) {
    final elementType = type.typeArguments.first;
    if (_isPrimitive(elementType.baseName) && !elementType.isNullable) {
      // List of primitives - cast to List<T>.
      return '($expression as List<Object?>).cast<${elementType.toSource()}>()';
    }
    final elementDecode = generateDartDecode('e', elementType, typeGraph);
    return '($expression as List<Object?>).map((e) => $elementDecode).toList()';
  }

  // Map<K, V>.
  if (baseName == 'Map' && type.typeArguments.length == 2) {
    final keyType = type.typeArguments[0];
    final valueType = type.typeArguments[1];
    if (_isPrimitive(keyType.baseName) && _isPrimitive(valueType.baseName)) {
      return '($expression as Map<Object?, Object?>).cast<${keyType.toSource()}, ${valueType.toSource()}>()';
    }
    final valueDecode = generateDartDecode('v', valueType, typeGraph);
    return '($expression as Map<Object?, Object?>).map((k, v) => '
        'MapEntry(k as ${keyType.toSource()}, $valueDecode))';
  }

  // Enum - decode from index.
  if (typeGraph[baseName] is EnumType) {
    return '$baseName.values[$expression as int]';
  }

  // Custom class - call decode().
  if (typeGraph.containsKey(baseName)) {
    return '$baseName.decode($expression as List<Object?>)';
  }

  // Fallback.
  return '$expression as $baseName';
}

/// Generates encode() method body for a class with given fields.
String generateDartEncodeMethod(
  List<FieldInfo> fields,
  Map<String, TypeDefinition> typeGraph,
) {
  if (fields.isEmpty) {
    return 'List<Object?> encode() => <Object?>[];';
  }

  final buffer = StringBuffer()..writeln('List<Object?> encode() => <Object?>[');

  for (final field in fields) {
    final encode = generateDartEncode(field.name, field.type, typeGraph);
    buffer.writeln('    $encode,');
  }

  buffer.write('  ]');
  return buffer.toString();
}

/// Generates decode() static method for a class.
String generateDartDecodeMethod(
  String className,
  List<FieldInfo> fields,
  Map<String, TypeDefinition> typeGraph,
) {
  final buffer = StringBuffer()
    ..writeln('static $className decode(List<Object?> list) {');

  if (fields.isEmpty) {
    buffer.writeln('    return $className();');
  } else {
    buffer.writeln('    return $className(');

    for (var i = 0; i < fields.length; i++) {
      final field = fields[i];
      final decode = generateDartDecode('list[$i]', field.type, typeGraph);
      buffer.writeln('      ${field.name}: $decode,');
    }

    buffer.writeln('    );');
  }

  buffer.write('  }');
  return buffer.toString();
}

bool _isPrimitive(String typeName) {
  return const {'bool', 'int', 'double', 'num', 'String'}.contains(typeName);
}

/// Returns the raw (non-nullable) representation of a nullable type for casting.
String _rawType(TypeInfo type) {
  if (type.typeArguments.isEmpty) {
    return '${type.baseName}?';
  }
  return '${type.baseName}<${type.typeArguments.map((t) => t.toSource()).join(', ')}>?';
}
