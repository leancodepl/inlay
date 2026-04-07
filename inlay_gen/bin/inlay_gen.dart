import 'dart:io';

import 'package:args/args.dart';
import 'package:inlay_gen/inlay_gen.dart';

void main(List<String> arguments) {
  final parser = buildArgParser();

  try {
    final results = parser.parse(arguments);

    if (results['help'] as bool) {
      printUsage(parser);
      return;
    }

    // Load config from YAML file (if specified or found).
    final configPath = results['config'] as String?;
    GeneratorConfig config;

    if (configPath != null) {
      final file = File(configPath);
      if (!file.existsSync()) {
        stderr.writeln('Error: Config file not found: $configPath\n');
        exit(1);
      }
      config = loadYamlConfigFile(configPath);
    } else {
      // Try to find default config file.
      config = findAndLoadDefaultConfig();
    }

    // Override with CLI arguments (CLI takes precedence).
    config = config.mergeCliArgs(
      routes: results['routes'] as String?,
      stores: results['stores'] as String?,
      dartOutput: results['dart-output'] as String?,
      kotlinOutput: results['kotlin-output'] as String?,
      kotlinPackage: results['kotlin-package'] as String?,
      swiftOutput: results['swift-output'] as String?,
    );

    // Validate: at least one input file is required.
    if (config.routes == null && config.stores == null) {
      stderr.writeln(
        'Error: At least one input file is required.\n'
        'Provide --routes and/or --stores, or create an inlay.yaml config file.\n',
      );
      printUsage(parser);
      exit(1);
    }

    runGenerator(config);
  } on FormatException catch (e) {
    stderr.writeln('Error: ${e.message}\n');
    printUsage(parser);
    exit(1);
  }
}

ArgParser buildArgParser() {
  return ArgParser()
    ..addOption(
      'config',
      abbr: 'c',
      help: 'Path to YAML config file (default: inlay.yaml).',
      valueHelp: 'inlay.yaml',
    )
    ..addOption(
      'routes',
      abbr: 'r',
      help: 'Path to the routes schema file.',
      valueHelp: 'lib/inlay/routes.dart',
    )
    ..addOption(
      'stores',
      help: 'Path to the stores schema file.',
      valueHelp: 'lib/inlay/stores.dart',
    )
    ..addOption(
      'dart-output',
      abbr: 'd',
      help: 'Directory where generated Dart files will be written.',
      valueHelp: 'lib/src/generated/',
    )
    ..addOption(
      'kotlin-output',
      abbr: 'k',
      help: 'Directory where generated Kotlin files will be written.',
      valueHelp: 'android/src/main/kotlin/...',
    )
    ..addOption(
      'kotlin-package',
      abbr: 'p',
      help: 'Kotlin package name for generated files.',
      valueHelp: 'com.example.app.generated',
    )
    ..addOption(
      'swift-output',
      abbr: 's',
      help: 'Directory where generated Swift files will be written.',
      valueHelp: 'ios/Classes/',
    )
    ..addFlag(
      'help',
      abbr: 'h',
      negatable: false,
      help: 'Print this usage information.',
    );
}

void printUsage(ArgParser parser) {
  stdout
    ..writeln('Usage: inlay_gen [options]\n')
    ..writeln(
      'Generates Dart, Kotlin, and Swift code from inlay schema files.\n',
    )
    ..writeln('Options:')
    ..writeln(parser.usage)
    ..writeln()
    ..writeln('Configuration:')
    ..writeln('  Create an inlay.yaml file in your project root:')
    ..writeln()
    ..writeln('    routes: lib/inlay/routes.dart')
    ..writeln('    stores: lib/inlay/stores.dart')
    ..writeln()
    ..writeln('    dart:')
    ..writeln('      output: lib/src/generated/')
    ..writeln()
    ..writeln('    kotlin:')
    ..writeln('      output: android/src/main/kotlin/com/example/generated/')
    ..writeln('      package: com.example.app.generated')
    ..writeln()
    ..writeln('    swift:')
    ..writeln('      output: ios/Classes/Generated/')
    ..writeln()
    ..writeln('CLI arguments override values from the config file.');
}
