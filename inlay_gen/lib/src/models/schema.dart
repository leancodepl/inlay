import 'package:inlay_gen/src/models/data_type_definition.dart';
import 'package:inlay_gen/src/models/route_definition.dart';
import 'package:inlay_gen/src/models/store_definition.dart';
import 'package:inlay_gen/src/models/type_info.dart';

class Schema {
  const Schema({
    this.flutterRoutes = const [],
    this.flutterDialogRoutes = const [],
    this.nativeRoutes = const [],
    this.stores = const [],
    this.dataClasses = const [],
    this.enums = const [],
  });

  final List<RouteDefinition> flutterRoutes;
  final List<RouteDefinition> flutterDialogRoutes;
  final List<RouteDefinition> nativeRoutes;
  final List<StoreDefinition> stores;
  final List<DataClassDefinition> dataClasses;
  final List<EnumDefinition> enums;

  List<RouteDefinition> get allRoutes => [
    ...flutterRoutes,
    ...flutterDialogRoutes,
    ...nativeRoutes,
  ];

  Schema merge(Schema other) => Schema(
    flutterRoutes: [...flutterRoutes, ...other.flutterRoutes],
    flutterDialogRoutes: [...flutterDialogRoutes, ...other.flutterDialogRoutes],
    nativeRoutes: [...nativeRoutes, ...other.nativeRoutes],
    stores: [...stores, ...other.stores],
    dataClasses: [...dataClasses, ...other.dataClasses],
    enums: [...enums, ...other.enums],
  );

  /// Splits data classes and enums into route-referenced vs store-only types.
  ///
  /// Types transitively referenced by any route go to `routeTypes`.
  /// Types only referenced by stores go to `storeOnlyTypes`.
  ({
    List<DataClassDefinition> routeDataClasses,
    List<EnumDefinition> routeEnums,
    List<DataClassDefinition> storeOnlyDataClasses,
    List<EnumDefinition> storeOnlyEnums,
  })
  classifyTypes() {
    final routeReferenced = <String>{};
    final dataClassByName = {for (final dc in dataClasses) dc.className: dc};

    // Collect all type names referenced by routes (transitively).
    void collectTypes(TypeInfo type) {
      final baseName = type.baseName;
      if (routeReferenced.add(baseName)) {
        final dc = dataClassByName[baseName];
        if (dc != null) {
          for (final field in dc.fields) {
            collectTypes(field.type);
          }
        }
      }
      type.typeArguments.forEach(collectTypes);
    }

    for (final route in allRoutes) {
      for (final field in route.fields) {
        collectTypes(field.type);
      }
    }

    return (
      routeDataClasses: dataClasses
          .where((dc) => routeReferenced.contains(dc.className))
          .toList(),
      routeEnums: enums.where((e) => routeReferenced.contains(e.name)).toList(),
      storeOnlyDataClasses: dataClasses
          .where((dc) => !routeReferenced.contains(dc.className))
          .toList(),
      storeOnlyEnums: enums
          .where((e) => !routeReferenced.contains(e.name))
          .toList(),
    );
  }
}
