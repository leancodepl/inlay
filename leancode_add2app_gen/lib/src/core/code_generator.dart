import 'dart:io';

import 'package:leancode_add2app_gen/src/core/generation_result.dart';
import 'package:leancode_add2app_gen/src/generators/dart/dart_routes_generator.dart';
import 'package:leancode_add2app_gen/src/generators/dart/dart_store_generator.dart';
import 'package:leancode_add2app_gen/src/generators/kotlin/kotlin_routes_generator.dart';
import 'package:leancode_add2app_gen/src/generators/kotlin/kotlin_store_generator.dart';
import 'package:leancode_add2app_gen/src/generators/swift/swift_routes_generator.dart';
import 'package:leancode_add2app_gen/src/generators/swift/swift_store_generator.dart';
import 'package:leancode_add2app_gen/src/models/schema.dart';
import 'package:leancode_add2app_gen/src/parser/annotation_parser.dart';
import 'package:leancode_add2app_gen/src/parser/type_resolver.dart';
import 'package:path/path.dart' as p;

class CodeGenerator {
  CodeGenerator({AnnotationParser? parser, TypeResolver? resolver})
    : _parser = parser ?? AnnotationParser(),
      _resolver = resolver ?? TypeResolver();

  final AnnotationParser _parser;
  final TypeResolver _resolver;

  ParseResult parseAndValidate(String source, {String? path}) {
    final schema = _parser.parse(source, path: path);
    final resolution = _resolver.resolve(schema);

    if (!resolution.isValid) {
      return ParseFailure(
        resolution.errors.map((e) => GenerationError(e.toString())).toList(),
      );
    }

    return ParseSuccess(schema: schema, resolution: resolution);
  }

  /// Parses multiple source files and merges their schemas.
  ParseResult parseAndValidateMultiple(
    List<(String source, String? path)> sources,
  ) {
    var mergedSchema = const Schema();

    for (final (source, path) in sources) {
      final schema = _parser.parse(source, path: path);
      mergedSchema = mergedSchema.merge(schema);
    }

    final resolution = _resolver.resolve(mergedSchema);

    if (!resolution.isValid) {
      return ParseFailure(
        resolution.errors.map((e) => GenerationError(e.toString())).toList(),
      );
    }

    return ParseSuccess(schema: mergedSchema, resolution: resolution);
  }

  /// Generates all code from a successfully parsed schema.
  GenerationResult generate({
    required Schema schema,
    required Map<String, TypeDefinition> typeGraph,
    String? kotlinPackage,
  }) {
    // Split types: route-referenced types go to routes file,
    // store-only types go to stores file.
    final types = schema.classifyTypes();

    final routeSchema = Schema(
      flutterRoutes: schema.flutterRoutes,
      flutterDialogRoutes: schema.flutterDialogRoutes,
      nativeRoutes: schema.nativeRoutes,
      dataClasses: types.routeDataClasses,
      enums: types.routeEnums,
    );

    final storeSchema = Schema(
      stores: schema.stores,
      dataClasses: types.storeOnlyDataClasses,
      enums: types.storeOnlyEnums,
    );

    final hasRoutes =
        schema.flutterRoutes.isNotEmpty ||
        schema.flutterDialogRoutes.isNotEmpty ||
        schema.nativeRoutes.isNotEmpty ||
        types.routeDataClasses.isNotEmpty ||
        types.routeEnums.isNotEmpty;
    final hasStores = schema.stores.isNotEmpty;

    return GenerationResult(
      schema: schema,
      typeGraph: typeGraph,
      dartRoutesCode: hasRoutes
          ? generateDartRoutes(schema: routeSchema, typeGraph: typeGraph)
          : null,
      dartStoresCode: hasStores
          ? generateDartStores(schema: storeSchema, typeGraph: typeGraph)
          : null,
      kotlinRoutesCode: hasRoutes && kotlinPackage != null
          ? generateKotlinRoutes(
              schema: routeSchema,
              typeGraph: typeGraph,
              packageName: kotlinPackage,
            )
          : null,
      kotlinStoresCode: hasStores && kotlinPackage != null
          ? generateKotlinStores(
              schema: storeSchema,
              typeGraph: typeGraph,
              packageName: kotlinPackage,
            )
          : null,
      swiftRoutesCode: hasRoutes
          ? generateSwiftRoutes(schema: routeSchema, typeGraph: typeGraph)
          : null,
      swiftStoresCode: hasStores
          ? generateSwiftStores(schema: storeSchema, typeGraph: typeGraph)
          : null,
    );
  }

  /// Convenience method that parses, validates, and generates in one call.
  (GenerationResult?, List<GenerationError>) generateFromSource(
    String source, {
    String? path,
    String? kotlinPackage,
  }) {
    final parseResult = parseAndValidate(source, path: path);

    switch (parseResult) {
      case ParseFailure(:final errors):
        return (null, errors);
      case ParseSuccess(:final schema, :final resolution):
        final result = generate(
          schema: schema,
          typeGraph: resolution.typeGraph,
          kotlinPackage: kotlinPackage,
        );
        return (result, const []);
    }
  }
}

/// Configuration for native file output.
class NativeOutputConfig {
  /// Creates a new native output configuration.
  const NativeOutputConfig({
    this.kotlinOutput,
    this.kotlinPackage,
    this.swiftOutput,
  });

  /// The output directory for Kotlin files.
  final String? kotlinOutput;

  /// The Kotlin package name for generated files.
  final String? kotlinPackage;

  /// The output directory for Swift files.
  final String? swiftOutput;

  /// Whether Kotlin generation is configured.
  bool get hasKotlinConfig => kotlinOutput != null && kotlinPackage != null;

  /// Whether Swift generation is configured.
  bool get hasSwiftConfig => swiftOutput != null;
}

/// Writes native (Kotlin/Swift) files to disk.
///
/// This is extracted as a separate function since both CLI and build_runner
/// need to write native files (build_runner only manages Dart output).
void writeNativeFiles(
  GenerationResult result,
  NativeOutputConfig config, {
  void Function(String message)? onFileWritten,
}) {
  // Write Kotlin files.
  if (config.hasKotlinConfig) {
    final kotlinDir = config.kotlinOutput!;

    if (result.kotlinRoutesCode != null) {
      final file = File(p.join(kotlinDir, 'Routes.g.kt'));
      file.parent.createSync(recursive: true);
      file.writeAsStringSync(result.kotlinRoutesCode!);
      onFileWritten?.call(file.path);
    }

    if (result.kotlinStoresCode != null) {
      final file = File(p.join(kotlinDir, 'Stores.g.kt'));
      file.parent.createSync(recursive: true);
      file.writeAsStringSync(result.kotlinStoresCode!);
      onFileWritten?.call(file.path);
    }
  }

  // Write Swift files.
  if (config.hasSwiftConfig) {
    final swiftDir = config.swiftOutput!;

    if (result.swiftRoutesCode != null) {
      final file = File(p.join(swiftDir, 'Routes.g.swift'));
      file.parent.createSync(recursive: true);
      file.writeAsStringSync(result.swiftRoutesCode!);
      onFileWritten?.call(file.path);
    }

    if (result.swiftStoresCode != null) {
      final file = File(p.join(swiftDir, 'Stores.g.swift'));
      file.parent.createSync(recursive: true);
      file.writeAsStringSync(result.swiftStoresCode!);
      onFileWritten?.call(file.path);
    }
  }
}
