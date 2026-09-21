import 'dart:io';

import 'package:inlay_gen/src/config/generator_config.dart';
import 'package:inlay_gen/src/core/code_generator.dart';
import 'package:inlay_gen/src/core/generation_result.dart';
import 'package:path/path.dart' as p;

/// Runs the inlay code generator with the given [config].
void runGenerator(GeneratorConfig config) {
  stdout
    ..writeln('inlay_gen')
    ..writeln('====================')
    ..writeln('Routes:         ${config.routes ?? '(not specified)'}')
    ..writeln('Stores:         ${config.stores ?? '(not specified)'}')
    ..writeln('Dart output:    ${config.dartOutput ?? '(not specified)'}')
    ..writeln('Kotlin output:  ${config.kotlinOutput ?? '(not specified)'}')
    ..writeln('Kotlin package: ${config.kotlinPackage ?? '(not specified)'}')
    ..writeln('Java output:    ${config.javaOutput ?? '(not specified)'}')
    ..writeln('Java package:   ${config.javaPackage ?? '(not specified)'}')
    ..writeln('Swift output:   ${config.swiftOutput ?? '(not specified)'}')
    ..writeln();

  final codeGenerator = CodeGenerator();
  final sources = <(String, String?)>[];

  // Read routes file.
  if (config.routes != null) {
    final routesFile = File(config.routes!);
    if (!routesFile.existsSync()) {
      stderr.writeln('Error: Routes file not found: ${config.routes}');
      exit(1);
    }
    sources.add((routesFile.readAsStringSync(), config.routes));
  }

  // Read stores file.
  if (config.stores != null) {
    final storesFile = File(config.stores!);
    if (!storesFile.existsSync()) {
      stderr.writeln('Error: Stores file not found: ${config.stores}');
      exit(1);
    }
    sources.add((storesFile.readAsStringSync(), config.stores));
  }

  // Parse and validate all sources.
  final parseResult = codeGenerator.parseAndValidateMultiple(sources);

  switch (parseResult) {
    case ParseFailure(:final errors):
      stderr.writeln('Type resolution errors:');
      for (final error in errors) {
        stderr.writeln('  - $error');
      }
      exit(1);

    case ParseSuccess(:final schema, :final resolution):
      // Print summary.
      stdout
        ..writeln('Parsed:')
        ..writeln('  - ${schema.flutterRoutes.length} flutter route(s)')
        ..writeln(
          '  - ${schema.flutterDialogRoutes.length} flutter dialog route(s)',
        )
        ..writeln('  - ${schema.nativeRoutes.length} native route(s)')
        ..writeln('  - ${schema.stores.length} store(s)')
        ..writeln('  - ${schema.dataClasses.length} data class(es)')
        ..writeln('  - ${schema.enums.length} enum(s)')
        ..writeln();

      // Generate code.
      final result = codeGenerator.generate(
        schema: schema,
        typeGraph: resolution.typeGraph,
        kotlinPackage: config.kotlinPackage,
        javaPackage: config.javaPackage,
        dartHeader: config.dartHeader ?? const [],
        kotlinHeader: config.kotlinHeader ?? const [],
        javaHeader: config.javaHeader ?? const [],
        swiftHeader: config.swiftHeader ?? const [],
      );

      if (!result.hasContent) {
        stdout.writeln('No routes or stores found — nothing to generate.');
        return;
      }

      stdout.writeln('Generating...');

      // Write Dart files.
      if (config.dartOutput != null) {
        _writeDartFiles(result, config.dartOutput!);
      }

      // Write native files (Kotlin/Java/Swift).
      writeNativeFiles(
        result,
        NativeOutputConfig(
          kotlinOutput: config.kotlinOutput,
          kotlinPackage: config.kotlinPackage,
          javaOutput: config.javaOutput,
          javaPackage: config.javaPackage,
          swiftOutput: config.swiftOutput,
        ),
        onFileWritten: (path) => stdout.writeln('  $path'),
      );

      stdout
        ..writeln()
        ..writeln('Done.');
  }
}

void _writeDartFiles(GenerationResult result, String outputDir) {
  if (result.dartRoutesCode != null) {
    final file = File(p.join(outputDir, 'routes.g.dart'));
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(result.dartRoutesCode!);
    stdout.writeln('  ${file.path}');
  }

  if (result.dartStoresCode != null) {
    final file = File(p.join(outputDir, 'stores.g.dart'));
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(result.dartStoresCode!);
    stdout.writeln('  ${file.path}');
  }
}
