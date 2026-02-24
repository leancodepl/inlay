import 'package:flutter/material.dart';
import 'package:leancode_add2app/leancode_add2app.dart';

import 'generated/routes.g.dart';
import 'screens/counter_screen.dart';
import 'screens/greeting_screen.dart';
import 'screens/home_screen.dart';
import 'screens/profile_screen.dart';

Add2AppPageHandler createImperativePageHandler() {
  return const ExampleImperativePageHandler();
}

class ExampleImperativePageHandler extends FlutterRouteHandler
    implements Add2AppPageHandler {
  const ExampleImperativePageHandler();

  @override
  Widget build(PageSettings page) => handle(page);

  @override
  Widget onGreeting(GreetingPage page) {
    return GreetingScreen(name: page.name, style: page.style);
  }

  @override
  Widget onCounter(CounterPage page) {
    return const CounterScreen();
  }

  @override
  Widget onProfile(ProfilePage page) {
    return ProfileScreen(userId: page.userId, badges: page.badges ?? const []);
  }

  @override
  Widget onUnknownRoute(PageSettings route) {
    if (route.routeId == '/' || route.routeId == '__add2app_prewarm__') {
      return const ExampleHomeScreen();
    }
    return Center(child: Text('Unknown route: ${route.routeId}'));
  }
}
