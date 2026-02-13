import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart' show CommentToken;
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:leancode_add2app_gen/src/models/page_definition.dart';
import 'package:leancode_add2app_gen/src/models/page_field.dart';
import 'package:leancode_add2app_gen/src/models/page_tag.dart';

/// Parses a Dart schema file and extracts [PageDefinition]s from it.
///
/// Uses the `analyzer` package to build a full AST of the source file, then
/// walks every class declaration looking for a preceding
/// `// add2app: <tag>` comment.
class SchemaParser {
  /// Parses the given [source] code and returns all page definitions found.
  ///
  /// [path] is used only for error messages and diagnostics.
  List<PageDefinition> parse(String source, {String? path}) {
    final parseResult = parseString(
      content: source,
      path: path,
    );

    final unit = parseResult.unit;
    final visitor = _PageCollectorVisitor();
    unit.visitChildren(visitor);

    return visitor.pages;
  }
}

/// AST visitor that collects class declarations preceded by
/// `// add2app: <tag>` comments.
class _PageCollectorVisitor extends RecursiveAstVisitor<void> {
  final List<PageDefinition> pages = [];

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    final tag = _extractTag(node);
    if (tag == null) {
      // No add2app comment — skip this class.
      super.visitClassDeclaration(node);
      return;
    }

    final fields = _extractFields(node);

    pages.add(
      PageDefinition(
        className: node.namePart.typeName.lexeme,
        tag: tag,
        fields: fields,
      ),
    );

    super.visitClassDeclaration(node);
  }

  /// Looks at the comments preceding [node] for a line matching
  /// `// add2app: <value>` and returns the parsed [PageTag], or `null`.
  PageTag? _extractTag(ClassDeclaration node) {
    // The `// add2app:` comment is always right before the `class` keyword.
    // Using `firstTokenAfterCommentAndMetadata` gives us the `class` token
    // regardless of whether the node has metadata annotations or not.
    // Its `precedingComments` chain includes comments between any metadata
    // and the `class` keyword.
    final classToken = node.firstTokenAfterCommentAndMetadata;

    var comment = classToken.precedingComments;
    while (comment != null) {
      final text = comment.toString().trim();
      final match = _add2appPattern.firstMatch(text);
      if (match != null) {
        final tagValue = match.group(1)!;
        return PageTag.tryParse(tagValue);
      }
      // precedingComments returns CommentToken?, but next returns Token?.
      // In a preceding-comment chain the next token is always a CommentToken.
      final next = comment.next;
      comment = next is CommentToken ? next : null;
    }

    return null;
  }

  /// Extracts all fields from the class by looking at field declarations.
  List<PageField> _extractFields(ClassDeclaration node) {
    final fields = <PageField>[];

    final body = node.body;
    if (body is! BlockClassBody) return fields;

    final members = body.members;

    // Collect required-ness info from the constructor parameters.
    final requiredParams = <String>{};
    for (final member in members) {
      if (member is ConstructorDeclaration) {
        for (final param in member.parameters.parameters) {
          if (param.isRequired) {
            final name = param.name?.lexeme;
            if (name != null) {
              requiredParams.add(name);
            }
          }
        }
      }
    }

    // Collect field declarations.
    for (final member in members) {
      if (member is FieldDeclaration) {
        final typeAnnotation = member.fields.type;
        if (typeAnnotation == null) continue;

        for (final variable in member.fields.variables) {
          final fieldName = variable.name.lexeme;
          final dartType = typeAnnotation.toSource();
          final isNullable = typeAnnotation.question != null;
          final isRequired = requiredParams.contains(fieldName);

          fields.add(
            PageField(
              name: fieldName,
              dartType: dartType.replaceAll('?', ''),
              isRequired: isRequired,
              isNullable: isNullable,
            ),
          );
        }
      }
    }

    return fields;
  }

  static final _add2appPattern = RegExp(r'//\s*add2app:\s*(\S+)');
}
