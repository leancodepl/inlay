import 'dart:io';

import 'package:path/path.dart' as p;

import 'package:leancode_add2app_gen/src/generator_config.dart';
import 'package:leancode_add2app_gen/src/generators/dart_flutter_pages_generator.dart';
import 'package:leancode_add2app_gen/src/generators/dart_native_pages_generator.dart';
import 'package:leancode_add2app_gen/src/generators/kotlin_native_route_handler_generator.dart';
import 'package:leancode_add2app_gen/src/generators/swift_native_route_handler_generator.dart';
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

  if (flutterPages.isEmpty && nativePages.isEmpty) {
    stdout.writeln(
      'No flutter_page or native_page classes found — nothing to generate.',
    );
    return;
  }

  // ── Generate Dart ──────────────────────────────────────────────────

  if (config.dartOutput != null) {
    if (flutterPages.isNotEmpty) {
      final flutterPagesCode = generateDartFlutterPages(
        flutterPages: flutterPages,
      );

      final flutterPagesFile = File(
        p.join(config.dartOutput!, 'flutter_routes.g.dart'),
      );
      flutterPagesFile.parent.createSync(recursive: true);
      flutterPagesFile.writeAsStringSync(flutterPagesCode);
      stdout.writeln('  Dart:   ${flutterPagesFile.path}');
    }

    if (nativePages.isNotEmpty) {
      final pigeonImport = pigeonConfig.dartOutFilename ?? 'pages.g.dart';
      final nativeRoutesCode = generateDartNativePages(
        nativePages: nativePages,
        pigeonDartImport: pigeonImport,
      );

      final nativeRoutesFile = File(
        p.join(config.dartOutput!, 'native_routes.g.dart'),
      );
      nativeRoutesFile.parent.createSync(recursive: true);
      nativeRoutesFile.writeAsStringSync(nativeRoutesCode);
      stdout.writeln('  Dart:   ${nativeRoutesFile.path}');
    }
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

  // ── Generate Swift ───────────────────────────────────────────────

  if (config.swiftOutput != null) {
    final swiftCode = generateSwiftNativeRouteHandler(
      nativePages: nativePages,
    );

    final swiftFile = File(
      p.join(config.swiftOutput!, 'NativeRouteHandler.g.swift'),
    );
    swiftFile.parent.createSync(recursive: true);
    swiftFile.writeAsStringSync(swiftCode);
    stdout.writeln('  Swift:  ${swiftFile.path}');
  }

  stdout.writeln();
  stdout.writeln('Done.');
}
