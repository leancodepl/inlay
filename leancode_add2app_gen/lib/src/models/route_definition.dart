import 'package:leancode_add2app_gen/src/models/type_info.dart';

/// The type of route (Flutter or Native).
enum RouteType {
  flutter,
  native,
}

/// A parsed route class from the schema file.
class RouteDefinition {
  const RouteDefinition({
    required this.className,
    required this.routeType,
    required this.routeName,
    required this.fields,
  });

  /// The class name (e.g., `ContactDetailsPage`).
  final String className;

  /// Whether this is a Flutter or native route.
  final RouteType routeType;

  /// The route name/ID used in navigation.
  /// Either explicitly provided in the annotation or derived from class name.
  final String routeName;

  /// The fields declared in the class.
  final List<FieldInfo> fields;

  @override
  String toString() =>
      'RouteDefinition($className, '
      'type: ${routeType.name}, '
      'name: $routeName, '
      'fields: [${fields.map((f) => f.name).join(', ')}])';
}
