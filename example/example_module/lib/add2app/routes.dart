import 'package:leancode_add2app/leancode_add2app.dart';

@Add2AppFlutterRoute('/greeting/:name')
class GreetingPage {
  const GreetingPage({required this.name, this.style});

  final String name;
  final GreetingStyle? style;
}

@Add2AppFlutterRoute('/counter')
class CounterPage {
  const CounterPage({this.seed});

  final int? seed;
}

@Add2AppFlutterRoute('/profile/:userId')
class ProfilePage {
  const ProfilePage({required this.userId, this.badges});

  final String userId;
  final List<UserBadge>? badges;
}

@Add2AppFlutterDialog('/confirm-action/:action')
class ConfirmActionDialog {
  const ConfirmActionDialog({required this.action, this.message});

  final String action;
  final String? message;
}

@Add2AppFlutterDialog('/theme-picker/:userId')
class ThemePickerDialog {
  const ThemePickerDialog({required this.userId});

  final String userId;
}

@Add2AppNativeRoute()
class NativeSettingsPage {
  const NativeSettingsPage({this.source});

  final String? source;
}

@Add2AppNativeRoute()
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
