import 'package:flutter/widgets.dart';
import 'package:inlay/src/navigator/inlay_navigator.dart';

/// A [RootBackButtonDispatcher] that closes the native container
/// (Activity/ViewController) when the router's navigation stack is exhausted.
///
/// When a [Router] cannot handle the back press (its stack is empty),
/// this dispatcher calls [InlayNavigator.instance.pop()] to close
/// the hosting native container.
///
/// Usage:
/// ```dart
/// MaterialApp.router(
///   routerConfig: router,
///   backButtonDispatcher: InlayBackButtonDispatcher(),
/// )
/// ```
class InlayBackButtonDispatcher extends RootBackButtonDispatcher {
  @override
  Future<bool> didPopRoute() async {
    final handled = await super.didPopRoute();
    if (!handled) {
      await InlayNavigator.instance.pop();
      return true;
    }
    return handled;
  }
}
