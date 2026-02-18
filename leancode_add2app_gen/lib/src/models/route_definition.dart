import 'package:leancode_add2app_gen/src/models/type_info.dart';

enum RouteType { flutter, native }

class RouteDefinition {
  const RouteDefinition({
    required this.className,
    required this.routeType,
    required this.routeName,
    required this.fields,
  });

  final String className;
  final RouteType routeType;
  final String routeName;
  final List<FieldInfo> fields;

  @override
  String toString() =>
      'RouteDefinition($className, '
      'type: ${routeType.name}, '
      'name: $routeName, '
      'fields: [${fields.map((f) => f.name).join(', ')}])';
}
