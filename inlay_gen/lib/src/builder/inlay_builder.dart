import 'dart:async';
import 'dart:io';

import 'package:build/build.dart';
import 'package:inlay_gen/src/config/generator_config.dart';
import 'package:inlay_gen/src/core/code_generator.dart';
import 'package:inlay_gen/src/core/generation_result.dart';
import 'package:path/path.dart' as p;

/// Builder that generates Dart, Kotlin, Java, and Swift code from inlay
/// schema files.
///
/// Configuration is read from `inlay.yaml` in the package root.
///
/// The Dart outputs are written through the [BuildStep] whenever they land
/// on the paths declared in `build.yaml` (the default `lib/src/generated/`),
/// so build_runner tracks them in its asset graph and other builders in the
/// same build - e.g. `go_router_builder` resolving a routes file that
/// imports the generated route classes - can read them. Native outputs live
/// outside the Dart package and are always written straight to disk.
class InlayBuilder implements Builder {
  /// Creates a new builder.
  InlayBuilder(BuilderOptions _);

  final CodeGenerator _codeGenerator = CodeGenerator();

  static const _defaultDartOutput = 'lib/src/generated/';
  static const _routesFile = 'routes.g.dart';
  static const _storesFile = 'stores.g.dart';

  @override
  Map<String, List<String>> get buildExtensions => {
    r'$lib$': ['src/generated/$_routesFile', 'src/generated/$_storesFile'],
  };

  @override
  Future<void> build(BuildStep buildStep) async {
    // The builder runs in the package root directory.
    final packageRoot = Directory.current.path;
    log.info('Running inlay builder in: $packageRoot');

    // Load configuration from inlay.yaml.
    final configFile = File(p.join(packageRoot, 'inlay.yaml'));
    if (!configFile.existsSync()) {
      log.info('No inlay.yaml found, skipping generation.');
      return;
    }

    final config = parseYamlConfig(configFile.readAsStringSync());

    // Collect schema sources.
    final sources = <(String, String?)>[];

    if (config.routes case final routesPath?) {
      final routesFile = File(p.join(packageRoot, routesPath));
      if (routesFile.existsSync()) {
        final source = routesFile.readAsStringSync();
        sources.add((source, config.routes));
        log.info('Reading routes schema: ${config.routes}');
      } else {
        log.warning('Routes file not found: ${config.routes}');
      }
    }

    if (config.stores case final storesPath?) {
      final storesFile = File(p.join(packageRoot, storesPath));
      if (storesFile.existsSync()) {
        final source = storesFile.readAsStringSync();
        sources.add((source, config.stores));
        log.info('Reading stores schema: ${config.stores}');
      } else {
        log.warning('Stores file not found: ${config.stores}');
      }
    }

    if (sources.isEmpty) {
      log.info('No schema files found.');
      return;
    }

    // Parse and validate.
    final parseResult = _codeGenerator.parseAndValidateMultiple(sources);

    switch (parseResult) {
      case ParseFailure(:final errors):
        for (final error in errors) {
          log.severe('Schema error: $error');
        }
        return;

      case ParseSuccess(:final schema, :final resolution):
        // Generate code.
        final result = _codeGenerator.generate(
          schema: schema,
          typeGraph: resolution.typeGraph,
          kotlinPackage: config.kotlinPackage,
          javaPackage: config.javaPackage,
          dartHeader: config.dartHeader ?? const [],
          kotlinHeader: config.kotlinHeader ?? const [],
          javaHeader: config.javaHeader ?? const [],
          swiftHeader: config.swiftHeader ?? const [],
        );

        final dartOutput = config.dartOutput ?? _defaultDartOutput;
        if (result.dartRoutesCode != null) {
          await _writeDart(
            buildStep,
            packageRoot,
            dartOutput,
            _routesFile,
            result.dartRoutesCode!,
          );
        }
        if (result.dartStoresCode != null) {
          await _writeDart(
            buildStep,
            packageRoot,
            dartOutput,
            _storesFile,
            result.dartStoresCode!,
          );
        }

        // Native files live outside the Dart package - write them directly.
        final javaOutput = config.javaOutput;
        writeNativeFiles(
          result,
          NativeOutputConfig(
            kotlinOutput: config.kotlinOutput,
            kotlinPackage: config.kotlinPackage,
            javaOutput: javaOutput != null
                ? p.normalize(p.join(packageRoot, javaOutput))
                : null,
            javaPackage: config.javaPackage,
            swiftOutput: config.swiftOutput,
          ),
          onFileWritten: (path) => log.info('Generated: $path'),
        );
    }
  }

  /// Writes a Dart output through [buildStep] when it lands on a declared
  /// build extension, so the asset graph tracks it; otherwise straight to
  /// disk, like the native outputs.
  Future<void> _writeDart(
    BuildStep buildStep,
    String packageRoot,
    String dartOutput,
    String fileName,
    String content,
  ) async {
    final relativePath = p.posix.normalize(
      p.posix.join(p.posix.joinAll(p.split(dartOutput)), fileName),
    );
    final declared = buildExtensions[r'$lib$']!.map(
      (extension) => p.posix.join('lib', extension),
    );

    if (declared.contains(relativePath)) {
      final assetId = AssetId(buildStep.inputId.package, relativePath);
      await buildStep.writeAsString(assetId, content);
      log.info('Generated: $relativePath');
      return;
    }

    final outputPath = p.join(packageRoot, dartOutput, fileName);
    _writeFile(outputPath, content);
    log.info(
      'Generated: $outputPath (outside the declared build extensions - '
      'other builders cannot see it in this build)',
    );
  }

  void _writeFile(String path, String content) {
    final file = File(path);
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(content);
  }
}
