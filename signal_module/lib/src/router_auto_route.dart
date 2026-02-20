import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:signal_module/src/screens/contact_details_screen.dart';
import 'package:signal_module/src/screens/set_wallpaper_screen.dart';
import 'package:signal_module/src/screens/sounds_notifications_screen.dart';

/// Normalizes route passed from the host platform before deep-link parsing.
String normalizeSignalAutoRouteLocation(String platformLocation) {
  final location = platformLocation.trim();

  if (location.isEmpty) {
    return '/';
  }

  return location.startsWith('/') ? location : '/$location';
}

RootStackRouter createSignalAutoRouter() {
  return RootStackRouter.build(
    routes: [
      NamedRouteDef(
        name: 'SoundsNotificationsRoute',
        path: '/sounds-notifications/:contactId',
        builder: (_, data) => SoundsNotificationsScreen(
          contactId: data.params.getString('contactId'),
        ),
      ),
      NamedRouteDef(
        name: 'SetWallpaperRoute',
        path: '/set-wallpaper/:recipientId',
        builder: (_, data) => SetWallpaperScreen(
          recipientId: data.params.optString('recipientId'),
        ),
      ),
      // Keep support for opening wallpaper screen without a recipient id.
      NamedRouteDef(
        name: 'SetWallpaperGlobalRoute',
        path: '/set-wallpaper',
        builder: (_, _) => const SetWallpaperScreen(),
      ),
      NamedRouteDef(
        name: 'ContactDetailsRoute',
        path: '/contact-details/:contactId',
        builder: (_, data) => ContactDetailsScreen(
          contactId: data.params.getString('contactId'),
        ),
      ),
      NamedRouteDef(
        name: 'SignalHomeRoute',
        path: '/',
        builder: (_, _) => const Scaffold(
          body: Center(child: Text('Signal Module (auto_route)')),
        ),
      ),
      NamedRouteDef(
        name: 'UnknownRoute',
        path: '*',
        builder: (_, data) => Scaffold(
          body: Center(child: Text('Unknown route: ${data.path}')),
        ),
      ),
    ],
  );
}
