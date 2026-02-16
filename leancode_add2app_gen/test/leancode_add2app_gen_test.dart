import 'package:leancode_add2app_gen/leancode_add2app_gen.dart';
import 'package:test/test.dart';

const _schemaSource = '''
// add2app: flutter_page
class SoundsNotificationsPage {
  SoundsNotificationsPage({required this.contactId});

  final String contactId;
}

// add2app: flutter_page
class SetWallpaperPage {
  SetWallpaperPage({required this.recipientId});

  final String recipientId;
}

// add2app: native_page
class NativeEditProfilePage {
  NativeEditProfilePage({required this.contactId});

  final String contactId;
}

// add2app: native_page
class NativeMediaViewerPage {
  NativeMediaViewerPage({required this.mediaId, this.mediaType});

  final String mediaId;
  final String? mediaType;
}
''';

void main() {
  late SchemaParser parser;

  setUp(() {
    parser = SchemaParser();
  });

  test('parses all tagged classes from schema', () {
    final pages = parser.parse(_schemaSource);
    expect(pages, hasLength(4));
  });

  test('identifies native_page classes', () {
    final pages = parser.parse(_schemaSource);
    final nativePages =
        pages.where((p) => p.tag == PageTag.nativePage).toList();

    expect(nativePages, hasLength(2));
    expect(nativePages[0].className, 'NativeEditProfilePage');
    expect(nativePages[1].className, 'NativeMediaViewerPage');
  });

  test('identifies flutter_page classes', () {
    final pages = parser.parse(_schemaSource);
    final flutterPages =
        pages.where((p) => p.tag == PageTag.flutterPage).toList();

    expect(flutterPages, hasLength(2));
    expect(flutterPages[0].className, 'SoundsNotificationsPage');
    expect(flutterPages[1].className, 'SetWallpaperPage');
  });

  test('extracts fields with correct types and required-ness', () {
    final pages = parser.parse(_schemaSource);
    final mediaViewer =
        pages.firstWhere((p) => p.className == 'NativeMediaViewerPage');

    expect(mediaViewer.fields, hasLength(2));

    final mediaId = mediaViewer.fields[0];
    expect(mediaId.name, 'mediaId');
    expect(mediaId.dartType, 'String');
    expect(mediaId.isRequired, isTrue);
    expect(mediaId.isNullable, isFalse);

    final mediaType = mediaViewer.fields[1];
    expect(mediaType.name, 'mediaType');
    expect(mediaType.dartType, 'String');
    expect(mediaType.isRequired, isFalse);
    expect(mediaType.isNullable, isTrue);
  });

  test('ignores classes without add2app comment', () {
    const source = '''
class UntaggedPage {
  UntaggedPage({required this.id});
  final String id;
}

// add2app: native_page
class TaggedPage {
  TaggedPage({required this.id});
  final String id;
}
''';

    final pages = parser.parse(source);
    expect(pages, hasLength(1));
    expect(pages.first.className, 'TaggedPage');
  });

  test('generates Add2AppFlutterRoute wrappers for flutter_page classes', () {
    final pages = parser.parse(_schemaSource);
    final flutterPages =
        pages.where((p) => p.tag == PageTag.flutterPage).toList();

    final output = generateDartFlutterPages(flutterPages: flutterPages);

    expect(
      output,
      contains('class SoundsNotificationsPage extends Add2AppFlutterRoute'),
    );
    expect(output, contains("String get routeId => 'soundsNotifications';"));
    expect(output, contains("'contactId': contactId"));
  });

  test('generates nullable params as optional map entries', () {
    const source = '''
// add2app: flutter_page
class OptionalPage {
  OptionalPage({this.recipientId});

  final String? recipientId;
}
''';

    final pages = parser.parse(source);
    final flutterPages =
        pages.where((p) => p.tag == PageTag.flutterPage).toList();

    final output = generateDartFlutterPages(flutterPages: flutterPages);

    expect(
      output,
      contains("...?recipientId != null ? {'recipientId': recipientId!} : null"),
    );
  });
}
