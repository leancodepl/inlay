import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'inlay_navigator.dart';

/// Syncs native iOS back gesture availability with Flutter stack depth.
///
/// - If Flutter can handle pop (`canHandlePop == true`), native gesture is
///   disabled to avoid popping the container.
/// - If Flutter is at root (`canHandlePop == false`), native gesture is
///   enabled so swipe-back exits the container.
class InlayNativePopGestureObserver extends StatefulWidget {
  const InlayNativePopGestureObserver({super.key, required this.child});

  final Widget child;

  @override
  State<InlayNativePopGestureObserver> createState() =>
      _InlayNativePopGestureObserverState();
}

class _InlayNativePopGestureObserverState
    extends State<InlayNativePopGestureObserver> {
  bool? _lastNativeGestureEnabled;

  bool get _isIOS => defaultTargetPlatform == TargetPlatform.iOS;

  Future<void> _syncNativeGesture(bool enabled) async {
    if (!_isIOS || _lastNativeGestureEnabled == enabled) {
      return;
    }
    _lastNativeGestureEnabled = enabled;

    try {
      await InlayNavigator.instance.setNativePopGestureEnabled(enabled);
    } on PlatformException catch (error) {
      if (error.code != 'channel-error') {
        debugPrint(
          'InlayNativePopGestureObserver sync failed: '
          '${error.code} ${error.message}',
        );
      }
    } on MissingPluginException {
      // Running outside inlay host.
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
