import 'dart:async';

import 'package:flutter/material.dart';

import 'add2app_navigator.dart';

/// Runs a transparent [MaterialApp] and calls [onReady] after the first frame.
///
/// When [onReady] completes (i.e. the dialog/sheet is dismissed),
/// the native transparent container is automatically popped via
/// `Add2AppNavigator.instance.pop()`.
///
/// Developers call standard Flutter APIs inside [onReady]:
/// ```dart
/// runAdd2AppDialog(
///   onReady: (context) => showDialog(
///     context: context,
///     builder: (_) => AlertDialog(title: Text('Hello')),
///   ),
/// );
/// ```
void runAdd2AppDialog({
  required Future<void> Function(BuildContext context) onReady,
  ThemeData? theme,
  ThemeData? darkTheme,
  ThemeMode? themeMode,
}) {
  runApp(
    MaterialApp(
      theme: (theme ?? ThemeData.light()).copyWith(
        scaffoldBackgroundColor: Colors.transparent,
      ),
      darkTheme: darkTheme?.copyWith(
        scaffoldBackgroundColor: Colors.transparent,
      ),
      themeMode: themeMode,
      home: _DialogLauncher(onReady: onReady),
    ),
  );
}

class _DialogLauncher extends StatefulWidget {
  const _DialogLauncher({required this.onReady});

  final Future<void> Function(BuildContext context) onReady;

  @override
  State<_DialogLauncher> createState() => _DialogLauncherState();
}

class _DialogLauncherState extends State<_DialogLauncher> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await widget.onReady(context);
      await Add2AppNavigator.instance.pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(color: Colors.transparent);
  }
}

/// A [Page] that shows a dialog overlay via [DialogRoute].
///
/// Use in go_router's `pageBuilder`:
/// ```dart
/// GoRoute(
///   path: '/confirm-action/:action',
///   pageBuilder: (_, state) => Add2AppDialogPage(
///     builder: (_) => AlertDialog(title: Text('Confirm')),
///   ),
/// )
/// ```
class Add2AppDialogPage<T> extends Page<T> {
  const Add2AppDialogPage({
    required this.builder,
    this.barrierDismissible = true,
    this.barrierColor,
    this.barrierLabel,
    super.key,
    super.name,
  });

  final WidgetBuilder builder;
  final bool barrierDismissible;
  final Color? barrierColor;
  final String? barrierLabel;

  @override
  Route<T> createRoute(BuildContext context) {
    return _NativePopDialogRoute<T>(
      context: context,
      builder: builder,
      barrierDismissible: barrierDismissible,
      barrierColor: barrierColor ?? Colors.black54,
      barrierLabel: barrierLabel,
      settings: this,
    );
  }
}

/// A [Page] that shows a modal bottom sheet via [ModalBottomSheetRoute].
class Add2AppBottomSheetPage<T> extends Page<T> {
  const Add2AppBottomSheetPage({
    required this.builder,
    this.isScrollControlled = false,
    this.showDragHandle,
    this.backgroundColor,
    this.modalBarrierColor,
    super.key,
    super.name,
  });

  final WidgetBuilder builder;
  final bool isScrollControlled;
  final bool? showDragHandle;
  final Color? backgroundColor;
  final Color? modalBarrierColor;

  @override
  Route<T> createRoute(BuildContext context) {
    return _NativePopBottomSheetRoute<T>(
      builder: builder,
      isScrollControlled: isScrollControlled,
      showDragHandle: showDragHandle,
      backgroundColor: backgroundColor,
      modalBarrierColor: modalBarrierColor,
      settings: this,
    );
  }
}

/// [DialogRoute] that dismisses the native transparent container when popped.
class _NativePopDialogRoute<T> extends DialogRoute<T> {
  _NativePopDialogRoute({
    required super.context,
    required super.builder,
    super.barrierDismissible,
    super.barrierColor,
    super.barrierLabel,
    super.settings,
  });

  @override
  bool didPop(T? result) {
    final popped = super.didPop(result);
    if (popped) {
      unawaited(Add2AppNavigator.instance.pop().catchError((_) {}));
    }
    return popped;
  }
}

/// [ModalBottomSheetRoute] that dismisses the native transparent container
/// when popped.
class _NativePopBottomSheetRoute<T> extends ModalBottomSheetRoute<T> {
  _NativePopBottomSheetRoute({
    required super.builder,
    super.isScrollControlled = false,
    super.showDragHandle,
    super.backgroundColor,
    super.modalBarrierColor,
    super.settings,
  });

  @override
  bool didPop(T? result) {
    final popped = super.didPop(result);
    if (popped) {
      unawaited(Add2AppNavigator.instance.pop().catchError((_) {}));
    }
    return popped;
  }
}
