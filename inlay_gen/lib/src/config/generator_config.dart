import 'dart:io';

import 'package:yaml/yaml.dart';

/// Configuration for the inlay code generator.
class GeneratorConfig {
  /// Creates a new generator configuration.
  const GeneratorConfig({
    this.routes,
    this.stores,
    this.dartOutput,
    this.kotlinOutput,
    this.kotlinPackage,
    this.swiftOutput,
  });

  /// Path to the routes schema file.
  final String? routes;

  /// Path to the stores schema file.
  final String? stores;

  /// Directory where generated Dart files will be written.
  final String? dartOutput;

  /// Directory where generated Kotlin files will be written.
  final String? kotlinOutput;

  /// Kotlin package name for generated files.
  final String? kotlinPackage;

  /// Directory where generated Swift files will be written.
  final String? swiftOutput;

  /// Creates a copy of this config with the given values replaced.
  GeneratorConfig copyWith({
    String? routes,
    String? stores,
    String? dartOutput,
    String? kotlinOutput,
    String? kotlinPackage,
    String? swiftOutput,
  }) {
    return GeneratorConfig(
      routes: routes ?? this.routes,
      stores: stores ?? this.stores,
      dartOutput: dartOutput ?? this.dartOutput,
      kotlinOutput: kotlinOutput ?? this.kotlinOutput,
      kotlinPackage: kotlinPackage ?? this.kotlinPackage,
      swiftOutput: swiftOutput ?? this.swiftOutput,
    );
  }

  /// Merges CLI arguments over this config (CLI takes precedence).
  GeneratorConfig mergeCliArgs({
    String? routes,
    String? stores,
    String? dartOutput,
    String? kotlinOutput,
    String? kotlinPackage,
    String? swiftOutput,
  }) {
    return GeneratorConfig(
      routes: routes ?? this.routes,
      stores: stores ?? this.stores,
      dartOutput: dartOutput ?? this.dartOutput,
      kotlinOutput: kotlinOutput ?? this.kotlinOutput,
      kotlinPackage: kotlinPackage ?? this.kotlinPackage,
      swiftOutput: swiftOutput ?? this.swiftOutput,
    );
  }

  @override
  String toString() {
    return 'GeneratorConfig('
        'routes: $routes, '
        'stores: $stores, '
        'dartOutput: $dartOutput, '
        'kotlinOutput: $kotlinOutput, '
        'kotlinPackage: $kotlinPackage, '
        'swiftOutput: $swiftOutput)';
  }
}

/// Parses a YAML config file into [GeneratorConfig].
///
/// Example YAML format:
/// ```yaml
/// routes: lib/inlay/routes.dart
/// stores: lib/inlay/stores.dart
///
/// dart:
///   output: lib/src/generated/
///
/// kotlin:
///   output: android/src/main/kotlin/com/example/generated/
///   package: com.example.app.generated
///
/// swift:
///   output: ios/Classes/Generated/
/// ```
GeneratorConfig parseYamlConfig(String content) {
  final yaml = loadYaml(content);

  if (yaml is! YamlMap) {
    return const GeneratorConfig();
  }

  final dartSection = yaml['dart'];
  final kotlinSection = yaml['kotlin'];
  final swiftSection = yaml['swift'];

  return GeneratorConfig(
    routes: yaml['routes'] as String?,
    stores: yaml['stores'] as String?,
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

/// Loads config from a YAML file at [path].
///
/// Returns an empty config if the file doesn't exist.
GeneratorConfig loadYamlConfigFile(String path) {
  final file = File(path);
  if (!file.existsSync()) {
    return const GeneratorConfig();
  }
  return parseYamlConfig(file.readAsStringSync());
}

/// Tries to find and load the default config file (`inlay.yaml`).
///
/// Looks in the current directory and parent directories up to 3 levels.
/// Returns an empty config if no config file is found.
GeneratorConfig findAndLoadDefaultConfig() {
  const configFileName = 'inlay.yaml';
  var dir = Directory.current;

  for (var i = 0; i < 4; i++) {
    final configFile = File('${dir.path}/$configFileName');
    if (configFile.existsSync()) {
      return parseYamlConfig(configFile.readAsStringSync());
    }
    final parent = dir.parent;
    if (parent.path == dir.path) {
      break;
    }
    dir = parent;
  }

  return const GeneratorConfig();
}
