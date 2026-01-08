import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'leancode_add2app_platform_interface.dart';

/// An implementation of [LeancodeAdd2appPlatform] that uses method channels.
class MethodChannelLeancodeAdd2app extends LeancodeAdd2appPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('leancode_add2app');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
