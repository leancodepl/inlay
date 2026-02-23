class TypeInfo {
  const TypeInfo({
    required this.name,
    required this.isNullable,
    this.typeArguments = const [],
  });

  final String name;
  final bool isNullable;
  final List<TypeInfo> typeArguments;

  String get baseName => name;
  bool get isPrimitive =>
      const ['bool', 'int', 'double', 'String', 'num'].contains(name);
  bool get isList => name == 'List';
  bool get isMap => name == 'Map';
  bool get isUint8List => name == 'Uint8List';

  String toSource() {
    final buffer = StringBuffer(name);
    if (typeArguments.isNotEmpty) {
      buffer
        ..write('<')
        ..write(typeArguments.map((t) => t.toSource()).join(', '))
        ..write('>');
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
  int get hashCode =>
      Object.hash(name, isNullable, Object.hashAll(typeArguments));

  static bool _listEquals(List<TypeInfo> a, List<TypeInfo> b) {
    if (a.length != b.length) {
      return false;
    }
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) {
        return false;
      }
    }
    return true;
  }
}

class FieldInfo {
  const FieldInfo({
    required this.name,
    required this.type,
    required this.isRequired,
    this.defaultValue,
    this.isStoreKey = false,
  });

  final String name;
  final TypeInfo type;
  final bool isRequired;
  final String? defaultValue;
  final bool isStoreKey;

  bool get hasDefault => defaultValue != null;
}
