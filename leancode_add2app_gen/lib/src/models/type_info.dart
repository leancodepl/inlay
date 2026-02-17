/// Represents type information extracted from Dart source.
class TypeInfo {
  const TypeInfo({
    required this.name,
    required this.isNullable,
    this.typeArguments = const [],
  });

  /// The type name (e.g., `String`, `List`, `ContactSettings`).
  final String name;

  /// Whether this type is nullable.
  final bool isNullable;

  /// Type arguments for generic types (e.g., `String` in `List<String>`).
  final List<TypeInfo> typeArguments;

  /// Returns the base type name without nullability or type arguments.
  String get baseName => name;

  /// Whether this is a primitive type (bool, int, double, String).
  bool get isPrimitive =>
      const ['bool', 'int', 'double', 'String', 'num'].contains(name);

  /// Whether this is a List type.
  bool get isList => name == 'List';

  /// Whether this is a Map type.
  bool get isMap => name == 'Map';

  /// Whether this is Uint8List.
  bool get isUint8List => name == 'Uint8List';

  /// Full Dart type string including nullability and type arguments.
  String toSource() {
    final buffer = StringBuffer(name);
    if (typeArguments.isNotEmpty) {
      buffer.write('<');
      buffer.write(typeArguments.map((t) => t.toSource()).join(', '));
      buffer.write('>');
    }
    if (isNullable) {
      buffer.write('?');
    }
    return buffer.toString();
  }

  @override
  String toString() => 'TypeInfo(${toSource()})';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TypeInfo &&
          name == other.name &&
          isNullable == other.isNullable &&
          _listEquals(typeArguments, other.typeArguments);

  @override
  int get hashCode => Object.hash(name, isNullable, Object.hashAll(typeArguments));

  static bool _listEquals(List<TypeInfo> a, List<TypeInfo> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// Information about a field in a class.
class FieldInfo {
  const FieldInfo({
    required this.name,
    required this.type,
    required this.isRequired,
    this.defaultValue,
  });

  /// The field name.
  final String name;

  /// The field type information.
  final TypeInfo type;

  /// Whether this field is required in the constructor.
  final bool isRequired;

  /// Default value expression if present (e.g., `false`, `'Default'`).
  final String? defaultValue;

  /// Whether this field has a default value.
  bool get hasDefault => defaultValue != null;

  @override
  String toString() =>
      'FieldInfo($name: ${type.toSource()}'
      '${isRequired ? ', required' : ''}'
      '${hasDefault ? ', default: $defaultValue' : ''})';
}
