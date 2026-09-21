/// First line of every generated Dart file: exempts it from `dart format`.
///
/// Generated code is not meant to be formatter-clean, and the formatter's
/// output changes between SDK releases; without this directive every
/// regeneration (or SDK bump) would need a formatting pass and produce
/// noisy diffs. `dart format --set-exit-if-changed` leaves such files alone.
const dartFormatOff = '// dart format off\n';

/// Renders the user-configured `header:` lines that open every generated
/// file of a language, one `//` comment per line.
///
/// Configured per language in `inlay.yaml`, e.g. lint suppressions for code
/// that is generated rather than hand-written (`CHECKSTYLE.OFF: ...`,
/// `swiftlint:disable all`, `ignore_for_file: ...`) or a license notice. A
/// line may already carry the `//` prefix; it is not doubled.
String renderFileHeader(List<String> lines) {
  if (lines.isEmpty) {
    return '';
  }
  final buffer = StringBuffer();
  for (final line in lines) {
    final text = line.replaceFirst(RegExp(r'^//\s?'), '');
    buffer.writeln(text.isEmpty ? '//' : '// $text');
  }
  return buffer.toString();
}
