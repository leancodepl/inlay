import 'package:inlay_gen/src/config/generator_config.dart';
import 'package:test/test.dart';

void main() {
  group('parseYamlConfig', () {
    test('parses a full config', () {
      const yaml = '''
routes: lib/inlay/routes.dart
stores: lib/inlay/stores.dart

dart:
  output: lib/src/generated/

kotlin:
  output: android/src/main/kotlin/com/example/generated/
  package: com.example.app.generated

swift:
  output: ios/Classes/Generated/
''';

      final config = parseYamlConfig(yaml);

      expect(config.routes, 'lib/inlay/routes.dart');
      expect(config.stores, 'lib/inlay/stores.dart');
      expect(config.dartOutput, 'lib/src/generated/');
      expect(
        config.kotlinOutput,
        'android/src/main/kotlin/com/example/generated/',
      );
      expect(config.kotlinPackage, 'com.example.app.generated');
      expect(config.swiftOutput, 'ios/Classes/Generated/');
    });

    test('missing sections stay null (language skipped)', () {
      final config = parseYamlConfig('routes: lib/inlay/routes.dart');

      expect(config.routes, 'lib/inlay/routes.dart');
      expect(config.stores, isNull);
      expect(config.dartOutput, isNull);
      expect(config.kotlinOutput, isNull);
      expect(config.kotlinPackage, isNull);
      expect(config.swiftOutput, isNull);
    });

    test('non-map yaml yields an empty config', () {
      expect(parseYamlConfig('just a string').routes, isNull);
      expect(parseYamlConfig('- a\n- b').routes, isNull);
    });

    test('java section is optional and parsed like kotlin', () {
      final config = parseYamlConfig('''
routes: lib/inlay/routes.dart

java:
  output: android/src/main/java/com/example/generated/
  package: com.example.app.generated
''');

      expect(config.javaOutput, 'android/src/main/java/com/example/generated/');
      expect(config.javaPackage, 'com.example.app.generated');
      expect(
        parseYamlConfig('routes: lib/inlay/routes.dart').javaOutput,
        isNull,
      );
    });

    test('header accepts a list of lines or one multi-line string', () {
      final config = parseYamlConfig('''
java:
  output: android/generated/
  package: com.example
  header:
    - "CHECKSTYLE.OFF: LineLength"
    - "CHECKSTYLE.OFF: MagicNumber"
swift:
  output: ios/Generated/
  header: |
    swiftlint:disable all
    a second line
''');

      expect(config.javaHeader, [
        'CHECKSTYLE.OFF: LineLength',
        'CHECKSTYLE.OFF: MagicNumber',
      ]);
      expect(config.swiftHeader, ['swiftlint:disable all', 'a second line']);
      expect(config.dartHeader, isNull);
      expect(config.kotlinHeader, isNull);
    });

    test('kotlin section without package leaves package null', () {
      final config = parseYamlConfig('''
kotlin:
  output: android/generated/
''');

      expect(config.kotlinOutput, 'android/generated/');
      expect(config.kotlinPackage, isNull);
    });
  });

  group('mergeCliArgs', () {
    test('CLI arguments win over file values', () {
      const fileConfig = GeneratorConfig(
        routes: 'file_routes.dart',
        dartOutput: 'file_out/',
      );

      final merged = fileConfig.mergeCliArgs(routes: 'cli_routes.dart');

      expect(merged.routes, 'cli_routes.dart');
      expect(merged.dartOutput, 'file_out/');
    });
  });
}
