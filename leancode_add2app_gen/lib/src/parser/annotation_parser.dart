import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:leancode_add2app_gen/src/models/data_type_definition.dart';
import 'package:leancode_add2app_gen/src/models/route_definition.dart';
import 'package:leancode_add2app_gen/src/models/schema.dart';
import 'package:leancode_add2app_gen/src/models/store_definition.dart';
import 'package:leancode_add2app_gen/src/models/type_info.dart';
import 'package:leancode_add2app_gen/src/utils/naming.dart';

/// Annotation names that the parser looks for.
const _flutterRouteAnnotations = ['Add2AppFlutterRoute', 'add2AppFlutterRoute'];
const _nativeRouteAnnotations = ['Add2AppNativeRoute', 'add2AppNativeRoute'];
const _storeAnnotations = ['Add2AppStore', 'add2AppStore'];

/// Parses a Dart schema file and extracts definitions from annotations.
///
/// Looks for:
/// - `@Add2AppFlutterRoute()` or `@add2AppFlutterRoute`
/// - `@Add2AppNativeRoute()` or `@add2AppNativeRoute`
/// - `@Add2AppStore()` or `@add2AppStore`
/// - Non-annotated classes (data classes)
/// - Enums
class AnnotationParser {
  /// Parses the given [source] code and returns a [Schema].
  ///
  /// [path] is used only for error messages and diagnostics.
  Schema parse(String source, {String? path}) {
    final parseResult = parseString(
      content: source,
      path: path,
    );

    final unit = parseResult.unit;
    final visitor = _SchemaCollectorVisitor();
    unit.visitChildren(visitor);

    return Schema(
      flutterRoutes: visitor.flutterRoutes,
      nativeRoutes: visitor.nativeRoutes,
      stores: visitor.stores,
      dataClasses: visitor.dataClasses,
      enums: visitor.enums,
    );
  }
}

/// AST visitor that collects schema definitions.
class _SchemaCollectorVisitor extends RecursiveAstVisitor<void> {
  final List<RouteDefinition> flutterRoutes = [];
  final List<RouteDefinition> nativeRoutes = [];
  final List<StoreDefinition> stores = [];
  final List<DataClassDefinition> dataClasses = [];
  final List<EnumDefinition> enums = [];

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    // Using deprecated API - namePart replacement has different structure.
    // ignore: deprecated_member_use
    final className = node.name.lexeme;

    // Check for route annotations.
    final flutterAnnotation = _findAnnotation(node, _flutterRouteAnnotations);
    if (flutterAnnotation != null) {
      final routeName = _extractRouteName(flutterAnnotation, className);
      final fields = _extractFields(node);
      flutterRoutes.add(RouteDefinition(
        className: className,
        routeType: RouteType.flutter,
        routeName: routeName,
        fields: fields,
      ));
      super.visitClassDeclaration(node);
      return;
    }

    final nativeAnnotation = _findAnnotation(node, _nativeRouteAnnotations);
    if (nativeAnnotation != null) {
      final routeName = _extractRouteName(nativeAnnotation, className);
      final fields = _extractFields(node);
      nativeRoutes.add(RouteDefinition(
        className: className,
        routeType: RouteType.native,
        routeName: routeName,
        fields: fields,
      ));
      super.visitClassDeclaration(node);
      return;
    }

    // Check for store annotation.
    final storeAnnotation = _findAnnotation(node, _storeAnnotations);
    if (storeAnnotation != null) {
      final storeKey = _extractStoreKey(storeAnnotation, className);
      final (scopeFields, valueFields) = _extractStoreFields(node);
      stores.add(StoreDefinition(
        className: className,
        storeKey: storeKey,
        scopeFields: scopeFields,
        valueFields: valueFields,
      ));
      super.visitClassDeclaration(node);
      return;
    }

    // Non-annotated class - treat as data class.
    final fields = _extractFields(node);
    if (fields.isNotEmpty) {
      dataClasses.add(DataClassDefinition(
        className: className,
        fields: fields,
      ));
    }

    super.visitClassDeclaration(node);
  }

  @override
  void visitEnumDeclaration(EnumDeclaration node) {
    // Using deprecated API - namePart replacement has different structure.
    // ignore: deprecated_member_use
    final name = node.name.lexeme;
    // Using deprecated API - body.constants has different iteration pattern.
    // ignore: deprecated_member_use
    final values = node.constants.map((c) => c.name.lexeme).toList();
    enums.add(EnumDefinition(name: name, values: values));
    super.visitEnumDeclaration(node);
  }

  /// Finds an annotation on [node] matching any of [annotationNames].
  Annotation? _findAnnotation(
    ClassDeclaration node,
    List<String> annotationNames,
  ) {
    for (final metadata in node.metadata) {
      final name = metadata.name.name;
      if (annotationNames.contains(name)) {
        return metadata;
      }
    }
    return null;
  }

  /// Extracts the route name from an annotation.
  ///
  /// If the annotation has a positional argument, use that.
  /// Otherwise, derive from the class name (remove "Page" suffix, camelCase).
  String _extractRouteName(Annotation annotation, String className) {
    final arguments = annotation.arguments;
    if (arguments != null && arguments.arguments.isNotEmpty) {
      final firstArg = arguments.arguments.first;
      if (firstArg is SimpleStringLiteral) {
        return firstArg.value;
      }
    }
    return routeIdFromClassName(className);
  }

  /// Extracts the store key from an annotation.
  ///
  /// Looks for a `key:` named argument.
  /// Otherwise, derive from the class name (remove "Store" suffix, snake_case).
  String _extractStoreKey(Annotation annotation, String className) {
    final arguments = annotation.arguments;
    if (arguments != null) {
      for (final arg in arguments.arguments) {
        if (arg is NamedExpression && arg.name.label.name == 'key') {
          final expr = arg.expression;
          if (expr is SimpleStringLiteral) {
            return expr.value;
          }
        }
      }
    }
    return storeKeyFromClassName(className);
  }

  List<FieldInfo> _extractFields(ClassDeclaration node) {
    final fields = <FieldInfo>[];
    // Using deprecated API - body.members has different iteration pattern.
    // ignore: deprecated_member_use
    final members = node.members;

    // First, collect constructor parameter info.
    final paramInfo = _extractConstructorParamInfo(members);

    // Then collect field declarations.
    for (final member in members) {
      if (member is FieldDeclaration) {
        final typeAnnotation = member.fields.type;
        if (typeAnnotation == null) {
          continue;
        }

        for (final variable in member.fields.variables) {
          final fieldName = variable.name.lexeme;
          final typeInfo = _parseTypeAnnotation(typeAnnotation);
          final info = paramInfo[fieldName];

          fields.add(FieldInfo(
            name: fieldName,
            type: typeInfo,
            isRequired: info?.isRequired ?? false,
            defaultValue: info?.defaultValue,
          ));
        }
      }
    }

    return fields;
  }

  /// Extracts store fields, separating scope fields from value fields.
  ///
  /// Scope fields: required constructor params without defaults.
  /// Value fields: everything else.
  (List<FieldInfo>, List<FieldInfo>) _extractStoreFields(ClassDeclaration node) {
    final allFields = _extractFields(node);
    final scopeFields = <FieldInfo>[];
    final valueFields = <FieldInfo>[];

    for (final field in allFields) {
      if (field.isRequired && !field.hasDefault) {
        scopeFields.add(field);
      } else {
        valueFields.add(field);
      }
    }

    return (scopeFields, valueFields);
  }

  /// Collects parameter info (required, default value) from constructors.
  Map<String, _ParamInfo> _extractConstructorParamInfo(NodeList<ClassMember> members) {
    final info = <String, _ParamInfo>{};

    for (final member in members) {
      if (member is ConstructorDeclaration && member.name == null) {
        // Primary constructor (unnamed).
        for (final param in member.parameters.parameters) {
          final name = param.name?.lexeme;
          if (name == null) {
            continue;
          }

          String? defaultValue;
          if (param is DefaultFormalParameter && param.defaultValue != null) {
            defaultValue = param.defaultValue!.toSource();
          }

          info[name] = _ParamInfo(
            isRequired: param.isRequired,
            defaultValue: defaultValue,
          );
        }
      }
    }

    return info;
  }

  /// Parses a type annotation into [TypeInfo].
  TypeInfo _parseTypeAnnotation(TypeAnnotation typeAnnotation) {
    if (typeAnnotation is NamedType) {
      final name = typeAnnotation.name.lexeme;
      final isNullable = typeAnnotation.question != null;
      final typeArgs = <TypeInfo>[];

      final typeArgList = typeAnnotation.typeArguments;
      if (typeArgList != null) {
        for (final arg in typeArgList.arguments) {
          typeArgs.add(_parseTypeAnnotation(arg));
        }
      }

      return TypeInfo(
        name: name,
        isNullable: isNullable,
        typeArguments: typeArgs,
      );
    }

    // Fallback for unknown type annotations.
    return TypeInfo(
      name: typeAnnotation.toSource().replaceAll('?', ''),
      isNullable: typeAnnotation.question != null,
    );
  }
}

class _ParamInfo {
  const _ParamInfo({required this.isRequired, this.defaultValue});

  final bool isRequired;
  final String? defaultValue;
}
