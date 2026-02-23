import 'dart:async';
import 'dart:io';

import 'package:build/build.dart';
import 'package:leancode_add2app_gen/src/core/code_generator.dart';
import 'package:leancode_add2app_gen/src/core/generation_result.dart';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

/// Builder that generates Dart, Kotlin, and Swift code from add2app schema files.
///
/// Configuration is read from `add2app.yaml` in the package root.
class Add2AppBuilder implements Builder {
  /// Creates a new builder.
  Add2AppBuilder(BuilderOptions _);

  final CodeGenerator _codeGenerator = CodeGenerator();

  @override
  Map<String, List<String>> get buildExtensions => {
    r'$lib$': ['src/generated/routes.g.dart', 'src/generated/stores.g.dart'],
  };

  @override
  Future<void> build(BuildStep buildStep) async {
    // The builder runs in the package root directory.
    final packageRoot = Directory.current.path;
    log.info('Running add2app builder in: $packageRoot');

    // Load configuration from add2app.yaml.
    final configFile = File(p.join(packageRoot, 'add2app.yaml'));
    if (!configFile.existsSync()) {
      log.info('No add2app.yaml found, skipping generation.');
      return;
    }

    final config = _loadConfig(configFile);
    if (config == null) {
      log.warning('Invalid add2app.yaml, skipping generation.');
      return;
    }

    // Collect schema sources.
    final sources = <(String, String?)>[];

    if (config.routesPath case final routesPath?) {
      final routesFile = File(p.join(packageRoot, routesPath));
      if (routesFile.existsSync()) {
        final source = routesFile.readAsStringSync();
        sources.add((source, config.routesPath));
        log.info('Reading routes schema: ${config.routesPath}');
      } else {
        log.warning('Routes file not found: ${config.routesPath}');
      }
    }

    if (config.storesPath case final storesPath?) {
      final storesFile = File(p.join(packageRoot, storesPath));
      if (storesFile.existsSync()) {
        final source = storesFile.readAsStringSync();
        sources.add((source, config.storesPath));
        log.info('Reading stores schema: ${config.storesPath}');
      } else {
        log.warning('Stores file not found: ${config.storesPath}');
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
        );

        // Write Dart routes directly to filesystem.
        if (result.dartRoutesCode != null) {
          final dartOutput = config.dartOutput ?? 'lib/src/generated/';
          final outputPath = p.join(packageRoot, dartOutput, 'routes.g.dart');
          _writeFile(outputPath, result.dartRoutesCode!);
          log.info('Generated: $outputPath');
        }

        // Write Dart stores directly to filesystem.
        if (result.dartStoresCode != null) {
          final dartOutput = config.dartOutput ?? 'lib/src/generated/';
          final outputPath = p.join(packageRoot, dartOutput, 'stores.g.dart');
          _writeFile(outputPath, result.dartStoresCode!);
          log.info('Generated: $outputPath');
        }

        // Write native files (Kotlin/Swift) directly to filesystem.
        writeNativeFiles(
          result,
          NativeOutputConfig(
            kotlinOutput: config.kotlinOutput,
            kotlinPackage: config.kotlinPackage,
            swiftOutput: config.swiftOutput,
          ),
          onFileWritten: (path) => log.info('Generated: $path'),
        );
    }
  }

  void _writeFile(String path, String content) {
    final file = File(path);
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(content);
  }

  _BuildConfig? _loadConfig(File configFile) {
    final content = configFile.readAsStringSync();
    final yaml = loadYaml(content);
    if (yaml is! YamlMap) {
      return null;
    }

    final dartSection = yaml['dart'];
    final kotlinSection = yaml['kotlin'];
    final swiftSection = yaml['swift'];

    return _BuildConfig(
      routesPath: yaml['routes'] as String?,
      storesPath: yaml['stores'] as String?,
      dartOutput: dartSection is YamlMap
          ? dartSection['output'] as String?
          : null,
      kotlinOutput: kotlinSection is YamlMap
          ? kotlinSection['output'] as String?
          : null,
      kotlinPackage: kotlinSection is YamlMap
          ? kotlinSection['package'] as String?
          : null,
      swiftOutput: swiftSection is YamlMap
          ? swiftSection['output'] as String?
          : null,
    );
  }
}

class _BuildConfig {
  const _BuildConfig({
    this.routesPath,
    this.storesPath,
    this.dartOutput,
    this.kotlinOutput,
    this.kotlinPackage,
    this.swiftOutput,
  });

  final String? routesPath;
  final String? storesPath;
  final String? dartOutput;
  final String? kotlinOutput;
  final String? kotlinPackage;
  final String? swiftOutput;
}
