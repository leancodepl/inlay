import 'package:leancode_add2app_gen/src/models/type_info.dart';
import 'package:leancode_add2app_gen/src/parser/type_resolver.dart';

/// Swift's closure shorthand argument ($0, $1, etc.)
const _swiftArg0 = r'$0';
const _swiftArg1 = r'$1';

/// Maps Dart types to Swift types.
String dartTypeToSwift(TypeInfo type) {
  final baseName = type.baseName;
  String swiftType;

  switch (baseName) {
    case 'bool':
      swiftType = 'Bool';
    case 'int':
      swiftType = 'Int64';
    case 'double':
      swiftType = 'Double';
    case 'num':
      swiftType = 'NSNumber';
    case 'String':
      swiftType = 'String';
    case 'Uint8List':
      swiftType = 'FlutterStandardTypedData';
    case 'List':
      if (type.typeArguments.isNotEmpty) {
        swiftType = '[${dartTypeToSwift(type.typeArguments.first)}]';
      } else {
        swiftType = '[Any?]';
      }
    case 'Map':
      if (type.typeArguments.length == 2) {
        swiftType =
            '[${dartTypeToSwift(type.typeArguments[0])}: ${dartTypeToSwift(type.typeArguments[1])}]';
      } else {
        swiftType = '[AnyHashable: Any?]';
      }
    default:
      swiftType = baseName; // Custom type.
  }

  if (type.isNullable) {
    swiftType = '$swiftType?';
  }
  return swiftType;
}

/// Generates Swift code for encoding a value to a list element.
String generateSwiftEncode(
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
    final nonNullEncode = generateSwiftEncode(
      _swiftArg0,
      nonNullType,
      typeGraph,
    );
    return '$value.map { $nonNullEncode }';
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
    final elementEncode = generateSwiftEncode(
      _swiftArg0,
      elementType,
      typeGraph,
    );
    return '$value.map { $elementEncode }';
  }

  // Map<K, V>.
  if (baseName == 'Map' && type.typeArguments.length == 2) {
    final keyType = type.typeArguments[0];
    final valueType = type.typeArguments[1];
    if (_isPrimitive(keyType.baseName) && _isPrimitive(valueType.baseName)) {
      return value;
    }
    final valueEncode = generateSwiftEncode(_swiftArg1, valueType, typeGraph);
    return '$value.mapValues { $valueEncode }';
  }

  // Enum - encode as index.
  if (typeGraph[baseName] is EnumType) {
    return '$value.rawValue';
  }

  // Custom class - call toList().
  if (typeGraph.containsKey(baseName)) {
    return '$value.toList()';
  }

  return value;
}

/// Generates Swift code for decoding a value from a list element.
String generateSwiftDecode(
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

    // For primitives, use simple optional casting.
    if (_isPrimitive(baseName)) {
      return '$expression as? ${dartTypeToSwift(nonNullType)}';
    }

    if (baseName == 'Uint8List') {
      return '$expression as? FlutterStandardTypedData';
    }

    if (baseName == 'List' && type.typeArguments.isNotEmpty) {
      final elementType = type.typeArguments.first;
      if (_isPrimitive(elementType.baseName) && !elementType.isNullable) {
        final swiftElementType = dartTypeToSwift(elementType);
        return '($expression as? [Any?])?.map { \$0 as! $swiftElementType }';
      }
      final elementDecode = generateSwiftDecode(
        _swiftArg0,
        elementType,
        typeGraph,
      );
      return '($expression as? [Any?])?.map { $elementDecode }';
    }

    if (baseName == 'Map' && type.typeArguments.length == 2) {
      final keyType = type.typeArguments[0];
      final valueType = type.typeArguments[1];
      final swiftKeyType = dartTypeToSwift(keyType);
      final swiftValueType = dartTypeToSwift(valueType);

      if (_isPrimitive(keyType.baseName) && _isPrimitive(valueType.baseName)) {
        return '($expression as? [AnyHashable: Any?]).map { source in source.reduce(into: [$swiftKeyType: $swiftValueType]()) { dict, pair in dict[pair.key as! $swiftKeyType] = pair.value as? $swiftValueType } }';
      }

      final valueDecode = generateSwiftDecode(_swiftArg1, valueType, typeGraph);
      return '($expression as? [AnyHashable: Any?]).map { source in source.mapValues { $valueDecode } }';
    }

    if (typeGraph[baseName] is EnumType) {
      return '($expression as? Int).flatMap { $baseName(rawValue: \$0) }';
    }

    if (typeGraph.containsKey(baseName)) {
      return '($expression as? [Any?]).map { $baseName.fromList(\$0) }';
    }

    return '$expression as? ${dartTypeToSwift(nonNullType)}';
  }

  // Primitives.
  if (_isPrimitive(baseName)) {
    final swiftType = dartTypeToSwift(type);
    return '$expression as! $swiftType';
  }

  // Uint8List.
  if (baseName == 'Uint8List') {
    return '$expression as! FlutterStandardTypedData';
  }

  // List<T>.
  if (baseName == 'List' && type.typeArguments.isNotEmpty) {
    final elementType = type.typeArguments.first;
    if (_isPrimitive(elementType.baseName) && !elementType.isNullable) {
      final swiftElementType = dartTypeToSwift(elementType);
      return r'($expression as! [Any?]).map { $0 as! $swiftElementType }'
          .replaceAll(r'$expression', expression)
          .replaceAll(r'$swiftElementType', swiftElementType);
    }
    final elementDecode = generateSwiftDecode(
      _swiftArg0,
      elementType,
      typeGraph,
    );
    return '($expression as! [Any?]).map { $elementDecode }';
  }

  // Map<K, V>.
  if (baseName == 'Map' && type.typeArguments.length == 2) {
    final keyType = type.typeArguments[0];
    final valueType = type.typeArguments[1];
    final swiftKeyType = dartTypeToSwift(keyType);
    final swiftValueType = dartTypeToSwift(valueType);
    if (_isPrimitive(keyType.baseName) && _isPrimitive(valueType.baseName)) {
      return '($expression as! [AnyHashable: Any?]).reduce(into: [$swiftKeyType: $swiftValueType]()) { dict, pair in dict[pair.key as! $swiftKeyType] = pair.value as? $swiftValueType }';
    }
    final valueDecode = generateSwiftDecode(_swiftArg1, valueType, typeGraph);
    return '($expression as! [AnyHashable: Any?]).mapValues { $valueDecode }';
  }

  // Enum.
  if (typeGraph[baseName] is EnumType) {
    return '$baseName(rawValue: $expression as! Int)!';
  }

  // Custom class.
  if (typeGraph.containsKey(baseName)) {
    return '$baseName.fromList($expression as! [Any?])';
  }

  final swiftType = dartTypeToSwift(type);
  return '$expression as! $swiftType';
}

/// Generates toList() method body for a Swift struct.
String generateSwiftToListMethod(
  List<FieldInfo> fields,
  Map<String, TypeDefinition> typeGraph,
) {
  if (fields.isEmpty) {
    return 'func toList() -> [Any?] { [] }';
  }

  final buffer = StringBuffer()
    ..writeln('func toList() -> [Any?] {')
    ..writeln('        [');

  for (final field in fields) {
    final encode = generateSwiftEncode(field.name, field.type, typeGraph);
    buffer.writeln('            $encode,');
  }

  buffer
    ..writeln('        ]')
    ..write('    }');
  return buffer.toString();
}

/// Generates fromList() static method for a Swift struct.
String generateSwiftFromListMethod(
  String structName,
  List<FieldInfo> fields,
  Map<String, TypeDefinition> typeGraph,
) {
  final buffer = StringBuffer()
    ..writeln('static func fromList(_ list: [Any?]) -> $structName {')
    ..writeln('        $structName(');

  for (var i = 0; i < fields.length; i++) {
    final field = fields[i];
    final decode = generateSwiftDecode('list[$i]', field.type, typeGraph);
    final comma = i < fields.length - 1 ? ',' : '';
    buffer.writeln('            ${field.name}: $decode$comma');
  }

  buffer
    ..writeln('        )')
    ..write('    }');
  return buffer.toString();
}

bool _isPrimitive(String typeName) {
  return const {'bool', 'int', 'double', 'num', 'String'}.contains(typeName);
}
