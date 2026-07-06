import 'package:inlay_gen/src/models/type_info.dart';

enum RouteType { flutter, native, flutterDialog }

class RouteDefinition {
  const RouteDefinition({
    required this.className,
    required this.routeType,
    required this.routeName,
    required this.fields,
    this.path,
    this.resultType,
  });

  final String className;
  final RouteType routeType;

  /// Internal route identifier, auto-derived from class name.
  final String routeName;

  final List<FieldInfo> fields;

  /// URL path template for Flutter routes (e.g. '/products/:id').
  /// Null for native routes.
  final String? path;

  /// Result type the screen returns to its caller, from the annotation's
  /// `result:` argument. Null when the route returns nothing.
  final TypeInfo? resultType;

  @override
  String toString() =>
      'RouteDefinition($className, '
      'type: ${routeType.name}, '
      'name: $routeName, '
      'path: $path, '
      'fields: [${fields.map((f) => f.name).join(', ')}])';
}
