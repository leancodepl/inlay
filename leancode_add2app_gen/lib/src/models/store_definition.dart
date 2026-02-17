import 'package:leancode_add2app_gen/src/models/type_info.dart';

/// A parsed store class from the schema file.
class StoreDefinition {
  const StoreDefinition({
    required this.className,
    required this.storeKey,
    required this.scopeFields,
    required this.valueFields,
  });

  /// The class name (e.g., `SoundsNotificationsStore`).
  final String className;

  /// The storage key prefix.
  /// Either explicitly provided in the annotation or derived from class name.
  final String storeKey;

  /// Scope fields - required constructor params used in key prefix, not stored.
  /// Example: `contactId` for per-contact storage.
  final List<FieldInfo> scopeFields;

  /// Value fields - the actual stored values with their defaults.
  final List<FieldInfo> valueFields;

  /// All fields (scope + value).
  List<FieldInfo> get allFields => [...scopeFields, ...valueFields];

  @override
  String toString() =>
      'StoreDefinition($className, '
      'key: $storeKey, '
      'scopes: [${scopeFields.map((f) => f.name).join(', ')}], '
      'values: [${valueFields.map((f) => f.name).join(', ')}])';
}
