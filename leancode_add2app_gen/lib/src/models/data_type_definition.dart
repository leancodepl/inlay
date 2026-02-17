import 'package:leancode_add2app_gen/src/models/type_info.dart';

/// A parsed data class (non-annotated class used by routes/stores).
class DataClassDefinition {
  const DataClassDefinition({
    required this.className,
    required this.fields,
  });

  /// The class name (e.g., `ContactSettings`).
  final String className;

  /// The fields declared in the class.
  final List<FieldInfo> fields;

  @override
  String toString() =>
      'DataClassDefinition($className, '
      'fields: [${fields.map((f) => f.name).join(', ')}])';
}

/// A parsed enum definition.
class EnumDefinition {
  const EnumDefinition({
    required this.name,
    required this.values,
  });

  /// The enum name (e.g., `MediaType`).
  final String name;

  /// The enum values (e.g., `['image', 'video', 'audio']`).
  final List<String> values;

  @override
  String toString() => 'EnumDefinition($name: [${values.join(', ')}])';
}
