import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:leancode_add2app/leancode_add2app.dart';
import 'package:signal_module/src/generated/routes.g.dart';
import 'package:signal_module/src/screens/contact_details_screen.dart';
import 'package:signal_module/src/screens/set_wallpaper_screen.dart';
import 'package:signal_module/src/screens/sounds_notifications_screen.dart';

GoRouter createSignalRouter({
  String initialLocation = '/',
  FlutterRouteBase? initialExtra,
}) {
  return GoRouter(
    initialLocation: initialLocation,
    initialExtra: initialExtra,
    routes: [
      GoRoute(
        path: SoundsNotificationsPage.pathTemplate,
        builder: (_, state) {
          final page = state.extra is SoundsNotificationsPage
              ? state.extra! as SoundsNotificationsPage
              : null;
          return SoundsNotificationsScreen(
            contactId:
                page?.contactId ?? state.pathParameters['contactId'] ?? '',
            preferences: page?.preferences,
            presets: page?.presets,
            fallbackChannel: page?.fallbackChannel,
          );
        },
      ),
      GoRoute(
        path: SetWallpaperPage.pathTemplate,
        builder: (_, state) => SetWallpaperScreen(
          recipientId: state.pathParameters['recipientId'],
        ),
      ),
      GoRoute(
        path: ContactDetailsPage.pathTemplate,
        builder: (_, state) => ContactDetailsScreen(
          contactId: state.pathParameters['contactId']!,
        ),
      ),
      GoRoute(
        path: '/',
        builder: (_, _) =>
            const Scaffold(body: Center(child: Text('Signal Module'))),
      ),
    ],
  );
}
