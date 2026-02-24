import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:leancode_add2app/leancode_add2app.dart';

import 'generated/routes.g.dart';
import 'screens/counter_screen.dart';
import 'screens/greeting_screen.dart';
import 'screens/home_screen.dart';
import 'screens/profile_screen.dart';

RootStackRouter createExampleAutoRouter({FlutterRouteBase? routeData}) {
  return RootStackRouter.build(
    routes: [
      NamedRouteDef(
        name: 'GreetingRoute',
        path: GreetingPage.pathTemplate,
        builder: (_, data) {
          final page = routeData is GreetingPage ? routeData : null;
          return GreetingScreen(
            name: page?.name ?? data.params.getString('name'),
            style: page?.style,
          );
        },
      ),
      NamedRouteDef(
        name: 'CounterRoute',
        path: CounterPage.pathTemplate,
        builder: (_, _) => const CounterScreen(),
      ),
      NamedRouteDef(
        name: 'ProfileRoute',
        path: ProfilePage.pathTemplate,
        builder: (_, data) {
          final page = routeData is ProfilePage ? routeData : null;
          return ProfileScreen(
            userId: page?.userId ?? data.params.getString('userId'),
            badges: page?.badges ?? const [],
          );
        },
      ),
      NamedRouteDef(
        name: 'HomeRoute',
        path: '/',
        builder: (_, _) => const ExampleHomeScreen(),
      ),
      NamedRouteDef(
        name: 'UnknownRoute',
        path: '*',
        builder: (_, data) =>
            Scaffold(body: Center(child: Text('Unknown route: ${data.path}'))),
      ),
    ],
  );
}
