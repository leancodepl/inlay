/// A single field on a page class from the schema.
class PageField {
  const PageField({
    required this.name,
    required this.dartType,
    required this.isRequired,
    required this.isNullable,
  });

  /// The field name (e.g. `contactId`).
  final String name;

  /// The Dart type as written in the source (e.g. `String`, `int`).
  final String dartType;

  /// Whether the field is marked `required` in the constructor.
  final bool isRequired;

  /// Whether the field type is nullable (e.g. `String?`).
  final bool isNullable;

  @override
  String toString() =>
      'PageField($name: $dartType${isNullable ? '?' : ''}'
      '${isRequired ? ', required' : ''})';
}
