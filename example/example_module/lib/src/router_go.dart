import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:inlay/inlay.dart';

import 'generated/routes.g.dart';
import 'screens/confirm_action_content.dart';
import 'screens/counter_screen.dart';
import 'screens/greeting_screen.dart';
import 'screens/home_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/theme_picker_content.dart';

GoRouter createExampleGoRouter({
  String initialLocation = '/',
  InlayRoute? initialExtra,
}) {
  return GoRouter(
    initialLocation: initialLocation,
    initialExtra: initialExtra,
    routes: [
      GoRoute(
        path: GreetingPage.pathTemplate,
        builder: (_, state) {
          final page = state.extra is GreetingPage
              ? state.extra! as GreetingPage
              : null;
          return GreetingScreen(
            name: page?.name ?? state.pathParameters['name'] ?? 'Guest',
            style: page?.style,
          );
        },
      ),
      GoRoute(
        path: CounterPage.pathTemplate,
        builder: (_, _) => const CounterScreen(),
      ),
      GoRoute(
        path: ProfilePage.pathTemplate,
        builder: (_, state) {
          final page = state.extra is ProfilePage
              ? state.extra! as ProfilePage
              : null;
          return ProfileScreen(
            userId: page?.userId ?? state.pathParameters['userId'] ?? 'guest',
            badges: page?.badges ?? const [],
          );
        },
      ),
      GoRoute(
        path: ConfirmActionDialog.pathTemplate,
        pageBuilder: (_, state) {
          final dialog = state.extra is ConfirmActionDialog
              ? state.extra! as ConfirmActionDialog
              : null;
          final action = dialog?.action ?? state.pathParameters['action'] ?? '';
          return InlayDialogPage(
            builder: (_) =>
                ConfirmActionContent(action: action, message: dialog?.message),
          );
        },
      ),
      GoRoute(
        path: ThemePickerDialog.pathTemplate,
        pageBuilder: (_, state) {
          final dialog = state.extra is ThemePickerDialog
              ? state.extra! as ThemePickerDialog
              : null;
          final userId = dialog?.userId ?? state.pathParameters['userId'] ?? '';
          return InlayBottomSheetPage(
            isScrollControlled: true,
            showDragHandle: true,
            builder: (_) => ThemePickerContent(userId: userId),
          );
        },
      ),
      GoRoute(path: '/', builder: (_, _) => const ExampleHomeScreen()),
      GoRoute(
        path: '/404',
        builder: (_, state) =>
            Scaffold(body: Center(child: Text('Unknown route: ${state.uri}'))),
      ),
    ],
    errorBuilder: (_, state) =>
        Scaffold(body: Center(child: Text(state.error.toString()))),
  );
}
