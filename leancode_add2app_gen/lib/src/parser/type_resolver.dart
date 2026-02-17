import 'package:leancode_add2app_gen/src/models/schema.dart';
import 'package:leancode_add2app_gen/src/models/store_definition.dart';
import 'package:leancode_add2app_gen/src/models/type_info.dart';

/// Primitive types supported by the serialization.
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

/// Result of type resolution containing the validated schema and any errors.
class TypeResolutionResult {
  const TypeResolutionResult({
    required this.schema,
    required this.errors,
    required this.typeGraph,
  });

  /// The validated schema.
  final Schema schema;

  /// Any errors found during resolution.
  final List<TypeResolutionError> errors;

  /// Map of type name to its definition for quick lookup.
  final Map<String, TypeDefinition> typeGraph;

  /// Whether resolution was successful (no errors).
  bool get isValid => errors.isEmpty;
}

/// Represents an error found during type resolution.
class TypeResolutionError {
  const TypeResolutionError({
    required this.message,
    required this.location,
  });

  /// Error message.
  final String message;

  /// Where the error occurred (class name, field name, etc.).
  final String location;

  @override
  String toString() => '$location: $message';
}

/// Represents a resolved type definition (class or enum).
abstract class TypeDefinition {
  const TypeDefinition({required this.name});

  final String name;
}

/// A resolved data class.
class DataClassType extends TypeDefinition {
  const DataClassType({
    required super.name,
    required this.fields,
  });

  final List<FieldInfo> fields;
}

/// A resolved enum.
class EnumType extends TypeDefinition {
  const EnumType({
    required super.name,
    required this.values,
  });

  final List<String> values;
}

/// Resolves and validates types in a schema.
///
/// Builds a type graph, validates all types are known, and detects circular references.
class TypeResolver {
  /// Resolves and validates the given [schema].
  TypeResolutionResult resolve(Schema schema) {
    final errors = <TypeResolutionError>[];
    final typeGraph = <String, TypeDefinition>{};

    // Register all known custom types.
    for (final dataClass in schema.dataClasses) {
      if (typeGraph.containsKey(dataClass.className)) {
        errors.add(TypeResolutionError(
          message: 'Duplicate type definition',
          location: dataClass.className,
        ));
      } else {
        typeGraph[dataClass.className] = DataClassType(
          name: dataClass.className,
          fields: dataClass.fields,
        );
      }
    }

    for (final enumDef in schema.enums) {
      if (typeGraph.containsKey(enumDef.name)) {
        errors.add(TypeResolutionError(
          message: 'Duplicate type definition',
          location: enumDef.name,
        ));
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
      _validateFields(
        route.fields,
        route.className,
        typeGraph,
        errors,
      );
    }

    // Validate data class types.
    for (final dataClass in schema.dataClasses) {
      _validateFields(
        dataClass.fields,
        dataClass.className,
        typeGraph,
        errors,
      );
    }

    // Validate store types (only primitives + String for now).
    for (final store in schema.stores) {
      _validateStoreFields(store, errors);
    }

    // Check for circular references.
    final circularRefs = _findCircularReferences(typeGraph);
    for (final cycle in circularRefs) {
      errors.add(TypeResolutionError(
        message: 'Circular reference detected: ${cycle.join(' -> ')} -> ${cycle.first}',
        location: cycle.first,
      ));
    }

    // Check for duplicate route names.
    final routeNames = <String, String>{};
    for (final route in schema.allRoutes) {
      if (routeNames.containsKey(route.routeName)) {
        errors.add(TypeResolutionError(
          message: 'Duplicate route name "${route.routeName}" '
              '(also used by ${routeNames[route.routeName]})',
          location: route.className,
        ));
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
    errors.add(TypeResolutionError(
      message: 'Unknown type "$baseName"',
      location: location,
    ));
  }

  void _validateStoreFields(
    StoreDefinition store,
    List<TypeResolutionError> errors,
  ) {
    // For now, stores only support primitive types.
    final supportedStoreTypes = {'bool', 'int', 'double', 'String'};

    for (final field in store.valueFields) {
      final baseName = field.type.baseName;
      if (!supportedStoreTypes.contains(baseName)) {
        errors.add(TypeResolutionError(
          message: 'Store fields must be primitive types (bool, int, double, String). '
              'Found: $baseName',
          location: '${store.className}.${field.name}',
        ));
      }
    }

    // Scope fields must be String.
    for (final field in store.scopeFields) {
      if (field.type.baseName != 'String') {
        errors.add(TypeResolutionError(
          message: 'Store scope fields must be String. Found: ${field.type.baseName}',
          location: '${store.className}.${field.name}',
        ));
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

      if (visited.contains(typeName)) return;

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

    for (final typeName in typeGraph.keys) {
      dfs(typeName);
    }

    return cycles;
  }
}
