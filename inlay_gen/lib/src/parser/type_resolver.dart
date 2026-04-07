import 'package:inlay_gen/src/models/schema.dart';
import 'package:inlay_gen/src/models/store_definition.dart';
import 'package:inlay_gen/src/models/type_info.dart';

/// Returns true if the type is a simple store type (primitive or enum)
/// that can be stored as a plain string without JSON encoding.
bool isSimpleStoreType(TypeInfo type, Map<String, TypeDefinition> typeGraph) {
  final baseName = type.baseName;
  return const {'bool', 'int', 'double', 'String'}.contains(baseName) ||
      typeGraph[baseName] is EnumType;
}

const _primitiveTypes = {
  'bool',
  'int',
  'double',
  'num',
  'String',
  'Uint8List',
  'List',
  'Map',
  'Object',
  'dynamic',
};

class TypeResolutionResult {
  const TypeResolutionResult({
    required this.schema,
    required this.errors,
    required this.typeGraph,
  });

  final Schema schema;
  final List<TypeResolutionError> errors;
  final Map<String, TypeDefinition> typeGraph;

  bool get isValid => errors.isEmpty;
}

class TypeResolutionError {
  const TypeResolutionError({required this.message, required this.location});

  final String message;
  final String location;

  @override
  String toString() => '$location: $message';
}

abstract class TypeDefinition {
  const TypeDefinition({required this.name});
  final String name;
}

class DataClassType extends TypeDefinition {
  const DataClassType({required super.name, required this.fields});
  final List<FieldInfo> fields;
}

class EnumType extends TypeDefinition {
  const EnumType({required super.name, required this.values});
  final List<String> values;
}

class TypeResolver {
  TypeResolutionResult resolve(Schema schema) {
    final errors = <TypeResolutionError>[];
    final typeGraph = <String, TypeDefinition>{};

    // Register all known custom types.
    for (final dataClass in schema.dataClasses) {
      if (typeGraph.containsKey(dataClass.className)) {
        errors.add(
          TypeResolutionError(
            message: 'Duplicate type definition',
            location: dataClass.className,
          ),
        );
      } else {
        typeGraph[dataClass.className] = DataClassType(
          name: dataClass.className,
          fields: dataClass.fields,
        );
      }
    }

    for (final enumDef in schema.enums) {
      if (typeGraph.containsKey(enumDef.name)) {
        errors.add(
          TypeResolutionError(
            message: 'Duplicate type definition',
            location: enumDef.name,
          ),
        );
      } else {
        typeGraph[enumDef.name] = EnumType(
          name: enumDef.name,
          values: enumDef.values,
        );
      }
    }

    // Also register route classes as types (they can be nested).
    for (final route in schema.allRoutes) {
      if (!typeGraph.containsKey(route.className)) {
        typeGraph[route.className] = DataClassType(
          name: route.className,
          fields: route.fields,
        );
      }
    }

    // Validate route types.
    for (final route in schema.allRoutes) {
      _validateFields(route.fields, route.className, typeGraph, errors);
    }

    // Validate data class types.
    for (final dataClass in schema.dataClasses) {
      _validateFields(dataClass.fields, dataClass.className, typeGraph, errors);
    }

    // Validate store types.
    for (final store in schema.stores) {
      _validateStoreFields(store, typeGraph, errors);
    }

    // Validate store value field types (using same validation as routes).
    for (final store in schema.stores) {
      _validateStoreValueFieldTypes(store, typeGraph, errors);
    }

    // Check for circular references.
    final circularRefs = _findCircularReferences(typeGraph);
    for (final cycle in circularRefs) {
      errors.add(
        TypeResolutionError(
          message:
              'Circular reference detected: ${cycle.join(' -> ')} -> ${cycle.first}',
          location: cycle.first,
        ),
      );
    }

    // Check for duplicate route names.
    final routeNames = <String, String>{};
    for (final route in schema.allRoutes) {
      if (routeNames.containsKey(route.routeName)) {
        errors.add(
          TypeResolutionError(
            message:
                'Duplicate route name "${route.routeName}" '
                '(also used by ${routeNames[route.routeName]})',
            location: route.className,
          ),
        );
      } else {
        routeNames[route.routeName] = route.className;
      }
    }

    return TypeResolutionResult(
      schema: schema,
      errors: errors,
      typeGraph: typeGraph,
    );
  }

  void _validateFields(
    List<FieldInfo> fields,
    String className,
    Map<String, TypeDefinition> typeGraph,
    List<TypeResolutionError> errors,
  ) {
    for (final field in fields) {
      _validateType(field.type, '$className.${field.name}', typeGraph, errors);
    }
  }

  void _validateType(
    TypeInfo type,
    String location,
    Map<String, TypeDefinition> typeGraph,
    List<TypeResolutionError> errors,
  ) {
    final baseName = type.baseName;

    // Check if it's a primitive or known type.
    if (_primitiveTypes.contains(baseName)) {
      // Validate type arguments for generic types.
      for (final arg in type.typeArguments) {
        _validateType(arg, location, typeGraph, errors);
      }
      return;
    }

    // Check if it's a known custom type.
    if (typeGraph.containsKey(baseName)) {
      return;
    }

    // Unknown type.
    errors.add(
      TypeResolutionError(
        message: 'Unknown type "$baseName"',
        location: location,
      ),
    );
  }

  void _validateStoreFields(
    StoreDefinition store,
    Map<String, TypeDefinition> typeGraph,
    List<TypeResolutionError> errors,
  ) {
    // Store key: zero or one key field.
    if (store.keyFields.length > 1) {
      errors.add(
        TypeResolutionError(
          message:
              'Store can have at most one field annotated with @InlayStoreKey',
          location: store.className,
        ),
      );
    }

    for (final field in store.keyFields) {
      final baseName = field.type.baseName;
      final isEnum = typeGraph[baseName] is EnumType;
      final isSupportedKeyType =
          baseName == 'String' || baseName == 'int' || isEnum;

      if (!isSupportedKeyType) {
        errors.add(
          TypeResolutionError(
            message:
                'Store key field must be String, int, or enum. Found: $baseName',
            location: '${store.className}.${field.name}',
          ),
        );
      }

      if (field.type.isNullable) {
        errors.add(
          TypeResolutionError(
            message: 'Store key field cannot be nullable.',
            location: '${store.className}.${field.name}',
          ),
        );
      }

      if (!field.isRequired || field.hasDefault) {
        errors.add(
          TypeResolutionError(
            message:
                'Store key field must be a required constructor parameter without default value.',
            location: '${store.className}.${field.name}',
          ),
        );
      }
    }

    // Validate store value field types.
    for (final field in store.valueFields) {
      _validateType(
        field.type,
        '${store.className}.${field.name}',
        typeGraph,
        errors,
      );
    }
  }

  void _validateStoreValueFieldTypes(
    StoreDefinition store,
    Map<String, TypeDefinition> typeGraph,
    List<TypeResolutionError> errors,
  ) {
    for (final field in store.valueFields) {
      if (!isSimpleStoreType(field.type, typeGraph) &&
          !field.type.isNullable &&
          !field.hasDefault) {
        errors.add(
          TypeResolutionError(
            message:
                'Non-nullable complex store field must have a default value. '
                'Make it nullable or provide a default.',
            location: '${store.className}.${field.name}',
          ),
        );
      }
    }
  }

  /// Finds circular references in the type graph using DFS.
  List<List<String>> _findCircularReferences(
    Map<String, TypeDefinition> typeGraph,
  ) {
    final cycles = <List<String>>[];
    final visited = <String>{};
    final inStack = <String>{};
    final stack = <String>[];

    void dfs(String typeName) {
      if (inStack.contains(typeName)) {
        // Found a cycle.
        final cycleStart = stack.indexOf(typeName);
        cycles.add(stack.sublist(cycleStart).toList());
        return;
      }

      if (visited.contains(typeName)) {
        return;
      }

      visited.add(typeName);
      inStack.add(typeName);
      stack.add(typeName);

      final typeDef = typeGraph[typeName];
      if (typeDef is DataClassType) {
        for (final field in typeDef.fields) {
          final baseName = field.type.baseName;
          if (typeGraph.containsKey(baseName)) {
            dfs(baseName);
          }
        }
      }

      stack.removeLast();
      inStack.remove(typeName);
    }

    typeGraph.keys.forEach(dfs);

    return cycles;
  }
}
