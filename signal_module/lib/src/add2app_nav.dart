import 'package:flutter/services.dart';

/// Method channel to request opening add2app screens in a new Android Activity (new engine).
/// Used to spawn multiple Flutter engines for comparison (memory, start time).
const _channel = MethodChannel('org.thoughtcrime.securesms/add2app_nav');

/// Asks the host to start Set Wallpaper in a new Activity (new engine).
Future<void> openSetWallpaperInNewActivity([String? recipientId]) async {
  await _channel.invokeMethod<void>('open_set_wallpaper', recipientId);
}

/// Asks the host to start Sounds & Notifications in a new Activity (new engine).
Future<void> openSoundsNotificationsInNewActivity([String? recipientId]) async {
  await _channel.invokeMethod<void>('open_sounds_notifications', recipientId);
}
