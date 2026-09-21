import 'dart:convert';
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
    this.javaOutput,
    this.javaPackage,
    this.swiftOutput,
    this.dartHeader,
    this.kotlinHeader,
    this.javaHeader,
    this.swiftHeader,
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

  /// Directory where generated Java files will be written.
  final String? javaOutput;

  /// Java package name for generated files.
  final String? javaPackage;

  /// Directory where generated Swift files will be written.
  final String? swiftOutput;

  /// Comment lines emitted at the top of every generated Dart file
  /// (`dart: header:`), e.g. `ignore_for_file:` directives.
  final List<String>? dartHeader;

  /// Comment lines emitted at the top of every generated Kotlin file
  /// (`kotlin: header:`).
  final List<String>? kotlinHeader;

  /// Comment lines emitted at the top of every generated Java file
  /// (`java: header:`), e.g. Checkstyle suppressions.
  final List<String>? javaHeader;

  /// Comment lines emitted at the top of every generated Swift file
  /// (`swift: header:`), e.g. `swiftlint:disable all`.
  final List<String>? swiftHeader;

  /// Creates a copy of this config with the given values replaced.
  GeneratorConfig copyWith({
    String? routes,
    String? stores,
    String? dartOutput,
    String? kotlinOutput,
    String? kotlinPackage,
    String? javaOutput,
    String? javaPackage,
    String? swiftOutput,
    List<String>? dartHeader,
    List<String>? kotlinHeader,
    List<String>? javaHeader,
    List<String>? swiftHeader,
  }) {
    return GeneratorConfig(
      routes: routes ?? this.routes,
      stores: stores ?? this.stores,
      dartOutput: dartOutput ?? this.dartOutput,
      kotlinOutput: kotlinOutput ?? this.kotlinOutput,
      kotlinPackage: kotlinPackage ?? this.kotlinPackage,
      javaOutput: javaOutput ?? this.javaOutput,
      javaPackage: javaPackage ?? this.javaPackage,
      swiftOutput: swiftOutput ?? this.swiftOutput,
      dartHeader: dartHeader ?? this.dartHeader,
      kotlinHeader: kotlinHeader ?? this.kotlinHeader,
      javaHeader: javaHeader ?? this.javaHeader,
      swiftHeader: swiftHeader ?? this.swiftHeader,
    );
  }

  /// Merges CLI arguments over this config (CLI takes precedence).
  ///
  /// Headers have no CLI counterpart and are always kept from the file.
  GeneratorConfig mergeCliArgs({
    String? routes,
    String? stores,
    String? dartOutput,
    String? kotlinOutput,
    String? kotlinPackage,
    String? javaOutput,
    String? javaPackage,
    String? swiftOutput,
  }) {
    return GeneratorConfig(
      routes: routes ?? this.routes,
      stores: stores ?? this.stores,
      dartOutput: dartOutput ?? this.dartOutput,
      kotlinOutput: kotlinOutput ?? this.kotlinOutput,
      kotlinPackage: kotlinPackage ?? this.kotlinPackage,
      javaOutput: javaOutput ?? this.javaOutput,
      javaPackage: javaPackage ?? this.javaPackage,
      swiftOutput: swiftOutput ?? this.swiftOutput,
      dartHeader: dartHeader,
      kotlinHeader: kotlinHeader,
      javaHeader: javaHeader,
      swiftHeader: swiftHeader,
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
        'javaOutput: $javaOutput, '
        'javaPackage: $javaPackage, '
        'swiftOutput: $swiftOutput, '
        'dartHeader: $dartHeader, '
        'kotlinHeader: $kotlinHeader, '
        'javaHeader: $javaHeader, '
        'swiftHeader: $swiftHeader)';
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
/// # Optional - for hosts written in Java instead of Kotlin.
/// java:
///   output: android/src/main/java/com/example/generated/
///   package: com.example.app.generated
///   # Optional in every language section: comment lines that open each
///   # generated file (lint suppressions, license notice).
///   header:
///     - "CHECKSTYLE.OFF: LineLength|MagicNumber"
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
  final javaSection = yaml['java'];
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
    javaOutput: javaSection is YamlMap
        ? javaSection['output'] as String?
        : null,
    javaPackage: javaSection is YamlMap
        ? javaSection['package'] as String?
        : null,
    swiftOutput: swiftSection is YamlMap
        ? swiftSection['output'] as String?
        : null,
    dartHeader: _headerOf(dartSection),
    kotlinHeader: _headerOf(kotlinSection),
    javaHeader: _headerOf(javaSection),
    swiftHeader: _headerOf(swiftSection),
  );
}

/// Reads a language section's `header:` - a list of lines or one multi-line
/// string. `null` when absent.
List<String>? _headerOf(Object? section) {
  if (section is! YamlMap) {
    return null;
  }
  final header = section['header'];
  return switch (header) {
    YamlList() => header.map((line) => line.toString()).toList(),
    String() => const LineSplitter().convert(header),
    _ => null,
  };
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
