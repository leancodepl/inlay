import 'package:leancode_add2app_gen/src/models/type_info.dart';

class DataClassDefinition {
  const DataClassDefinition({required this.className, required this.fields});

  final String className;
  final List<FieldInfo> fields;
}

class EnumDefinition {
  const EnumDefinition({required this.name, required this.values});

  final String name;
  final List<String> values;
}
