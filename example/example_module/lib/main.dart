import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:leancode_add2app/leancode_add2app.dart';

import 'src/generated/routes.g.dart';
import 'src/router_auto.dart';
import 'src/router_go.dart';
import 'src/router_imperative.dart';

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
    ),
  );
}

Future<void> _runAdd2AppImperative() async {
  WidgetsFlutterBinding.ensureInitialized();
  await KeyValueStorage.instance.init();

  final handler = createImperativePageHandler();
  final typedRoute = await Add2AppNavigator.fetchInitialRoute(
    decodeFlutterRouteData,
  );
  final page =
      typedRoute?.toPageSettings() ??
      Add2AppNavigator.initialPageFromPlatform();

  runApp(
    MaterialApp(home: Add2AppNavigator.instance.runPageHandler(page, handler)),
  );
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
