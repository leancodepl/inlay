import 'package:inlay_gen/src/generators/java/java_routes_generator.dart';
import 'package:inlay_gen/src/generators/java/java_serialization.dart';
import 'package:inlay_gen/src/models/data_type_definition.dart';
import 'package:inlay_gen/src/models/route_definition.dart';
import 'package:inlay_gen/src/models/schema.dart';
import 'package:inlay_gen/src/models/type_info.dart';
import 'package:inlay_gen/src/parser/type_resolver.dart';
import 'package:test/test.dart';

const _string = TypeInfo(name: 'String', isNullable: false);
const _int = TypeInfo(name: 'int', isNullable: false);
const _bool = TypeInfo(name: 'bool', isNullable: false);
const _nullableStyle = TypeInfo(name: 'GreetingStyle', isNullable: true);
const _nullableBadges = TypeInfo(
  name: 'List',
  isNullable: true,
  typeArguments: [TypeInfo(name: 'Badge', isNullable: false)],
);

final _typeGraph = <String, TypeDefinition>{
  'GreetingStyle': const EnumType(
    name: 'GreetingStyle',
    values: ['formal', 'casual'],
  ),
  'Badge': const DataClassType(
    name: 'Badge',
    fields: [
      FieldInfo(name: 'label', type: _string, isRequired: true),
      FieldInfo(
        name: 'level',
        type: TypeInfo(name: 'GreetingStyle', isNullable: false),
        isRequired: true,
      ),
    ],
  ),
};

const _schema = Schema(
  enums: [
    EnumDefinition(name: 'GreetingStyle', values: ['formal', 'casual']),
  ],
  dataClasses: [
    DataClassDefinition(
      className: 'Badge',
      fields: [
        FieldInfo(name: 'label', type: _string, isRequired: true),
        FieldInfo(
          name: 'level',
          type: TypeInfo(name: 'GreetingStyle', isNullable: false),
          isRequired: true,
        ),
      ],
    ),
  ],
  flutterRoutes: [
    RouteDefinition(
      className: 'GreetingPage',
      routeType: RouteType.flutter,
      routeName: '/greeting/:name',
      path: '/greeting/:name',
      fields: [
        FieldInfo(name: 'name', type: _string, isRequired: true),
        FieldInfo(name: 'style', type: _nullableStyle, isRequired: false),
        FieldInfo(name: 'badges', type: _nullableBadges, isRequired: false),
      ],
    ),
    RouteDefinition(
      className: 'CounterPage',
      routeType: RouteType.flutter,
      routeName: '/counter',
      path: '/counter',
      resultType: _int,
      fields: [
        FieldInfo(
          name: 'seed',
          type: TypeInfo(name: 'int', isNullable: true),
          isRequired: false,
        ),
      ],
    ),
    RouteDefinition(
      className: 'SettingsPage',
      routeType: RouteType.flutter,
      routeName: '/settings',
      path: '/settings',
      fields: [],
    ),
  ],
  flutterDialogRoutes: [
    RouteDefinition(
      className: 'ConfirmDialog',
      routeType: RouteType.flutterDialog,
      routeName: '/confirm/:action',
      path: '/confirm/:action',
      resultType: _bool,
      fields: [FieldInfo(name: 'action', type: _string, isRequired: true)],
    ),
  ],
  nativeRoutes: [
    RouteDefinition(
      className: 'NativeSettingsPage',
      routeType: RouteType.native,
      routeName: 'nativeSettings',
      fields: [],
    ),
    RouteDefinition(
      className: 'NativeAboutPage',
      routeType: RouteType.native,
      routeName: 'nativeAbout',
      resultType: _string,
      fields: [FieldInfo(name: 'appVersion', type: _string, isRequired: true)],
    ),
  ],
);

void main() {
  group('Java type mapping', () {
    test('uses boxed types so nullable fields can hold null', () {
      expect(dartTypeToJava(_int), 'Long');
      expect(dartTypeToJava(_bool), 'Boolean');
      expect(
        dartTypeToJava(const TypeInfo(name: 'double', isNullable: true)),
        'Double',
      );
      expect(
        dartTypeToJava(const TypeInfo(name: 'Uint8List', isNullable: false)),
        'byte[]',
      );
      expect(dartTypeToJava(_nullableBadges), 'List<Badge>');
    });
  });

  group('Java decode', () {
    test('int decodes through Number (wire delivers Integer or Long)', () {
      // Regression: a plain `(Long)` cast throws for values that fit in
      // 32 bits, which StandardMessageCodec delivers as Integer.
      expect(
        generateJavaDecode('list.get(0)', _int, _typeGraph),
        '((Number) list.get(0)).longValue()',
      );
      expect(
        generateJavaDecode(
          'list.get(0)',
          const TypeInfo(name: 'int', isNullable: true),
          _typeGraph,
        ),
        'list.get(0) == null ? null : ((Number) list.get(0)).longValue()',
      );
    });

    test('enums decode from ordinals delivered as numbers', () {
      expect(
        generateJavaDecode('list.get(1)', _nullableStyle, _typeGraph),
        'list.get(1) == null ? null : '
        'GreetingStyle.values()[((Number) list.get(1)).intValue()]',
      );
    });

    test('lists of custom classes are decoded element by element', () {
      final decode = generateJavaDecode(
        'list.get(2)',
        _nullableBadges,
        _typeGraph,
      );

      expect(decode, startsWith('list.get(2) == null ? null : '));
      expect(
        decode,
        contains('.stream().map(it -> Badge.fromList((List<Object>) it))'),
      );
      expect(decode, endsWith('.collect(Collectors.toList())'));
    });

    test('lists of strings are cast as a whole', () {
      expect(
        generateJavaDecode(
          'list.get(0)',
          const TypeInfo(
            name: 'List',
            isNullable: false,
            typeArguments: [_string],
          ),
          _typeGraph,
        ),
        '(List<String>) list.get(0)',
      );
    });

    test('maps with complex values are rebuilt into a HashMap', () {
      final decode = generateJavaDecode(
        'raw',
        const TypeInfo(
          name: 'Map',
          isNullable: false,
          typeArguments: [
            _string,
            TypeInfo(name: 'Badge', isNullable: false),
          ],
        ),
        _typeGraph,
      );

      // Collectors.toMap would throw on null values.
      expect(decode, contains('collect(HashMap::new'));
      expect(decode, contains('Badge.fromList((List<Object>) e.getValue())'));
    });
  });

  group('Java encode', () {
    test('primitives pass through, enums and classes are converted', () {
      expect(generateJavaEncode('name', _string, _typeGraph), 'name');
      expect(
        generateJavaEncode('style', _nullableStyle, _typeGraph),
        'style == null ? null : style.ordinal()',
      );
      expect(
        generateJavaEncode('badges', _nullableBadges, _typeGraph),
        'badges == null ? null : '
        'badges.stream().map(it -> it.toList()).collect(Collectors.toList())',
      );
    });
  });

  group('generateJavaRoutes', () {
    final files = generateJavaRoutes(
      schema: _schema,
      typeGraph: _typeGraph,
      packageName: 'com.example.generated',
      schemaFingerprint: 'testfp',
    );

    test('emits one file per public class plus the helpers', () {
      expect(
        files.keys,
        unorderedEquals([
          javaSchemaFileName,
          'GreetingStyle.java',
          'Badge.java',
          'GreetingPage.java',
          'CounterPage.java',
          'SettingsPage.java',
          'ConfirmDialog.java',
          'NativeSettingsPage.java',
          'NativeAboutPage.java',
          'NativeRouteHandler.java',
        ]),
      );
      for (final content in files.values) {
        expect(
          content,
          startsWith('// GENERATED CODE — DO NOT MODIFY BY HAND'),
        );
        expect(content, contains('package com.example.generated;'));
      }
    });

    test('embeds the schema fingerprint and sends it with every page', () {
      expect(
        files[javaSchemaFileName],
        contains('public static final String FINGERPRINT = "testfp";'),
      );
      expect(
        files['GreetingPage.java'],
        contains(
          'return new PageSettings(ROUTE_NAME, toList(), toPath(), InlaySchema.FINGERPRINT);',
        ),
      );
    });

    test('routes with a result implement the typed WithResult interfaces', () {
      final counter = files['CounterPage.java']!;
      expect(
        counter,
        contains(
          'public final class CounterPage implements FlutterRouteWithResult<Long> {',
        ),
      );
      expect(
        counter,
        contains('public static Object encodeResult(Long result) {'),
      );
      expect(counter, contains('public Long decodeResult(Object raw) {'));
      expect(
        counter,
        contains('return raw == null ? null : ((Number) raw).longValue();'),
      );
      expect(
        counter,
        contains('import co.leancode.inlay.FlutterRouteWithResult;'),
      );
      expect(
        counter,
        isNot(contains('import co.leancode.inlay.FlutterRoute;')),
      );

      expect(
        files['ConfirmDialog.java'],
        contains('implements FlutterDialogRouteWithResult<Boolean> {'),
      );
    });

    test('native routes expose both result codecs statically', () {
      final about = files['NativeAboutPage.java']!;
      expect(about, contains('public final class NativeAboutPage {'));
      expect(
        about,
        contains('public static Object encodeResult(String result) {'),
      );
      expect(
        about,
        contains('public static String decodeResult(Object raw) {'),
      );
      expect(about, isNot(contains('toPageSettings')));
    });

    test('the handler overrides the Kotlin fun interface and dispatches by route', () {
      final handler = files['NativeRouteHandler.java']!;
      expect(
        handler,
        contains(
          'public abstract class NativeRouteHandler implements co.leancode.inlay.NativeRouteHandler {',
        ),
      );
      expect(
        handler,
        contains(
          'public void handle(Context context, PageSettings route, Function1<Object, Unit> completion) {',
        ),
      );
      expect(
        handler,
        contains(
          'if (remote != null && !remote.equals(InlaySchema.FINGERPRINT)) {',
        ),
      );
      expect(handler, contains('case NativeSettingsPage.ROUTE_NAME:'));
      expect(
        handler,
        contains(
          'onNativeAbout(NativeAboutPage.fromList((List<Object>) route.getParams()), context, '
          'result -> completion.invoke(NativeAboutPage.encodeResult(result)));',
        ),
      );
      expect(
        handler,
        contains(
          'public abstract void onNativeAbout(NativeAboutPage page, Context context, Consumer<String> completion);',
        ),
      );
      expect(
        handler,
        contains(
          'public abstract void onNativeSettings(NativeSettingsPage page, Context context);',
        ),
      );
      expect(handler, contains('import kotlin.jvm.functions.Function1;'));
      expect(handler, contains('import java.util.function.Consumer;'));
    });

    test('toPath URL-encodes path and query parameters', () {
      final greeting = files['GreetingPage.java']!;
      expect(
        greeting,
        contains(
          'final String basePath = "/greeting/" + encodeRouteParam(String.valueOf(name));',
        ),
      );
      expect(greeting, contains('if (style != null) {'));
      expect(
        greeting,
        contains(
          'query.add("style=" + encodeRouteParam(String.valueOf(style)));',
        ),
      );
      // Complex fields never travel in the URL.
      expect(greeting, isNot(contains('"badges="')));
      // The (String, String) overload is the one available below API 33.
      expect(
        greeting,
        contains('return java.net.URLEncoder.encode(value, "UTF-8");'),
      );
      // Routes without URL parameters don't carry the helper.
      expect(files['SettingsPage.java'], isNot(contains('encodeRouteParam')));
    });

    test('imports are derived from what the class actually uses', () {
      final greeting = files['GreetingPage.java']!;
      expect(greeting, contains('import java.util.stream.Collectors;'));
      expect(greeting, contains('import java.util.ArrayList;'));
      expect(greeting, contains('import java.util.Arrays;'));
      expect(greeting, contains('import java.util.List;'));
      expect(greeting, isNot(contains('import java.util.Collections;')));
      expect(greeting, isNot(contains('import java.util.HashMap;')));

      final settings = files['SettingsPage.java']!;
      expect(settings, contains('import java.util.Collections;'));
      expect(settings, isNot(contains('import java.util.Arrays;')));
    });

    test('parameterless routes get a no-arg constructor and empty list', () {
      final settings = files['SettingsPage.java']!;
      expect(settings, contains('public SettingsPage() {}'));
      expect(settings, contains('return new SettingsPage();'));
      expect(settings, contains('return Collections.emptyList();'));
      expect(settings, contains('return "/settings";'));
      expect(settings, contains('return SettingsPage.class.hashCode();'));
    });

    test('fields get getters, deep equality and a fromList factory', () {
      final badge = files['Badge.java']!;
      expect(badge, contains('public final class Badge {'));
      expect(badge, contains('public String getLabel() {'));
      expect(badge, contains('public GreetingStyle getLevel() {'));
      expect(badge, contains('@SuppressWarnings("unchecked")'));
      expect(
        badge,
        contains('GreetingStyle.values()[((Number) list.get(1)).intValue()]'),
      );
      expect(badge, contains('return Objects.deepEquals(label, that.label)'));
      expect(
        badge,
        contains('return Arrays.deepHashCode(new Object[] {label, level});'),
      );
    });
  });
}
