import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:leancode_add2app/leancode_add2app.dart';
import 'package:signal_module/src/generated/routes.g.dart';
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

RootStackRouter createSignalAutoRouter({FlutterRouteBase? routeData}) {
  return RootStackRouter.build(
    routes: [
      NamedRouteDef(
        name: 'SoundsNotificationsRoute',
        path: SoundsNotificationsPage.pathTemplate,
        builder: (_, data) {
          final page =
              routeData is SoundsNotificationsPage ? routeData : null;
          return SoundsNotificationsScreen(
            contactId:
                page?.contactId ?? data.params.getString('contactId'),
            preferences: page?.preferences,
            presets: page?.presets,
            fallbackChannel: page?.fallbackChannel,
          );
        },
      ),
      NamedRouteDef(
        name: 'SetWallpaperRoute',
        path: SetWallpaperPage.pathTemplate,
        builder: (_, data) => SetWallpaperScreen(
          recipientId: data.params.optString('recipientId'),
        ),
      ),
      NamedRouteDef(
        name: 'SetWallpaperGlobalRoute',
        path: '/set-wallpaper',
        builder: (_, _) => const SetWallpaperScreen(),
      ),
      NamedRouteDef(
        name: 'ContactDetailsRoute',
        path: ContactDetailsPage.pathTemplate,
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
