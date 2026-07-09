import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:inlay/inlay.dart';

import 'generated/routes.g.dart';
import 'screens/confirm_action_content.dart';
import 'screens/counter_screen.dart';
import 'screens/greeting_screen.dart';
import 'screens/home_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/theme_picker_content.dart';

/// Transparent zero-transition host for inlay dialog/sheet launchers -
/// auto_route can't host foreign [Page] types like [InlayDialogPage], so
/// the launcher widgets are used with a custom transparent route instead.
final _transparentRoute = RouteType.custom(
  opaque: false,
  duration: Duration.zero,
);

RootStackRouter createExampleAutoRouter({InlayRoute? routeData}) {
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
        name: 'ConfirmActionDialogRoute',
        path: ConfirmActionDialog.pathTemplate,
        type: _transparentRoute,
        builder: (_, data) {
          final dialog = routeData is ConfirmActionDialog ? routeData : null;
          final action = dialog?.action ?? data.params.getString('action');
          return InlayDialogLauncher<bool>(
            encodeResult: ConfirmActionDialog.encodeResult,
            builder: (_) =>
                ConfirmActionContent(action: action, message: dialog?.message),
          );
        },
      ),
      NamedRouteDef(
        name: 'ThemePickerDialogRoute',
        path: ThemePickerDialog.pathTemplate,
        type: _transparentRoute,
        builder: (_, data) {
          final dialog = routeData is ThemePickerDialog ? routeData : null;
          final userId = dialog?.userId ?? data.params.getString('userId');
          return InlayBottomSheetLauncher<void>(
            isScrollControlled: true,
            showDragHandle: true,
            builder: (_) => ThemePickerContent(userId: userId),
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
