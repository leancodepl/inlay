/// Code generator for inlay Flutter projects.
///
/// This package provides:
/// - CLI tool for generating Dart/Kotlin/Java/Swift code from schema files
/// - build_runner integration via `InlayBuilder`
library;

export 'src/builder/inlay_builder.dart' show InlayBuilder;
export 'src/config/generator_config.dart'
    show
        GeneratorConfig,
        findAndLoadDefaultConfig,
        loadYamlConfigFile,
        parseYamlConfig;
export 'src/core/code_generator.dart' show NativeOutputConfig, writeNativeFiles;
export 'src/generator.dart' show runGenerator;
