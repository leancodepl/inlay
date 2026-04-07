import 'package:build/build.dart';

import 'src/builder/inlay_builder.dart';

/// Builder factory for build_runner.
///
/// This builder generates Dart, Kotlin, and Swift code from inlay schema files.
/// Schema files are treated as **specs only** (like Pigeon) - app code imports
/// the generated files, not the schema files.
///
/// ## Usage
///
/// 1. Add `inlay_gen` to your `dev_dependencies` in `pubspec.yaml`:
///
/// ```yaml
/// dev_dependencies:
///   inlay_gen: ^1.0.0
///   build_runner: ^2.4.0
/// ```
///
/// 2. Create an `inlay.yaml` configuration file:
///
/// ```yaml
/// routes: lib/inlay/routes.dart
/// stores: lib/inlay/stores.dart
///
/// dart:
///   output: lib/src/generated/routes.g.dart
///
/// kotlin:
///   output: android/src/main/kotlin/com/example/generated/
///   package: com.example.app.generated
///
/// swift:
///   output: ios/Classes/Generated/
/// ```
///
/// 3. Create your schema files (these are specs, not imported by app code):
///
/// ```dart
/// // lib/inlay/routes.dart
/// import 'package:inlay/inlay.dart';
///
/// @InlayFlutterRoute()
/// class ContactDetailsPage {
///   const ContactDetailsPage({required this.contactId});
///   final String contactId;
/// }
/// ```
///
/// 4. Run the generator:
///
/// ```bash
/// dart run build_runner build
/// ```
///
/// 5. Import the generated files in your app code:
///
/// ```dart
/// import 'package:my_app/src/generated/routes.g.dart';
/// ```
Builder inlayBuilder(BuilderOptions options) => InlayBuilder(options);
