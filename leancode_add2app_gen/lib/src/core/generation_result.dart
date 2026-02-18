import 'package:leancode_add2app_gen/src/models/schema.dart';
import 'package:leancode_add2app_gen/src/parser/type_resolver.dart';

class GenerationResult {
  const GenerationResult({
    required this.schema,
    required this.typeGraph,
    this.dartRoutesCode,
    this.dartStoresCode,
    this.kotlinRoutesCode,
    this.kotlinStoresCode,
    this.swiftRoutesCode,
  });

  final Schema schema;
  final Map<String, TypeDefinition> typeGraph;
  final String? dartRoutesCode;
  final String? dartStoresCode;
  final String? kotlinRoutesCode;
  final String? kotlinStoresCode;
  final String? swiftRoutesCode;

  bool get hasRoutes =>
      schema.flutterRoutes.isNotEmpty ||
      schema.nativeRoutes.isNotEmpty ||
      schema.dataClasses.isNotEmpty ||
      schema.enums.isNotEmpty;

  bool get hasStores => schema.stores.isNotEmpty;
  bool get hasContent => hasRoutes || hasStores;
}

class GenerationError {
  const GenerationError(this.message);
  final String message;

  @override
  String toString() => message;
}

sealed class ParseResult {
  const ParseResult();
}

class ParseSuccess extends ParseResult {
  const ParseSuccess({required this.schema, required this.resolution});

  final Schema schema;
  final TypeResolutionResult resolution;
}

class ParseFailure extends ParseResult {
  const ParseFailure(this.errors);
  final List<GenerationError> errors;
}
