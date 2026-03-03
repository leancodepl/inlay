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

/// A [Page] that shows a dialog overlay.
///
/// The dialog is launched via [showDialog] as a non-page route so that
/// barrier dismissal bypasses go_router's `onPopPage` (which would block
/// the pop when the dialog is the only route in the engine).
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
    return _Add2AppDialogPageRoute<T>(page: this);
  }
}

/// A [Page] that shows a modal bottom sheet.
///
/// Like [Add2AppDialogPage], the sheet is launched via
/// [showModalBottomSheet] as a non-page route.
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
    return _Add2AppBottomSheetPageRoute<T>(page: this);
  }
}

/// Transparent [PageRoute] that immediately shows a [showDialog] on first
/// frame. When the dialog is dismissed, the native container is popped.
class _Add2AppDialogPageRoute<T> extends PageRoute<T> {
  _Add2AppDialogPageRoute({required Add2AppDialogPage<T> page})
    : _page = page,
      super(settings: page);

  final Add2AppDialogPage<T> _page;

  @override
  bool get opaque => false;

  @override
  bool get barrierDismissible => false;

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  bool get maintainState => false;

  @override
  Duration get transitionDuration => Duration.zero;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return _ShowDialogOnReady(
      builder: _page.builder,
      barrierDismissible: _page.barrierDismissible,
      barrierColor: _page.barrierColor,
      barrierLabel: _page.barrierLabel,
    );
  }
}

/// Transparent [PageRoute] that immediately shows a [showModalBottomSheet] on
/// first frame. When the sheet is dismissed, the native container is popped.
class _Add2AppBottomSheetPageRoute<T> extends PageRoute<T> {
  _Add2AppBottomSheetPageRoute({required Add2AppBottomSheetPage<T> page})
    : _page = page,
      super(settings: page);

  final Add2AppBottomSheetPage<T> _page;

  @override
  bool get opaque => false;

  @override
  bool get barrierDismissible => false;

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  bool get maintainState => false;

  @override
  Duration get transitionDuration => Duration.zero;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return _ShowBottomSheetOnReady(
      builder: _page.builder,
      isScrollControlled: _page.isScrollControlled,
      showDragHandle: _page.showDragHandle,
      backgroundColor: _page.backgroundColor,
      modalBarrierColor: _page.modalBarrierColor,
    );
  }
}

class _ShowDialogOnReady extends StatefulWidget {
  const _ShowDialogOnReady({
    required this.builder,
    required this.barrierDismissible,
    this.barrierColor,
    this.barrierLabel,
  });

  final WidgetBuilder builder;
  final bool barrierDismissible;
  final Color? barrierColor;
  final String? barrierLabel;

  @override
  State<_ShowDialogOnReady> createState() => _ShowDialogOnReadyState();
}

class _ShowDialogOnReadyState extends State<_ShowDialogOnReady> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) {
        return;
      }
      final navigator = Navigator.of(context);
      final route = DialogRoute<void>(
        context: context,
        builder: widget.builder,
        themes: InheritedTheme.capture(from: context, to: navigator.context),
        barrierDismissible: widget.barrierDismissible,
        barrierColor: widget.barrierColor ?? Colors.black54,
        barrierLabel: widget.barrierLabel,
      );
      unawaited(navigator.push(route));
      // route.completed (from TransitionRoute) resolves after the reverse
      // animation ends, unlike the Future from showDialog which resolves
      // immediately on pop.
      await route.completed;
      if (!mounted) {
        return;
      }
      await Add2AppNavigator.instance.pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(color: Colors.transparent);
  }
}

class _ShowBottomSheetOnReady extends StatefulWidget {
  const _ShowBottomSheetOnReady({
    required this.builder,
    required this.isScrollControlled,
    this.showDragHandle,
    this.backgroundColor,
    this.modalBarrierColor,
  });

  final WidgetBuilder builder;
  final bool isScrollControlled;
  final bool? showDragHandle;
  final Color? backgroundColor;
  final Color? modalBarrierColor;

  @override
  State<_ShowBottomSheetOnReady> createState() =>
      _ShowBottomSheetOnReadyState();
}

class _ShowBottomSheetOnReadyState extends State<_ShowBottomSheetOnReady> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) {
        return;
      }
      final navigator = Navigator.of(context);
      final route = ModalBottomSheetRoute<void>(
        builder: widget.builder,
        capturedThemes: InheritedTheme.capture(
          from: context,
          to: navigator.context,
        ),
        isScrollControlled: widget.isScrollControlled,
        showDragHandle: widget.showDragHandle,
        backgroundColor: widget.backgroundColor,
        modalBarrierColor: widget.modalBarrierColor,
      );
      unawaited(navigator.push(route));
      await route.completed;
      if (!mounted) {
        return;
      }
      await Add2AppNavigator.instance.pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(color: Colors.transparent);
  }
}
