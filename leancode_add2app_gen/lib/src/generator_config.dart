/// Configuration for the add2app code generator.
class GeneratorConfig {
  const GeneratorConfig({
    required this.input,
    this.dartOutput,
    this.kotlinOutput,
    this.swiftOutput,
  });

  /// Path to the Pigeon schema file.
  final String input;

  /// Directory where generated Dart files will be written.
  final String? dartOutput;

  /// Directory where generated Kotlin files will be written.
  final String? kotlinOutput;

  /// Directory where generated Swift files will be written.
  final String? swiftOutput;

  @override
  String toString() {
    return 'GeneratorConfig('
        'input: $input, '
        'dartOutput: $dartOutput, '
        'kotlinOutput: $kotlinOutput, '
        'swiftOutput: $swiftOutput)';
  }
}
