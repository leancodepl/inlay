import 'package:flutter/widgets.dart';
import 'package:inlay/src/navigator/inlay_navigator.dart';

/// A [PlatformRouteInformationProvider] seeded with the inlay initial location.
///
/// Lowest-level building block for custom [Router] implementations
/// using Navigator 2.0 directly.
///
/// ```dart
/// MaterialApp.router(
///   routeInformationProvider: InlayRouteInformationProvider(),
///   routerDelegate: myCustomRouterDelegate,
///   routeInformationParser: myRouteParser,
///   backButtonDispatcher: InlayBackButtonDispatcher(),
/// )
/// ```
class InlayRouteInformationProvider extends PlatformRouteInformationProvider {
  InlayRouteInformationProvider()
    : super(
        initialRouteInformation: RouteInformation(
          uri: Uri.parse(InlayNavigator.initialPath),
        ),
      );
}
