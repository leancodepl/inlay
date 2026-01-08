import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'leancode_add2app_method_channel.dart';

abstract class LeancodeAdd2appPlatform extends PlatformInterface {
  /// Constructs a LeancodeAdd2appPlatform.
  LeancodeAdd2appPlatform() : super(token: _token);

  static final Object _token = Object();

  static LeancodeAdd2appPlatform _instance = MethodChannelLeancodeAdd2app();

  /// The default instance of [LeancodeAdd2appPlatform] to use.
  ///
  /// Defaults to [MethodChannelLeancodeAdd2app].
  static LeancodeAdd2appPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [LeancodeAdd2appPlatform] when
  /// they register themselves.
  static set instance(LeancodeAdd2appPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
