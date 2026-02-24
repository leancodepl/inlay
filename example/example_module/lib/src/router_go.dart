import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:leancode_add2app/leancode_add2app.dart';

import 'generated/routes.g.dart';
import 'screens/counter_screen.dart';
import 'screens/greeting_screen.dart';
import 'screens/home_screen.dart';
import 'screens/profile_screen.dart';

GoRouter createExampleGoRouter({
  String initialLocation = '/',
  FlutterRouteBase? initialExtra,
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
