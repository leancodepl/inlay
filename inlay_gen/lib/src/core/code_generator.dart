import 'dart:io';

import 'package:inlay_gen/src/core/generation_result.dart';
import 'package:inlay_gen/src/generators/dart/dart_routes_generator.dart';
import 'package:inlay_gen/src/generators/dart/dart_store_generator.dart';
import 'package:inlay_gen/src/generators/java/java_routes_generator.dart';
import 'package:inlay_gen/src/generators/kotlin/kotlin_routes_generator.dart';
import 'package:inlay_gen/src/generators/kotlin/kotlin_store_generator.dart';
import 'package:inlay_gen/src/generators/swift/swift_routes_generator.dart';
import 'package:inlay_gen/src/generators/swift/swift_store_generator.dart';
import 'package:inlay_gen/src/models/schema.dart';
import 'package:inlay_gen/src/parser/annotation_parser.dart';
import 'package:inlay_gen/src/parser/type_resolver.dart';
import 'package:inlay_gen/src/utils/schema_fingerprint.dart';
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
    String? javaPackage,
    List<String> dartHeader = const [],
    List<String> kotlinHeader = const [],
    List<String> javaHeader = const [],
    List<String> swiftHeader = const [],
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

    // The fingerprint covers the full schema (routes + stores). It is
    // embedded into every outgoing PageSettings and verified automatically
    // on the receiving side; the constant lives in the routes file, or the
    // stores file for modules that only define stores.
    final fingerprint = computeSchemaFingerprint(schema);
    final storesFingerprint = hasRoutes ? null : fingerprint;

    return GenerationResult(
      schema: schema,
      typeGraph: typeGraph,
      dartRoutesCode: hasRoutes
          ? generateDartRoutes(
              schema: routeSchema,
              typeGraph: typeGraph,
              schemaFingerprint: fingerprint,
              header: dartHeader,
            )
          : null,
      dartStoresCode: hasStores
          ? generateDartStores(
              schema: storeSchema,
              typeGraph: typeGraph,
              schemaFingerprint: storesFingerprint,
              header: dartHeader,
            )
          : null,
      kotlinRoutesCode: hasRoutes && kotlinPackage != null
          ? generateKotlinRoutes(
              schema: routeSchema,
              typeGraph: typeGraph,
              packageName: kotlinPackage,
              schemaFingerprint: fingerprint,
              header: kotlinHeader,
            )
          : null,
      kotlinStoresCode: hasStores && kotlinPackage != null
          ? generateKotlinStores(
              schema: storeSchema,
              typeGraph: typeGraph,
              packageName: kotlinPackage,
              schemaFingerprint: storesFingerprint,
              header: kotlinHeader,
            )
          : null,
      javaRoutesCode: hasRoutes && javaPackage != null
          ? generateJavaRoutes(
              schema: routeSchema,
              typeGraph: typeGraph,
              packageName: javaPackage,
              schemaFingerprint: fingerprint,
              header: javaHeader,
            )
          : null,
      swiftRoutesCode: hasRoutes
          ? generateSwiftRoutes(
              schema: routeSchema,
              typeGraph: typeGraph,
              schemaFingerprint: fingerprint,
              header: swiftHeader,
            )
          : null,
      swiftStoresCode: hasStores
          ? generateSwiftStores(
              schema: storeSchema,
              typeGraph: typeGraph,
              schemaFingerprint: storesFingerprint,
              header: swiftHeader,
            )
          : null,
    );
  }

  /// Convenience method that parses, validates, and generates in one call.
  (GenerationResult?, List<GenerationError>) generateFromSource(
    String source, {
    String? path,
    String? kotlinPackage,
    String? javaPackage,
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
          javaPackage: javaPackage,
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
    this.javaOutput,
    this.javaPackage,
    this.swiftOutput,
  });

  /// The output directory for Kotlin files.
  final String? kotlinOutput;

  /// The Kotlin package name for generated files.
  final String? kotlinPackage;

  /// The output directory for Java files.
  final String? javaOutput;

  /// The Java package name for generated files.
  final String? javaPackage;

  /// The output directory for Swift files.
  final String? swiftOutput;

  /// Whether Kotlin generation is configured.
  bool get hasKotlinConfig => kotlinOutput != null && kotlinPackage != null;

  /// Whether Java generation is configured.
  bool get hasJavaConfig => javaOutput != null && javaPackage != null;

  /// Whether Swift generation is configured.
  bool get hasSwiftConfig => swiftOutput != null;
}

/// Writes native (Kotlin/Java/Swift) files to disk.
///
/// This is extracted as a separate function since both CLI and build_runner
/// need to write native files (build_runner only manages Dart output).
///
/// Java output is one file per class, so generated files that are no longer
/// produced (e.g. a removed route) are deleted from the Java directory -
/// only files carrying the inlay_gen header, never hand-written ones.
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

  // Write Java files (one per public class) and drop stale generated ones.
  if (config.hasJavaConfig) {
    final javaDir = Directory(config.javaOutput!);
    final javaFiles = result.javaRoutesCode;

    if (javaFiles != null) {
      for (final MapEntry(key: fileName, value: content) in javaFiles.entries) {
        final file = File(p.join(javaDir.path, fileName));
        file.parent.createSync(recursive: true);
        file.writeAsStringSync(content);
        onFileWritten?.call(file.path);
      }
    }

    if (javaDir.existsSync()) {
      for (final entity in javaDir.listSync()) {
        if (entity is! File || !entity.path.endsWith('.java')) {
          continue;
        }
        if (javaFiles?.containsKey(p.basename(entity.path)) ?? false) {
          continue;
        }
        if (_isGeneratedJavaFile(entity)) {
          entity.deleteSync();
          onFileWritten?.call('${entity.path} (removed - no longer generated)');
        }
      }
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

/// Whether [file] opens with the banner every generated Java file carries.
///
/// The banner may sit below the user-configured `header:` comment lines, so
/// the leading comment block is scanned; the first non-comment line ends it.
bool _isGeneratedJavaFile(File file) {
  try {
    for (final line in file.readAsLinesSync()) {
      if (line.contains('Generated by inlay_gen')) {
        return true;
      }
      if (line.trim().isNotEmpty && !line.trimLeft().startsWith('//')) {
        return false;
      }
    }
    return false;
  } on FileSystemException {
    return false;
  }
}
