import 'package:leancode_add2app_gen/src/models/data_type_definition.dart';
import 'package:leancode_add2app_gen/src/models/route_definition.dart';
import 'package:leancode_add2app_gen/src/models/store_definition.dart';

/// Complete parsed schema containing all definitions.
class Schema {
  const Schema({
    this.flutterRoutes = const [],
    this.nativeRoutes = const [],
    this.stores = const [],
    this.dataClasses = const [],
    this.enums = const [],
  });

  /// Flutter route definitions (`@Add2AppFlutterRoute`).
  final List<RouteDefinition> flutterRoutes;

  /// Native route definitions (`@Add2AppNativeRoute`).
  final List<RouteDefinition> nativeRoutes;

  /// Store definitions (`@Add2AppStore`).
  final List<StoreDefinition> stores;

  /// Data class definitions (non-annotated classes).
  final List<DataClassDefinition> dataClasses;

  /// Enum definitions.
  final List<EnumDefinition> enums;

  /// All route definitions (Flutter + native).
  List<RouteDefinition> get allRoutes => [...flutterRoutes, ...nativeRoutes];

  /// Merges this schema with another.
  Schema merge(Schema other) {
    return Schema(
      flutterRoutes: [...flutterRoutes, ...other.flutterRoutes],
      nativeRoutes: [...nativeRoutes, ...other.nativeRoutes],
      stores: [...stores, ...other.stores],
      dataClasses: [...dataClasses, ...other.dataClasses],
      enums: [...enums, ...other.enums],
    );
  }

  @override
  String toString() =>
      'Schema('
      'flutterRoutes: ${flutterRoutes.length}, '
      'nativeRoutes: ${nativeRoutes.length}, '
      'stores: ${stores.length}, '
      'dataClasses: ${dataClasses.length}, '
      'enums: ${enums.length})';
}
