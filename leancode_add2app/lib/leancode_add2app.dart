
import 'leancode_add2app_platform_interface.dart';

class LeancodeAdd2app {
  Future<String?> getPlatformVersion() {
    return LeancodeAdd2appPlatform.instance.getPlatformVersion();
  }
}
