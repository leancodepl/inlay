import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:leancode_add2app/leancode_add2app.dart';

import 'src/generated/routes.g.dart';
import 'src/router_auto.dart';
import 'src/router_go.dart';
import 'src/screens/counter_screen.dart';
import 'src/screens/greeting_screen.dart';
import 'src/screens/home_screen.dart';
import 'src/screens/profile_screen.dart';

void main() {
  runApp(const _StandaloneApp());
}

@pragma('vm:entry-point')
void add2appMain() {
  _runAdd2AppWithGoRouter();
}

@pragma('vm:entry-point')
void add2appGoRouterMain() {
  _runAdd2AppWithGoRouter();
}

@pragma('vm:entry-point')
void add2appAutoRouteMain() {
  _runAdd2AppWithAutoRoute();
}

@pragma('vm:entry-point')
void add2appImperativeMain() {
  _runAdd2AppImperative();
}

Future<void> _runAdd2AppWithGoRouter() async {
  WidgetsFlutterBinding.ensureInitialized();
  await KeyValueStorage.instance.init();

  final path = Add2AppNavigator.initialPath;
  final route = await Add2AppNavigator.fetchInitialRoute(
    decodeFlutterRouteData,
  );
  final router = createExampleGoRouter(
    initialLocation: path,
    initialExtra: route,
  );

  runApp(
    MaterialApp.router(
      routeInformationProvider: router.routeInformationProvider,
      routeInformationParser: router.routeInformationParser,
      routerDelegate: router.routerDelegate,
      backButtonDispatcher: Add2AppBackButtonDispatcher(),
      builder: (_, child) => Add2AppNativePopGestureObserver(
        child: child ?? const SizedBox.shrink(),
      ),
    ),
  );
}

Future<void> _runAdd2AppWithAutoRoute() async {
  WidgetsFlutterBinding.ensureInitialized();
  await KeyValueStorage.instance.init();

  final path = Add2AppNavigator.initialPath;
  final route = await Add2AppNavigator.fetchInitialRoute(
    decodeFlutterRouteData,
  );
  final router = createExampleAutoRouter(routeData: route);

  runApp(
    MaterialApp.router(
      routeInformationParser: router.defaultRouteParser(
        includePrefixMatches: true,
      ),
      routerDelegate: router.delegate(
        deepLinkBuilder: (_) => DeepLink.path(path),
        rebuildStackOnDeepLink: true,
      ),
      backButtonDispatcher: Add2AppBackButtonDispatcher(),
      builder: (_, child) => Add2AppNativePopGestureObserver(
        child: child ?? const SizedBox.shrink(),
      ),
    ),
  );
}

Future<void> _runAdd2AppImperative() async {
  WidgetsFlutterBinding.ensureInitialized();
  await KeyValueStorage.instance.init();

  final route = await Add2AppNavigator.fetchInitialRoute(
    decodeFlutterRouteData,
  );

  final widget = switch (route) {
    GreetingPage(:final name, :final style) => GreetingScreen(
      name: name,
      style: style,
    ),
    CounterPage() => const CounterScreen(),
    ProfilePage(:final userId, :final badges) => ProfileScreen(
      userId: userId,
      badges: badges ?? const [],
    ),
    null => const ExampleHomeScreen(),
  };

  runApp(MaterialApp(home: widget));
}

class _StandaloneApp extends StatelessWidget {
  const _StandaloneApp();

  @override
  Widget build(BuildContext context) {
    final router = createExampleGoRouter();
    return MaterialApp.router(
      routeInformationProvider: router.routeInformationProvider,
      routeInformationParser: router.routeInformationParser,
      routerDelegate: router.routerDelegate,
    );
  }
}
