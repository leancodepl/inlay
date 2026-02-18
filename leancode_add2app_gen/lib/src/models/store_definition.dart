import 'package:leancode_add2app_gen/src/models/type_info.dart';

class StoreDefinition {
  const StoreDefinition({
    required this.className,
    required this.storeKey,
    required this.keyFields,
    required this.valueFields,
  });

  final String className;
  final String storeKey;
  final List<FieldInfo> keyFields;
  final List<FieldInfo> valueFields;

  FieldInfo? get keyField => keyFields.isEmpty ? null : keyFields.first;
  List<FieldInfo> get allFields => [...keyFields, ...valueFields];
}
