import 'package:flutter/widgets.dart';

import '../navigator/inlay_navigator.dart';

/// Recording [InlayNavigator] double for widget and unit tests.
///
/// No platform channel is involved: every navigation call is recorded so
/// tests can assert on it. Install it by overriding the singleton:
///
/// ```dart
/// final navigator = FakeInlayNavigator();
/// InlayNavigator.instance = navigator;
///
/// // ... pump a widget, tap a button ...
///
/// expect(navigator.pushedRoutes.single, isA<CounterPage>());
/// ```
class FakeInlayNavigator implements InlayNavigator {
  /// Typed routes passed to [push], in call order.
  final pushedRoutes = <InlayRoute>[];

  /// Raw [PageSettings] passed to the lower-level dispatch methods
  /// ([pushFlutterRoute], [pushNativeRoute], [presentFlutterDialog]),
  /// including those produced by [push].
  final pushedPages = <PageSettings>[];

  /// Number of container pops ([pop] calls, plus [maybePop] calls that
  /// could not pop an in-Flutter route).
  int popCount = 0;

  /// Last value passed to [setNativePopGestureEnabled], if any.
  bool? nativePopGestureEnabled;

  @override
  Future<void> push(InlayRoute route) async {
    pushedRoutes.add(route);
    pushedPages.add(route.toPageSettings());
  }

  @override
  Future<void> pop() async {
    popCount++;
  }

  @override
  Future<void> maybePop(BuildContext context) async {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
    } else {
      await pop();
    }
  }

  @override
  Future<void> setNativePopGestureEnabled(bool enabled) async {
    nativePopGestureEnabled = enabled;
  }

  @override
  Future<void> pushFlutterRoute(PageSettings page) async {
    pushedPages.add(page);
  }

  @override
  Future<void> pushNativeRoute(PageSettings page) async {
    pushedPages.add(page);
  }

  @override
  Future<void> presentFlutterDialog(PageSettings page) async {
    pushedPages.add(page);
  }
}
