import 'package:path/path.dart' as p;

/// Pigeon configuration extracted from `@ConfigurePigeon` in the schema source.
class PigeonConfig {
  const PigeonConfig({this.dartOut, this.kotlinPackage});

  /// The `dartOut` path from `PigeonOptions` (e.g. `lib/src/navigator/pages.g.dart`).
  final String? dartOut;

  /// The Kotlin package from `KotlinOptions` (e.g. `co.leancode.signal_module.navigator`).
  final String? kotlinPackage;

  /// The filename of the pigeon-generated Dart file (e.g. `pages.g.dart`).
  String? get dartOutFilename =>
      dartOut != null ? p.basename(dartOut!) : null;
}

/// Parses pigeon configuration from the raw schema source text.
///
/// Uses simple regex matching — does NOT evaluate the annotation AST.
PigeonConfig parsePigeonConfig(String source) {
  final dartOutMatch = _dartOutPattern.firstMatch(source);
  final packageMatch = _kotlinPackagePattern.firstMatch(source);

  return PigeonConfig(
    dartOut: dartOutMatch?.group(1),
    kotlinPackage: packageMatch?.group(1),
  );
}

final _dartOutPattern = RegExp(r"dartOut:\s*'([^']+)'");

// Match `package:` inside a KotlinOptions context.
final _kotlinPackagePattern = RegExp(r"package:\s*'([^']+)'");
