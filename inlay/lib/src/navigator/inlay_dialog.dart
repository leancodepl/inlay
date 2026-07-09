import 'dart:async';

import 'package:flutter/material.dart';

import '../appearance/inlay_appearance.dart';
import 'inlay_navigator.dart';

/// Runs a transparent [MaterialApp] and calls [onReady] after the first frame.
///
/// When [onReady] completes (i.e. the dialog/sheet is dismissed),
/// the native transparent container is automatically popped via
/// `InlayNavigator.instance.pop()`.
///
/// Use this for **imperative** (non-router) entrypoints where you call
/// `showDialog` / `showModalBottomSheet` directly. For **declarative**
/// router-based navigation, prefer [InlayDialogPage] /
/// [InlayBottomSheetPage] (go_router, or any router that accepts custom
/// [Page]s) or [InlayDialogLauncher] / [InlayBottomSheetLauncher]
/// (auto_route and other routers that manage their own page types).
///
/// ```dart
/// runInlayDialog(
///   onReady: (context) => showDialog(
///     context: context,
///     builder: (_) => AlertDialog(title: Text('Hello')),
///   ),
/// );
/// ```
void runInlayDialog({
  required Future<Object?> Function(BuildContext context) onReady,
  Object? Function(Object? result)? encodeResult,
  ThemeData? theme,
  ThemeData? darkTheme,
  ThemeMode? themeMode,
}) {
  // Dialogs render over a native screen, so they should follow the
  // app-level appearance ([InlayAppearance]) unless explicitly overridden.
  unawaited(InlayAppearance.instance.init());
  runApp(
    ListenableBuilder(
      listenable: InlayAppearance.instance,
      builder: (context, _) => MaterialApp(
        theme: (theme ?? ThemeData.light()).copyWith(
          scaffoldBackgroundColor: Colors.transparent,
        ),
        darkTheme: (darkTheme ?? ThemeData.dark()).copyWith(
          scaffoldBackgroundColor: Colors.transparent,
        ),
        themeMode: themeMode ?? InlayAppearance.instance.themeMode,
        locale: InlayAppearance.instance.locale,
        home: _DialogLauncher(onReady: onReady, encodeResult: encodeResult),
      ),
    ),
  );
}

class _DialogLauncher extends StatefulWidget {
  const _DialogLauncher({required this.onReady, this.encodeResult});

  final Future<Object?> Function(BuildContext context) onReady;
  final Object? Function(Object? result)? encodeResult;

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
      final result = await widget.onReady(context);
      if (!mounted) {
        return;
      }
      await InlayNavigator.instance.pop(widget.encodeResult?.call(result));
    });
  }

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(color: Colors.transparent);
  }
}

/// A [Page] that shows a Flutter dialog inside a transparent native container.
///
/// Use this with declarative routers that accept custom [Page]s (e.g.
/// go_router's `pageBuilder`) to show dialogs as inlay routes. For routers
/// that manage their own page types (e.g. auto_route), use
/// [InlayDialogLauncher] in a transparent route instead. The native side
/// opens a transparent Activity/ViewController, and Flutter renders the
/// dialog content (barrier, animation, positioning) over the native screen
/// underneath.
///
/// When the dialog is dismissed, the native container is automatically
/// closed via `InlayNavigator.instance.pop()`.
///
/// For imperative (non-router) entrypoints, use [runInlayDialog] instead.
///
/// ## go_router example
///
/// ```dart
/// GoRoute(
///   path: '/confirm-action/:action',
///   pageBuilder: (_, state) => InlayDialogPage(
///     builder: (_) => AlertDialog(title: Text('Confirm')),
///   ),
/// )
/// ```
///
/// ## Schema definition
///
/// ```dart
/// @InlayFlutterDialog('/confirm-action/:action')
/// class ConfirmActionDialog {
///   const ConfirmActionDialog({required this.action});
///   final String action;
/// }
/// ```
class InlayDialogPage<T> extends Page<T> {
  const InlayDialogPage({
    required this.builder,
    this.encodeResult,
    this.barrierDismissible = true,
    this.barrierColor,
    this.barrierLabel,
    super.key,
    super.name,
  });

  /// Builds the dialog content (e.g. an [AlertDialog]).
  final WidgetBuilder builder;

  /// Encodes the value the dialog pops with (`Navigator.pop(context, v)`)
  /// into the wire format delivered to the native caller's result
  /// callback. Pass the generated route's `encodeResult`. When `null`,
  /// the container closes without a result.
  // ignore: unsafe_variance
  final Object? Function(T result)? encodeResult;

  /// Whether tapping the barrier dismisses the dialog.
  final bool barrierDismissible;

  /// Color of the modal barrier. Defaults to [Colors.black54] when `null`.
  final Color? barrierColor;

  /// Semantic label for the barrier, used by accessibility tools.
  final String? barrierLabel;

  @override
  Route<T> createRoute(BuildContext context) {
    return _InlayDialogPageRoute<T>(page: this);
  }
}

/// A [Page] that shows a modal bottom sheet inside a transparent native
/// container.
///
/// Like [InlayDialogPage], this integrates with declarative routers to
/// show bottom sheets as inlay routes. The native side opens a transparent
/// Activity/ViewController, and Flutter renders the sheet with its barrier.
///
/// When the sheet is dismissed, the native container is automatically closed.
///
/// For imperative (non-router) entrypoints, use [runInlayDialog] with
/// [showModalBottomSheet] instead.
///
/// ## go_router example
///
/// ```dart
/// GoRoute(
///   path: '/theme-picker/:userId',
///   pageBuilder: (_, state) => InlayBottomSheetPage(
///     isScrollControlled: true,
///     showDragHandle: true,
///     builder: (_) => ThemePickerContent(userId: userId),
///   ),
/// )
/// ```
class InlayBottomSheetPage<T> extends Page<T> {
  const InlayBottomSheetPage({
    required this.builder,
    this.encodeResult,
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

  /// Encodes the value the sheet pops with (`Navigator.pop(context, v)`)
  /// into the wire format delivered to the native caller's result
  /// callback. Pass the generated route's `encodeResult`. When `null`,
  /// the container closes without a result.
  // ignore: unsafe_variance
  final Object? Function(T result)? encodeResult;

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
    return _InlayBottomSheetPageRoute<T>(page: this);
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

class _InlayDialogPageRoute<T> extends _TransparentPageRoute<T> {
  _InlayDialogPageRoute({required InlayDialogPage<T> page})
    : _page = page,
      super(page: page);

  final InlayDialogPage<T> _page;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return InlayDialogLauncher<T>(
      builder: _page.builder,
      encodeResult: _page.encodeResult,
      barrierDismissible: _page.barrierDismissible,
      barrierColor: _page.barrierColor,
      barrierLabel: _page.barrierLabel,
    );
  }
}

class _InlayBottomSheetPageRoute<T> extends _TransparentPageRoute<T> {
  _InlayBottomSheetPageRoute({required InlayBottomSheetPage<T> page})
    : _page = page,
      super(page: page);

  final InlayBottomSheetPage<T> _page;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return InlayBottomSheetLauncher<T>(
      builder: _page.builder,
      encodeResult: _page.encodeResult,
      isScrollControlled: _page.isScrollControlled,
      isDismissible: _page.isDismissible,
      enableDrag: _page.enableDrag,
      showDragHandle: _page.showDragHandle,
      backgroundColor: _page.backgroundColor,
      modalBarrierColor: _page.modalBarrierColor,
    );
  }
}

/// Shows a dialog after the first frame and closes the native transparent
/// container - delivering the encoded result - when it is dismissed.
///
/// This is the router-agnostic building block behind [InlayDialogPage].
/// Use it directly with routers that manage their own [Page] types and
/// can't host a foreign one (e.g. auto_route): place it as the content of
/// a transparent, zero-transition route.
///
/// ## auto_route example
///
/// ```dart
/// NamedRouteDef(
///   name: 'ConfirmActionDialogRoute',
///   path: ConfirmActionDialog.pathTemplate,
///   type: const RouteType.custom(opaque: false, duration: Duration.zero),
///   builder: (_, data) => InlayDialogLauncher<bool>(
///     encodeResult: ConfirmActionDialog.encodeResult,
///     builder: (_) => ConfirmActionContent(action: action),
///   ),
/// )
/// ```
class InlayDialogLauncher<T> extends StatefulWidget {
  const InlayDialogLauncher({
    required this.builder,
    this.encodeResult,
    this.barrierDismissible = true,
    this.barrierColor,
    this.barrierLabel,
    super.key,
  });

  /// Builds the dialog content (e.g. an [AlertDialog]).
  final WidgetBuilder builder;

  /// Encodes the value the dialog pops with into the wire format delivered
  /// to the native caller. Pass the generated route's `encodeResult`.
  // ignore: unsafe_variance
  final Object? Function(T result)? encodeResult;

  /// Whether tapping the barrier dismisses the dialog.
  final bool barrierDismissible;

  /// Color of the modal barrier. Defaults to [Colors.black54] when `null`.
  final Color? barrierColor;

  /// Semantic label for the barrier, used by accessibility tools.
  final String? barrierLabel;

  @override
  State<InlayDialogLauncher<T>> createState() => _InlayDialogLauncherState<T>();
}

class _InlayDialogLauncherState<T> extends State<InlayDialogLauncher<T>> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) {
        return;
      }
      final navigator = Navigator.of(context);
      final route = DialogRoute<Object?>(
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
      final result = await route.completed;
      if (!mounted) {
        return;
      }
      await InlayNavigator.instance.pop(
        result == null ? null : widget.encodeResult?.call(result as T),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(color: Colors.transparent);
  }
}

/// Shows a modal bottom sheet after the first frame and closes the native
/// transparent container - delivering the encoded result - when it is
/// dismissed.
///
/// The router-agnostic building block behind [InlayBottomSheetPage]; see
/// [InlayDialogLauncher] for when to use launchers directly.
class InlayBottomSheetLauncher<T> extends StatefulWidget {
  const InlayBottomSheetLauncher({
    required this.builder,
    this.encodeResult,
    this.isScrollControlled = false,
    this.isDismissible = true,
    this.enableDrag = true,
    this.showDragHandle,
    this.backgroundColor,
    this.modalBarrierColor,
    super.key,
  });

  /// Builds the bottom sheet content.
  final WidgetBuilder builder;

  /// Encodes the value the sheet pops with into the wire format delivered
  /// to the native caller. Pass the generated route's `encodeResult`.
  // ignore: unsafe_variance
  final Object? Function(T result)? encodeResult;

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
  State<InlayBottomSheetLauncher<T>> createState() =>
      _InlayBottomSheetLauncherState<T>();
}

class _InlayBottomSheetLauncherState<T>
    extends State<InlayBottomSheetLauncher<T>> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) {
        return;
      }
      final navigator = Navigator.of(context);
      final route = ModalBottomSheetRoute<Object?>(
        builder: widget.builder,
        capturedThemes: InheritedTheme.capture(
          from: context,
          to: navigator.context,
        ),
        isScrollControlled: widget.isScrollControlled,
        isDismissible: widget.isDismissible,
        enableDrag: widget.enableDrag,
        showDragHandle: widget.showDragHandle,
        backgroundColor: widget.backgroundColor,
        modalBarrierColor: widget.modalBarrierColor,
      );
      unawaited(navigator.push(route));
      final result = await route.completed;
      if (!mounted) {
        return;
      }
      await InlayNavigator.instance.pop(
        result == null ? null : widget.encodeResult?.call(result as T),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(color: Colors.transparent);
  }
}
