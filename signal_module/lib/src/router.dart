import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:leancode_add2app/leancode_add2app.dart';
import 'package:signal_module/src/screens/contact_details_screen.dart';
import 'package:signal_module/src/screens/set_wallpaper_screen.dart';
import 'package:signal_module/src/screens/sounds_notifications_screen.dart';

GoRouter createSignalRouter() {
  return GoRouter(
    initialLocation: Add2AppNavigator.initialLocationFromPlatform(),
    initialExtra: extra,
    routes: [
      GoRoute(
        path: '/sounds-notifications/:contactId',
        builder: (_, state) => SoundsNotificationsScreen(
          contactId: state.pathParameters['contactId']!,
        ),
      ),
      GoRoute(
        path: '/set-wallpaper/:recipientId',
        builder: (_, state) => SetWallpaperScreen(
          recipientId: state.pathParameters['recipientId'],
        ),
      ),
      GoRoute(
        path: '/contact-details/:contactId',
        builder: (_, state) =>
            ContactDetailsScreen(contactId: state.pathParameters['contactId']!),
      ),
      GoRoute(
        path: '/',
        builder: (_, _) =>
            const Scaffold(body: Center(child: Text('Signal Module'))),
      ),
    ],
  );
}
