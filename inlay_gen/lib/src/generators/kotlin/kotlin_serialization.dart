import 'package:inlay_gen/src/models/type_info.dart';
import 'package:inlay_gen/src/parser/type_resolver.dart';

/// Maps Dart types to Kotlin types.
String dartTypeToKotlin(TypeInfo type) {
  final baseName = type.baseName;
  String kotlinType;

  switch (baseName) {
    case 'bool':
      kotlinType = 'Boolean';
    case 'int':
      kotlinType = 'Long';
    case 'double':
      kotlinType = 'Double';
    case 'num':
      kotlinType = 'Number';
    case 'String':
      kotlinType = 'String';
    case 'Uint8List':
      kotlinType = 'ByteArray';
    case 'List':
      if (type.typeArguments.isNotEmpty) {
        kotlinType = 'List<${dartTypeToKotlin(type.typeArguments.first)}>';
      } else {
        kotlinType = 'List<Any?>';
      }
    case 'Map':
      if (type.typeArguments.length == 2) {
        kotlinType =
            'Map<${dartTypeToKotlin(type.typeArguments[0])}, ${dartTypeToKotlin(type.typeArguments[1])}>';
      } else {
        kotlinType = 'Map<Any?, Any?>';
      }
    default:
      kotlinType = baseName; // Custom type.
  }

  if (type.isNullable) {
    kotlinType = '$kotlinType?';
  }
  return kotlinType;
}

/// Generates Kotlin code for encoding a value to a list element.
String generateKotlinEncode(
  String value,
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
    return '$value?.let { ${generateKotlinEncode('it', nonNullType, typeGraph)} }';
  }

  // Primitives - pass through.
  if (_isPrimitive(baseName)) {
    return value;
  }

  // Uint8List.
  if (baseName == 'Uint8List') {
    return value;
  }

  // List<T>.
  if (baseName == 'List' && type.typeArguments.isNotEmpty) {
    final elementType = type.typeArguments.first;
    if (_isPrimitive(elementType.baseName) && !elementType.isNullable) {
      return value;
    }
    final elementEncode = generateKotlinEncode('it', elementType, typeGraph);
    return '$value.map { $elementEncode }';
  }

  // Map<K, V>.
  if (baseName == 'Map' && type.typeArguments.length == 2) {
    final keyType = type.typeArguments[0];
    final valueType = type.typeArguments[1];
    if (_isPrimitive(keyType.baseName) && _isPrimitive(valueType.baseName)) {
      return value;
    }
    final valueEncode = generateKotlinEncode('v', valueType, typeGraph);
    return '$value.mapValues { (_, v) -> $valueEncode }';
  }

  // Enum - encode as index.
  if (typeGraph[baseName] is EnumType) {
    return '$value.ordinal';
  }

  // Custom class - call toList().
  if (typeGraph.containsKey(baseName)) {
    return '$value.toList()';
  }

  return value;
}

/// Generates Kotlin code for decoding a value from a list element.
String generateKotlinDecode(
  String expression,
  TypeInfo type,
  Map<String, TypeDefinition> typeGraph,
) {
  final baseName = type.baseName;
  final kotlinType = dartTypeToKotlin(
    TypeInfo(
      name: baseName,
      isNullable: false,
      typeArguments: type.typeArguments,
    ),
  );

  // Handle nullable. Casts check against the *wire* type (what the codec
  // actually delivers), not the decoded Kotlin type - e.g. an enum arrives
  // as an ordinal number, a custom class as a List.
  if (type.isNullable) {
    if (baseName == 'int') {
      return '($expression as? Number)?.toLong()';
    }
    if (baseName == 'double') {
      return '($expression as? Number)?.toDouble()';
    }
    if (baseName == 'num') {
      return '$expression as? Number';
    }
    if (typeGraph[baseName] is EnumType) {
      return '($expression as? Number)?.let { $baseName.entries[it.toInt()] }';
    }
    final nonNullType = TypeInfo(
      name: baseName,
      isNullable: false,
      typeArguments: type.typeArguments,
    );
    final nonNullDecode = generateKotlinDecode('it', nonNullType, typeGraph);
    return '($expression as? ${_rawKotlinCast(type, typeGraph)})?.let { $nonNullDecode }';
  }

  // Primitives. Integers travel as Int32 or Int64 depending on magnitude
  // (StandardMessageCodec), so numeric decodes go through Number.
  if (_isPrimitive(baseName)) {
    return switch (baseName) {
      'int' => '($expression as Number).toLong()',
      'double' => '($expression as Number).toDouble()',
      'num' => '$expression as Number',
      _ => '$expression as $kotlinType',
    };
  }

  // Uint8List.
  if (baseName == 'Uint8List') {
    return '$expression as ByteArray';
  }

  // List<T>.
  if (baseName == 'List' && type.typeArguments.isNotEmpty) {
    final elementType = type.typeArguments.first;
    if (_isPrimitive(elementType.baseName) && !elementType.isNullable) {
      return '($expression as List<*>).filterIsInstance<${dartTypeToKotlin(elementType)}>()';
    }
    final elementDecode = generateKotlinDecode('it', elementType, typeGraph);
    return '($expression as List<*>).map { $elementDecode }';
  }

  // Map<K, V>.
  if (baseName == 'Map' && type.typeArguments.length == 2) {
    final keyType = type.typeArguments[0];
    final valueType = type.typeArguments[1];
    final keyKotlin = dartTypeToKotlin(keyType);
    final valueKotlin = dartTypeToKotlin(valueType);
    if (_isPrimitive(keyType.baseName) && _isPrimitive(valueType.baseName)) {
      return '@Suppress("UNCHECKED_CAST") ($expression as Map<$keyKotlin, $valueKotlin>)';
    }
    final valueDecode = generateKotlinDecode('v', valueType, typeGraph);
    return '@Suppress("UNCHECKED_CAST") ($expression as Map<*, *>).mapValues { (_, v) -> $valueDecode }';
  }

  // Enum.
  if (typeGraph[baseName] is EnumType) {
    return '$baseName.entries[($expression as Number).toInt()]';
  }

  // Custom class.
  if (typeGraph.containsKey(baseName)) {
    return '$baseName.fromList($expression as List<Any?>)';
  }

  return '$expression as $kotlinType';
}

/// Generates toList() method body for a Kotlin data class.
String generateKotlinToListMethod(
  List<FieldInfo> fields,
  Map<String, TypeDefinition> typeGraph,
) {
  if (fields.isEmpty) {
    return 'fun toList(): List<Any?> = emptyList()';
  }

  final buffer = StringBuffer()..writeln('fun toList(): List<Any?> = listOf(');

  for (final field in fields) {
    final encode = generateKotlinEncode(field.name, field.type, typeGraph);
    buffer.writeln('        $encode,');
  }

  buffer.write('    )');
  return buffer.toString();
}

/// Generates fromList() companion method for a Kotlin data class.
String generateKotlinFromListMethod(
  String className,
  List<FieldInfo> fields,
  Map<String, TypeDefinition> typeGraph,
) {
  final buffer = StringBuffer()
    ..writeln('fun fromList(list: List<Any?>): $className = $className(');

  for (var i = 0; i < fields.length; i++) {
    final field = fields[i];
    final decode = generateKotlinDecode('list[$i]', field.type, typeGraph);
    buffer.writeln('            ${field.name} = $decode,');
  }

  buffer.write('        )');
  return buffer.toString();
}

bool _isPrimitive(String typeName) {
  return const {'bool', 'int', 'double', 'num', 'String'}.contains(typeName);
}

/// The type to safe-cast against for nullable decodes: the shape the codec
/// delivers on the wire, not the final Kotlin type.
String _rawKotlinCast(TypeInfo type, Map<String, TypeDefinition> typeGraph) {
  final baseName = type.baseName;

  if (typeGraph.containsKey(baseName)) {
    // Enums travel as ordinal numbers, custom classes as lists.
    return typeGraph[baseName] is EnumType ? 'Number' : 'List<*>';
  }

  switch (baseName) {
    case 'List':
      return 'List<*>';
    case 'Map':
      return 'Map<*, *>';
    case 'int':
    case 'double':
    case 'num':
      return 'Number';
    default:
      return dartTypeToKotlin(
        TypeInfo(
          name: baseName,
          isNullable: false,
          typeArguments: type.typeArguments,
        ),
      );
  }
}
