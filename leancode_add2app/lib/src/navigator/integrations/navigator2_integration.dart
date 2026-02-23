import 'package:flutter/widgets.dart';
import 'package:leancode_add2app/src/navigator/add2app_navigator.dart';

/// A [PlatformRouteInformationProvider] seeded with the add2app initial location.
///
/// Lowest-level building block for custom [Router] implementations
/// using Navigator 2.0 directly.
///
/// ```dart
/// MaterialApp.router(
///   routeInformationProvider: Add2AppRouteInformationProvider(),
///   routerDelegate: myCustomRouterDelegate,
///   routeInformationParser: myRouteParser,
///   backButtonDispatcher: Add2AppBackButtonDispatcher(),
/// )
/// ```
class Add2AppRouteInformationProvider extends PlatformRouteInformationProvider {
  Add2AppRouteInformationProvider()
    : super(
        initialRouteInformation: RouteInformation(
          uri: Uri.parse(Add2AppNavigator.initialPath),
        ),
      );
}
