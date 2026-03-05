import 'dart:async';

import 'package:flutter/material.dart';

import 'add2app_navigator.dart';

/// Runs a transparent [MaterialApp] and calls [onReady] after the first frame.
///
/// When [onReady] completes (i.e. the dialog/sheet is dismissed),
/// the native transparent container is automatically popped via
/// `Add2AppNavigator.instance.pop()`.
///
/// Use this for **imperative** (non-router) entrypoints where you call
/// `showDialog` / `showModalBottomSheet` directly. For **declarative**
/// router-based navigation (go_router, auto_route), prefer
/// [Add2AppDialogPage] / [Add2AppBottomSheetPage] instead.
///
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
      if (!mounted) {
        return;
      }
      await widget.onReady(context);
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

/// A [Page] that shows a Flutter dialog inside a transparent native container.
///
/// Use this with declarative routers (go_router, auto_route) to show
/// dialogs as add2app routes. The native side opens a transparent
/// Activity/ViewController, and Flutter renders the dialog content
/// (barrier, animation, positioning) over the native screen underneath.
///
/// When the dialog is dismissed, the native container is automatically
/// closed via `Add2AppNavigator.instance.pop()`.
///
/// For imperative (non-router) entrypoints, use [runAdd2AppDialog] instead.
///
/// ## go_router example
///
/// ```dart
/// GoRoute(
///   path: '/confirm-action/:action',
///   pageBuilder: (_, state) => Add2AppDialogPage(
///     builder: (_) => AlertDialog(title: Text('Confirm')),
///   ),
/// )
/// ```
///
/// ## Schema definition
///
/// ```dart
/// @Add2AppFlutterDialog('/confirm-action/:action')
/// class ConfirmActionDialog {
///   const ConfirmActionDialog({required this.action});
///   final String action;
/// }
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

  /// Builds the dialog content (e.g. an [AlertDialog]).
  final WidgetBuilder builder;

  /// Whether tapping the barrier dismisses the dialog.
  final bool barrierDismissible;

  /// Color of the modal barrier. Defaults to [Colors.black54] when `null`.
  final Color? barrierColor;

  /// Semantic label for the barrier, used by accessibility tools.
  final String? barrierLabel;

  @override
  Route<T> createRoute(BuildContext context) {
    return _Add2AppDialogPageRoute<T>(page: this);
  }
}

/// A [Page] that shows a modal bottom sheet inside a transparent native
/// container.
///
/// Like [Add2AppDialogPage], this integrates with declarative routers to
/// show bottom sheets as add2app routes. The native side opens a transparent
/// Activity/ViewController, and Flutter renders the sheet with its barrier.
///
/// When the sheet is dismissed, the native container is automatically closed.
///
/// For imperative (non-router) entrypoints, use [runAdd2AppDialog] with
/// [showModalBottomSheet] instead.
///
/// ## go_router example
///
/// ```dart
/// GoRoute(
///   path: '/theme-picker/:userId',
///   pageBuilder: (_, state) => Add2AppBottomSheetPage(
///     isScrollControlled: true,
///     showDragHandle: true,
///     builder: (_) => ThemePickerContent(userId: userId),
///   ),
/// )
/// ```
class Add2AppBottomSheetPage<T> extends Page<T> {
  const Add2AppBottomSheetPage({
    required this.builder,
    this.isScrollControlled = false,
    this.isDismissible = true,
    this.enableDrag = true,
    this.showDragHandle,
    this.backgroundColor,
    this.modalBarrierColor,
    super.key,
    super.name,
  });

  /// Builds the bottom sheet content.
  final WidgetBuilder builder;

  /// Whether the sheet takes the full height (for [DraggableScrollableSheet]
  /// or tall content). Forwarded to [ModalBottomSheetRoute.isScrollControlled].
  final bool isScrollControlled;

  /// Whether tapping the barrier or pressing back dismisses the sheet.
  final bool isDismissible;

  /// Whether the sheet can be dragged up/down. Defaults to `true`.
  final bool enableDrag;

  /// Whether to show a drag handle at the top of the sheet.
  final bool? showDragHandle;

  /// Background color of the sheet surface.
  final Color? backgroundColor;

  /// Color of the modal barrier behind the sheet.
  final Color? modalBarrierColor;

  @override
  Route<T> createRoute(BuildContext context) {
    return _Add2AppBottomSheetPageRoute<T>(page: this);
  }
}

// Invisible page route — barrier/dismiss is handled by the inner
// DialogRoute/ModalBottomSheetRoute, not by this outer page route.
abstract class _TransparentPageRoute<T> extends PageRoute<T> {
  _TransparentPageRoute({required Page<T> page}) : super(settings: page);

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
}

class _Add2AppDialogPageRoute<T> extends _TransparentPageRoute<T> {
  _Add2AppDialogPageRoute({required Add2AppDialogPage<T> page})
    : _page = page,
      super(page: page);

  final Add2AppDialogPage<T> _page;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return _ShowDialogOnReady(page: _page);
  }
}

class _Add2AppBottomSheetPageRoute<T> extends _TransparentPageRoute<T> {
  _Add2AppBottomSheetPageRoute({required Add2AppBottomSheetPage<T> page})
    : _page = page,
      super(page: page);

  final Add2AppBottomSheetPage<T> _page;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return _ShowBottomSheetOnReady(page: _page);
  }
}

class _ShowDialogOnReady extends StatefulWidget {
  const _ShowDialogOnReady({required this.page});

  final Add2AppDialogPage<dynamic> page;

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
      final page = widget.page;
      final navigator = Navigator.of(context);
      final route = DialogRoute<void>(
        context: context,
        builder: page.builder,
        themes: InheritedTheme.capture(from: context, to: navigator.context),
        barrierDismissible: page.barrierDismissible,
        barrierColor: page.barrierColor ?? Colors.black54,
        barrierLabel: page.barrierLabel,
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
  const _ShowBottomSheetOnReady({required this.page});

  final Add2AppBottomSheetPage<dynamic> page;

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
      final page = widget.page;
      final navigator = Navigator.of(context);
      final route = ModalBottomSheetRoute<void>(
        builder: page.builder,
        capturedThemes: InheritedTheme.capture(
          from: context,
          to: navigator.context,
        ),
        isScrollControlled: page.isScrollControlled,
        isDismissible: page.isDismissible,
        enableDrag: page.enableDrag,
        showDragHandle: page.showDragHandle,
        backgroundColor: page.backgroundColor,
        modalBarrierColor: page.modalBarrierColor,
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
