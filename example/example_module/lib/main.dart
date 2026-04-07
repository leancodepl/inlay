import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:inlay/inlay.dart';

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
void inlayMain() {
  _runInlayWithGoRouter();
}

@pragma('vm:entry-point')
void inlayGoRouterMain() {
  _runInlayWithGoRouter();
}

@pragma('vm:entry-point')
void inlayAutoRouteMain() {
  _runInlayWithAutoRoute();
}

@pragma('vm:entry-point')
void inlayImperativeMain() {
  _runInlayImperative();
}

Future<void> _runInlayWithGoRouter() async {
  WidgetsFlutterBinding.ensureInitialized();
  await KeyValueStorage.instance.init();

  final path = InlayNavigator.initialPath;
  final route = await InlayNavigator.fetchInitialRoute(
    decodeInlayRouteData,
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
      backButtonDispatcher: InlayBackButtonDispatcher(),
      builder: (_, child) => InlayNativePopGestureObserver(
        child: child ?? const SizedBox.shrink(),
      ),
    ),
  );
}

Future<void> _runInlayWithAutoRoute() async {
  WidgetsFlutterBinding.ensureInitialized();
  await KeyValueStorage.instance.init();

  final path = InlayNavigator.initialPath;
  final route = await InlayNavigator.fetchInitialRoute(
    decodeInlayRouteData,
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
      backButtonDispatcher: InlayBackButtonDispatcher(),
      builder: (_, child) => InlayNativePopGestureObserver(
        child: child ?? const SizedBox.shrink(),
      ),
    ),
  );
}

Future<void> _runInlayImperative() async {
  WidgetsFlutterBinding.ensureInitialized();
  await KeyValueStorage.instance.init();

  final route = await InlayNavigator.fetchInitialRoute(
    decodeInlayRouteData,
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
      runInlayDialog(
        onReady: (context) => showDialog(
          context: context,
          builder: (_) =>
              ConfirmActionContent(action: action, message: message),
        ),
      );
    case ThemePickerDialog(:final userId):
      runInlayDialog(
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
