import 'package:flutter_test/flutter_test.dart';
import 'package:leancode_add2app/leancode_add2app.dart';
import 'package:leancode_add2app/leancode_add2app_platform_interface.dart';
import 'package:leancode_add2app/leancode_add2app_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockLeancodeAdd2appPlatform
    with MockPlatformInterfaceMixin
    implements LeancodeAdd2appPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final LeancodeAdd2appPlatform initialPlatform = LeancodeAdd2appPlatform.instance;

  test('$MethodChannelLeancodeAdd2app is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelLeancodeAdd2app>());
  });

  test('getPlatformVersion', () async {
    LeancodeAdd2app leancodeAdd2appPlugin = LeancodeAdd2app();
    MockLeancodeAdd2appPlatform fakePlatform = MockLeancodeAdd2appPlatform();
    LeancodeAdd2appPlatform.instance = fakePlatform;

    expect(await leancodeAdd2appPlugin.getPlatformVersion(), '42');
  });
}
