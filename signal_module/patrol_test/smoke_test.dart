import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:signal_module/main.dart' as app;

void main() {
  patrolTest('navigates from native Signal to a Flutter add2app screen', (
    $,
  ) async {
    Future<void> tapText(String text) {
      return $.platform.mobile.tap(
        MobileSelector(android: AndroidSelector(text: text)),
      );
    }

    await $.platform.mobile.tap(
      MobileSelector(android: AndroidSelector(contentDescription: 'New chat')),
    );
    await $.platform.mobile.tap(
      MobileSelector(android: AndroidSelector(textContains: 'Note to Self')),
    );
    await $.platform.mobile.tap(
      MobileSelector(
        android: AndroidSelector(contentDescription: 'More options'),
      ),
    );
    await tapText('Chat settings');
    await tapText('Chat color & wallpaper');

    await $.pumpWidgetAndSettle(
      await app.prepareSignalAdd2App(
        initialLocation: '/set-wallpaper/patrol',
        fetchInitialRouteData: false,
      ),
    );

    await $(const Key('set_wallpaper_screen_app_bar')).waitUntilVisible();
    await $.pumpAndSettle(duration: const Duration(seconds: 5));
  });
}
