import 'add2app_navigator.dart';

/// Page settings for the Sounds & Notifications screen.
///
/// ```dart
/// Add2AppNavigator.instance.push(
///   SoundsNotificationsPage(contactId: '42'),
/// );
/// ```
class SoundsNotificationsPage extends Add2AppPage {
  const SoundsNotificationsPage({required this.contactId});

  final String contactId;

  @override
  String get routeId => 'soundsNotifications';

  @override
  Map<String, String> get params => {'contactId': contactId};
}

/// Page settings for the Set Wallpaper screen.
class SetWallpaperPage extends Add2AppPage {
  const SetWallpaperPage({this.recipientId});

  final String? recipientId;

  @override
  String get routeId => 'setWallpaper';

  @override
  Map<String, String> get params => {
    ...?recipientId != null ? {'recipientId': recipientId!} : null,
  };
}

/// Page settings for the Contact Details screen.
class ContactDetailsPage extends Add2AppPage {
  const ContactDetailsPage({required this.contactId});

  final String contactId;

  @override
  String get routeId => 'contactDetails';

  @override
  Map<String, String> get params => {'contactId': contactId};
}
