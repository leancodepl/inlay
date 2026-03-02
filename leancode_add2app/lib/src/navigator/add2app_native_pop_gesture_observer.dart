import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'add2app_navigator.dart';

/// Syncs native iOS back gesture availability with Flutter stack depth.
///
/// - If Flutter can handle pop (`canHandlePop == true`), native gesture is
///   disabled to avoid popping the container.
/// - If Flutter is at root (`canHandlePop == false`), native gesture is
///   enabled so swipe-back exits the container.
class Add2AppNativePopGestureObserver extends StatefulWidget {
  const Add2AppNativePopGestureObserver({super.key, required this.child});

  final Widget child;

  @override
  State<Add2AppNativePopGestureObserver> createState() =>
      _Add2AppNativePopGestureObserverState();
}

class _Add2AppNativePopGestureObserverState
    extends State<Add2AppNativePopGestureObserver> {
  bool? _lastNativeGestureEnabled;

  bool get _isIOS => defaultTargetPlatform == TargetPlatform.iOS;

  Future<void> _syncNativeGesture(bool enabled) async {
    if (!_isIOS || _lastNativeGestureEnabled == enabled) {
      return;
    }
    _lastNativeGestureEnabled = enabled;

    try {
      await Add2AppNavigator.instance.setNativePopGestureEnabled(enabled);
    } on PlatformException catch (error) {
      if (error.code != 'channel-error') {
        debugPrint(
          'Add2AppNativePopGestureObserver sync failed: '
          '${error.code} ${error.message}',
        );
      }
    } on MissingPluginException {
      // Running outside add2app host.
    }
  }

  @override
  void initState() {
    super.initState();
    // Root by default until Router emits first NavigationNotification.
    unawaited(_syncNativeGesture(true));
  }

  @override
  void dispose() {
    // Best effort restore to default enabled when widget is torn down.
    unawaited(_syncNativeGesture(true));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<NavigationNotification>(
      onNotification: (notification) {
        unawaited(_syncNativeGesture(!notification.canHandlePop));
        return false;
      },
      child: widget.child,
    );
  }
}
