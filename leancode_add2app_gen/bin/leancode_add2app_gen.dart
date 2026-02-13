import 'dart:io';

import 'package:args/args.dart';
import 'package:leancode_add2app_gen/leancode_add2app_gen.dart';

void main(List<String> arguments) {
  final parser = buildArgParser();

  try {
    final results = parser.parse(arguments);

    if (results['help'] as bool) {
      printUsage(parser);
      return;
    }

    final input = results['input'] as String?;
    final dartOutput = results['dart-output'] as String?;
    final kotlinOutput = results['kotlin-output'] as String?;
    final swiftOutput = results['swift-output'] as String?;

    if (input == null) {
      stderr.writeln('Error: --input is required.\n');
      printUsage(parser);
      exit(1);
    }

    final config = GeneratorConfig(
      input: input,
      dartOutput: dartOutput,
      kotlinOutput: kotlinOutput,
      swiftOutput: swiftOutput,
    );

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
      'input',
      abbr: 'i',
      help: 'Path to the Pigeon schema file (required).',
      valueHelp: 'path/to/schema.dart',
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
  stdout.writeln('Usage: leancode_add2app_gen [options]\n');
  stdout.writeln(
    'Generates Dart, Kotlin, and Swift code from a Pigeon schema file.\n',
  );
  stdout.writeln(parser.usage);
}
