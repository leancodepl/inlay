import 'package:leancode_add2app_gen/src/models/type_info.dart';

enum RouteType { flutter, native, flutterDialog }

class RouteDefinition {
  const RouteDefinition({
    required this.className,
    required this.routeType,
    required this.routeName,
    required this.fields,
    this.path,
  });

  final String className;
  final RouteType routeType;

  /// Internal route identifier, auto-derived from class name.
  final String routeName;

  final List<FieldInfo> fields;

  /// URL path template for Flutter routes (e.g. '/products/:id').
  /// Null for native routes.
  final String? path;

  @override
  String toString() =>
      'RouteDefinition($className, '
      'type: ${routeType.name}, '
      'name: $routeName, '
      'path: $path, '
      'fields: [${fields.map((f) => f.name).join(', ')}])';
}
