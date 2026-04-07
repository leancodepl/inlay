import 'package:inlay/inlay.dart';

@InlayFlutterRoute('/greeting/:name')
class GreetingPage {
  const GreetingPage({required this.name, this.style});

  final String name;
  final GreetingStyle? style;
}

@InlayFlutterRoute('/counter')
class CounterPage {
  const CounterPage({this.seed});

  final int? seed;
}

@InlayFlutterRoute('/profile/:userId')
class ProfilePage {
  const ProfilePage({required this.userId, this.badges});

  final String userId;
  final List<UserBadge>? badges;
}

@InlayFlutterDialog('/confirm-action/:action')
class ConfirmActionDialog {
  const ConfirmActionDialog({required this.action, this.message});

  final String action;
  final String? message;
}

@InlayFlutterDialog('/theme-picker/:userId')
class ThemePickerDialog {
  const ThemePickerDialog({required this.userId});

  final String userId;
}

@InlayNativeRoute()
class NativeSettingsPage {
  const NativeSettingsPage({this.source});

  final String? source;
}

@InlayNativeRoute()
class NativeAboutPage {
  const NativeAboutPage({required this.appVersion});

  final String appVersion;
}

class UserBadge {
  const UserBadge({required this.label, required this.level});

  final String label;
  final BadgeLevel level;
}

enum GreetingStyle { casual, formal }

enum BadgeLevel { bronze, silver, gold }
