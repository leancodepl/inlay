import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:leancode_add2app/leancode_add2app.dart';

import 'src/generated/routes.g.dart';
import 'src/router_auto.dart';
import 'src/router_go.dart';
import 'src/screens/confirm_action_content.dart';
import 'src/screens/counter_screen.dart';
import 'src/screens/greeting_screen.dart';
import 'src/screens/home_screen.dart';
import 'src/screens/profile_screen.dart';
import 'src/screens/theme_picker_content.dart';

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
    decodeAdd2AppRouteData,
  );
  final router = createExampleGoRouter(
    initialLocation: path,
    initialExtra: route,
  );

  final isDialog = route is FlutterDialogRoute;

  runApp(
    MaterialApp.router(
      theme: isDialog
          ? ThemeData.light().copyWith(
              scaffoldBackgroundColor: Colors.transparent,
            )
          : ThemeData.light(),
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
    decodeAdd2AppRouteData,
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
    decodeAdd2AppRouteData,
  );

  switch (route) {
    case GreetingPage(:final name, :final style):
      runApp(
        MaterialApp(
          home: GreetingScreen(name: name, style: style),
        ),
      );
    case CounterPage():
      runApp(const MaterialApp(home: CounterScreen()));
    case ProfilePage(:final userId, :final badges):
      runApp(
        MaterialApp(
          home: ProfileScreen(userId: userId, badges: badges ?? const []),
        ),
      );
    case ConfirmActionDialog(:final action, :final message):
      runAdd2AppDialog(
        onReady: (context) => showDialog(
          context: context,
          builder: (_) =>
              ConfirmActionContent(action: action, message: message),
        ),
      );
    case ThemePickerDialog(:final userId):
      runAdd2AppDialog(
        onReady: (context) => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (_) => ThemePickerContent(userId: userId),
        ),
      );
    case null:
      runApp(const MaterialApp(home: ExampleHomeScreen()));
  }
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
