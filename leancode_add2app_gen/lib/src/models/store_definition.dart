import 'package:leancode_add2app_gen/src/models/type_info.dart';

class StoreDefinition {
  const StoreDefinition({
    required this.className,
    required this.storeKey,
    required this.scopeFields,
    required this.valueFields,
  });

  final String className;
  final String storeKey;
  final List<FieldInfo> scopeFields;
  final List<FieldInfo> valueFields;

  List<FieldInfo> get allFields => [...scopeFields, ...valueFields];
}
