import 'dart:io';

import 'package:path/path.dart' as p;

import 'package:leancode_add2app_gen/src/generator_config.dart';
import 'package:leancode_add2app_gen/src/generators/dart_native_pages_generator.dart';
import 'package:leancode_add2app_gen/src/generators/kotlin_native_route_handler_generator.dart';
import 'package:leancode_add2app_gen/src/models/page_tag.dart';
import 'package:leancode_add2app_gen/src/schema_parser.dart';
import 'package:leancode_add2app_gen/src/utils/pigeon_config.dart';

/// Runs the add2app code generator with the given [config].
void runGenerator(GeneratorConfig config) {
  stdout.writeln('leancode_add2app_gen');
  stdout.writeln('====================');
  stdout.writeln('Input:         ${config.input}');
  stdout.writeln('Dart output:   ${config.dartOutput ?? '(not specified)'}');
  stdout.writeln('Kotlin output: ${config.kotlinOutput ?? '(not specified)'}');
  stdout.writeln('Swift output:  ${config.swiftOutput ?? '(not specified)'}');
  stdout.writeln();

  final inputFile = File(config.input);
  if (!inputFile.existsSync()) {
    stderr.writeln('Error: Input file not found: ${config.input}');
    exit(1);
  }

  final source = inputFile.readAsStringSync();

  // Parse schema.
  final parser = SchemaParser();
  final pages = parser.parse(source, path: config.input);
  final pigeonConfig = parsePigeonConfig(source);

  final nativePages =
      pages.where((p) => p.tag == PageTag.nativePage).toList();
  final flutterPages =
      pages.where((p) => p.tag == PageTag.flutterPage).toList();

  stdout.writeln('Found ${pages.length} page(s) total:');
  stdout.writeln('  - ${flutterPages.length} flutter_page(s)');
  stdout.writeln('  - ${nativePages.length} native_page(s)');

  if (pigeonConfig.dartOut != null) {
    stdout.writeln('Pigeon dartOut: ${pigeonConfig.dartOut}');
  }
  if (pigeonConfig.kotlinPackage != null) {
    stdout.writeln('Kotlin package: ${pigeonConfig.kotlinPackage}');
  }

  stdout.writeln();

  if (nativePages.isEmpty) {
    stdout.writeln('No native_page classes found — nothing to generate.');
    return;
  }

  // ── Generate Dart ──────────────────────────────────────────────────

  if (config.dartOutput != null) {
    final pigeonImport = pigeonConfig.dartOutFilename ?? 'pages.g.dart';
    final dartCode = generateDartNativePages(
      nativePages: nativePages,
      pigeonDartImport: pigeonImport,
    );

    final dartFile = File(
      p.join(config.dartOutput!, 'native_routes.g.dart'),
    );
    dartFile.parent.createSync(recursive: true);
    dartFile.writeAsStringSync(dartCode);
    stdout.writeln('  Dart:   ${dartFile.path}');
  }

  // ── Generate Kotlin ────────────────────────────────────────────────

  if (config.kotlinOutput != null) {
    final kotlinPackage = pigeonConfig.kotlinPackage;
    if (kotlinPackage == null) {
      stderr.writeln(
        'Error: Could not determine Kotlin package from '
        '@ConfigurePigeon. Add kotlinOptions with a package.',
      );
      exit(1);
    }

    final kotlinCode = generateKotlinNativeRouteHandler(
      nativePages: nativePages,
      kotlinPackage: kotlinPackage,
    );

    final kotlinFile = File(
      p.join(config.kotlinOutput!, 'NativeRouteHandler.g.kt'),
    );
    kotlinFile.parent.createSync(recursive: true);
    kotlinFile.writeAsStringSync(kotlinCode);
    stdout.writeln('  Kotlin: ${kotlinFile.path}');
  }

  // ── Generate Swift (TODO) ──────────────────────────────────────────

  if (config.swiftOutput != null) {
    stdout.writeln('  Swift:  (not yet implemented)');
  }

  stdout.writeln();
  stdout.writeln('Done.');
}
