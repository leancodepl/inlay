import 'package:leancode_add2app_gen/src/models/schema.dart';
import 'package:leancode_add2app_gen/src/parser/type_resolver.dart';

/// Result of code generation containing all generated code.
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

  /// Generated Dart routes code (null if no routes).
  final String? dartRoutesCode;

  /// Generated Dart stores code (null if no stores).
  final String? dartStoresCode;

  /// Generated Kotlin routes code (null if no routes or no package specified).
  final String? kotlinRoutesCode;

  /// Generated Kotlin stores code (null if no stores or no package specified).
  final String? kotlinStoresCode;

  /// Generated Swift routes code (null if no routes).
  final String? swiftRoutesCode;

  bool get hasRoutes =>
      schema.flutterRoutes.isNotEmpty ||
      schema.nativeRoutes.isNotEmpty ||
      schema.dataClasses.isNotEmpty ||
      schema.enums.isNotEmpty;

  bool get hasStores => schema.stores.isNotEmpty;

  bool get hasContent => hasRoutes || hasStores;
}

/// Errors that occurred during schema parsing or type resolution.
class GenerationError {
  const GenerationError(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Result of parsing and validating a schema.
sealed class ParseResult {
  const ParseResult();
}

class ParseSuccess extends ParseResult {
  const ParseSuccess({
    required this.schema,
    required this.resolution,
  });

  final Schema schema;
  final TypeResolutionResult resolution;
}

class ParseFailure extends ParseResult {
  const ParseFailure(this.errors);

  final List<GenerationError> errors;
}
