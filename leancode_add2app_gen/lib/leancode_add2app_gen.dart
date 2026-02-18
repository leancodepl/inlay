/// Code generator for add2app Flutter projects.
///
/// This package provides:
/// - CLI tool for generating Dart/Kotlin/Swift code from schema files
/// - build_runner integration via `Add2AppBuilder`
library;

export 'src/builder/add2app_builder.dart' show Add2AppBuilder;
export 'src/config/generator_config.dart'
    show
        GeneratorConfig,
        findAndLoadDefaultConfig,
        loadYamlConfigFile,
        parseYamlConfig;
export 'src/core/code_generator.dart' show NativeOutputConfig, writeNativeFiles;
export 'src/generator.dart' show runGenerator;
