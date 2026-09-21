import 'package:inlay_gen/src/models/type_info.dart';
import 'package:inlay_gen/src/parser/type_resolver.dart';

/// Maps Dart types to (boxed) Java types.
///
/// Boxed types are used everywhere so that nullable Dart fields have a
/// natural `null` representation and so the same type can be used for
/// generics (`List<Long>`), fields and result values alike.
String dartTypeToJava(TypeInfo type) {
  final baseName = type.baseName;

  return switch (baseName) {
    'bool' => 'Boolean',
    'int' => 'Long',
    'double' => 'Double',
    'num' => 'Number',
    'String' => 'String',
    'Uint8List' => 'byte[]',
    'List' when type.typeArguments.isNotEmpty =>
      'List<${dartTypeToJava(type.typeArguments.first)}>',
    'List' => 'List<Object>',
    'Map' when type.typeArguments.length == 2 =>
      'Map<${dartTypeToJava(type.typeArguments[0])}, ${dartTypeToJava(type.typeArguments[1])}>',
    'Map' => 'Map<Object, Object>',
    _ => baseName, // Custom type.
  };
}

/// Generates the Java expression that encodes [value] into its wire form.
///
/// Returns [value] unchanged when the type travels as-is through
/// `StandardMessageCodec` (primitives, byte arrays, collections of them).
String generateJavaEncode(
  String value,
  TypeInfo type,
  Map<String, TypeDefinition> typeGraph,
) {
  final baseName = type.baseName;

  if (type.isNullable) {
    final inner = generateJavaEncode(value, type.toNonNullable(), typeGraph);
    return inner == value ? value : '$value == null ? null : $inner';
  }

  // Primitives and Uint8List - pass through.
  if (_isPrimitive(baseName) || baseName == 'Uint8List') {
    return value;
  }

  // List<T>.
  if (baseName == 'List' && type.typeArguments.isNotEmpty) {
    final elementEncode = generateJavaEncode(
      'it',
      type.typeArguments.first,
      typeGraph,
    );
    if (elementEncode == 'it') {
      return value;
    }
    return '$value.stream().map(it -> $elementEncode).collect(Collectors.toList())';
  }

  // Map<K, V>.
  if (baseName == 'Map' && type.typeArguments.length == 2) {
    final keyEncode = generateJavaEncode(
      'e.getKey()',
      type.typeArguments[0],
      typeGraph,
    );
    final valueEncode = generateJavaEncode(
      'e.getValue()',
      type.typeArguments[1],
      typeGraph,
    );
    if (keyEncode == 'e.getKey()' && valueEncode == 'e.getValue()') {
      return value;
    }
    // Collectors.toMap rejects null values, so collect into a HashMap by hand.
    return '$value.entrySet().stream().collect(HashMap::new, (m, e) -> m.put($keyEncode, $valueEncode), HashMap::putAll)';
  }

  // Enum - encode as ordinal.
  if (typeGraph[baseName] is EnumType) {
    return '$value.ordinal()';
  }

  // Custom class - call toList().
  if (typeGraph.containsKey(baseName)) {
    return '$value.toList()';
  }

  return value;
}

/// Generates the Java expression that decodes the wire value [expression]
/// into the Java type for [type].
///
/// Like the Kotlin output, numeric decodes go through `Number`:
/// `StandardMessageCodec` delivers integers as `Integer` or `Long`
/// depending on magnitude, so a direct `(Long)` cast would throw for small
/// values. Enums arrive as ordinals and custom classes as lists.
///
/// [expression] may be evaluated more than once (null checks), so it must be
/// side-effect free - e.g. `list.get(0)`.
String generateJavaDecode(
  String expression,
  TypeInfo type,
  Map<String, TypeDefinition> typeGraph,
) {
  final baseName = type.baseName;

  if (type.isNullable) {
    final inner = generateJavaDecode(
      expression,
      type.toNonNullable(),
      typeGraph,
    );
    return '$expression == null ? null : $inner';
  }

  if (_isPrimitive(baseName)) {
    return switch (baseName) {
      'int' => '((Number) $expression).longValue()',
      'double' => '((Number) $expression).doubleValue()',
      'num' => '(Number) $expression',
      _ => '(${dartTypeToJava(type)}) $expression',
    };
  }

  if (baseName == 'Uint8List') {
    return '(byte[]) $expression';
  }

  // List<T>.
  if (baseName == 'List' && type.typeArguments.isNotEmpty) {
    final elementType = type.typeArguments.first;
    final elementDecode = generateJavaDecode('it', elementType, typeGraph);
    if (elementDecode == _plainCast(elementType, 'it')) {
      // Elements arrive in their final shape (String, Boolean, byte[]...).
      return _plainCast(type, expression);
    }
    return '((List<Object>) $expression).stream().map(it -> $elementDecode).collect(Collectors.toList())';
  }

  // Map<K, V>.
  if (baseName == 'Map' && type.typeArguments.length == 2) {
    final keyType = type.typeArguments[0];
    final valueType = type.typeArguments[1];
    final keyDecode = generateJavaDecode('e.getKey()', keyType, typeGraph);
    final valueDecode = generateJavaDecode(
      'e.getValue()',
      valueType,
      typeGraph,
    );
    if (keyDecode == _plainCast(keyType, 'e.getKey()') &&
        valueDecode == _plainCast(valueType, 'e.getValue()')) {
      return _plainCast(type, expression);
    }
    // Collectors.toMap rejects null values, so collect into a HashMap by hand.
    return '((Map<Object, Object>) $expression).entrySet().stream().collect(HashMap::new, (m, e) -> m.put($keyDecode, $valueDecode), HashMap::putAll)';
  }

  // Enum.
  if (typeGraph[baseName] is EnumType) {
    return '$baseName.values()[((Number) $expression).intValue()]';
  }

  // Custom class.
  if (typeGraph.containsKey(baseName)) {
    return '$baseName.fromList((List<Object>) $expression)';
  }

  return _plainCast(type, expression);
}

/// Generates the `toList()` method of a Java class.
String generateJavaToListMethod(
  List<FieldInfo> fields,
  Map<String, TypeDefinition> typeGraph,
) {
  if (fields.isEmpty) {
    return 'public List<Object> toList() {\n'
        '        return Collections.emptyList();\n'
        '    }';
  }

  final buffer = StringBuffer()
    ..writeln('public List<Object> toList() {')
    ..writeln('        return Arrays.asList(');

  for (var i = 0; i < fields.length; i++) {
    final field = fields[i];
    final encode = generateJavaEncode(field.name, field.type, typeGraph);
    final comma = i < fields.length - 1 ? ',' : '';
    buffer.writeln('                $encode$comma');
  }

  buffer
    ..writeln('        );')
    ..write('    }');
  return buffer.toString();
}

/// Generates the static `fromList()` factory of a Java class.
///
/// Annotated with `@SuppressWarnings("unchecked")`: the wire format is an
/// untyped `List<Object>`, so nested lists and maps are cast without checks.
String generateJavaFromListMethod(
  String className,
  List<FieldInfo> fields,
  Map<String, TypeDefinition> typeGraph,
) {
  if (fields.isEmpty) {
    return 'public static $className fromList(List<Object> list) {\n'
        '        return new $className();\n'
        '    }';
  }

  final buffer = StringBuffer()
    ..writeln('@SuppressWarnings("unchecked")')
    ..writeln('    public static $className fromList(List<Object> list) {')
    ..writeln('        return new $className(');

  for (var i = 0; i < fields.length; i++) {
    final field = fields[i];
    final decode = generateJavaDecode('list.get($i)', field.type, typeGraph);
    final comma = i < fields.length - 1 ? ',' : '';
    buffer.writeln('                $decode$comma');
  }

  buffer
    ..writeln('        );')
    ..write('    }');
  return buffer.toString();
}

String _plainCast(TypeInfo type, String expression) =>
    '(${dartTypeToJava(type.toNonNullable())}) $expression';

bool _isPrimitive(String typeName) {
  return const {'bool', 'int', 'double', 'num', 'String'}.contains(typeName);
}
