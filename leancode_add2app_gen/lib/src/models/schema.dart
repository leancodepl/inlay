import 'package:leancode_add2app_gen/src/models/data_type_definition.dart';
import 'package:leancode_add2app_gen/src/models/route_definition.dart';
import 'package:leancode_add2app_gen/src/models/store_definition.dart';

class Schema {
  const Schema({
    this.flutterRoutes = const [],
    this.nativeRoutes = const [],
    this.stores = const [],
    this.dataClasses = const [],
    this.enums = const [],
  });

  final List<RouteDefinition> flutterRoutes;
  final List<RouteDefinition> nativeRoutes;
  final List<StoreDefinition> stores;
  final List<DataClassDefinition> dataClasses;
  final List<EnumDefinition> enums;

  List<RouteDefinition> get allRoutes => [...flutterRoutes, ...nativeRoutes];

  Schema merge(Schema other) => Schema(
        flutterRoutes: [...flutterRoutes, ...other.flutterRoutes],
        nativeRoutes: [...nativeRoutes, ...other.nativeRoutes],
        stores: [...stores, ...other.stores],
        dataClasses: [...dataClasses, ...other.dataClasses],
        enums: [...enums, ...other.enums],
      );
}
