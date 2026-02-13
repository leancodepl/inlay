/// The kind of page declared in the schema via `// add2app: <tag>` comments.
enum PageTag {
  /// A Flutter page navigated to from native or Flutter.
  flutterPage('flutter_page'),

  /// A native page navigated to from Flutter.
  nativePage('native_page');

  const PageTag(this.value);

  /// The string value as written in the `// add2app:` comment.
  final String value;

  /// Parses a [PageTag] from the raw comment value string.
  /// Returns `null` if the value is not recognised.
  static PageTag? tryParse(String value) {
    for (final tag in PageTag.values) {
      if (tag.value == value.trim()) {
        return tag;
      }
    }
    return null;
  }
}
