import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leancode_add2app/leancode_add2app_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  MethodChannelLeancodeAdd2app platform = MethodChannelLeancodeAdd2app();
  const MethodChannel channel = MethodChannel('leancode_add2app');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (MethodCall methodCall) async {
        return '42';
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
  });

  test('getPlatformVersion', () async {
    expect(await platform.getPlatformVersion(), '42');
  });
}
