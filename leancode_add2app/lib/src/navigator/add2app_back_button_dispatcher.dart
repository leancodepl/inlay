import 'package:flutter/widgets.dart';
import 'package:leancode_add2app/src/navigator/add2app_navigator.dart';

/// A [RootBackButtonDispatcher] that closes the native container
/// (Activity/ViewController) when the router's navigation stack is exhausted.
///
/// When a [Router] cannot handle the back press (its stack is empty),
/// this dispatcher calls [Add2AppNavigator.instance.pop()] to close
/// the hosting native container.
///
/// Usage:
/// ```dart
/// MaterialApp.router(
///   routerConfig: router,
///   backButtonDispatcher: Add2AppBackButtonDispatcher(),
/// )
/// ```
class Add2AppBackButtonDispatcher extends RootBackButtonDispatcher {
  @override
  Future<bool> didPopRoute() async {
    final handled = await super.didPopRoute();
    if (!handled) {
      await Add2AppNavigator.instance.pop();
      return true;
    }
    return handled;
  }
}
