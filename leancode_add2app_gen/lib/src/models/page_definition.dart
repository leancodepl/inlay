import 'package:leancode_add2app_gen/src/models/page_field.dart';
import 'package:leancode_add2app_gen/src/models/page_tag.dart';

/// A parsed page class from the schema file.
class PageDefinition {
  const PageDefinition({
    required this.className,
    required this.tag,
    required this.fields,
  });

  /// The class name (e.g. `NativeEditProfilePage`).
  final String className;

  /// The tag from the `// add2app:` comment.
  final PageTag tag;

  /// The fields declared in the class.
  final List<PageField> fields;

  @override
  String toString() =>
      'PageDefinition($className, tag: ${tag.value}, '
      'fields: [${fields.join(', ')}])';
}
