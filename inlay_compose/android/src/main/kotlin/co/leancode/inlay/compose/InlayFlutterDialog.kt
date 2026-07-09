package co.leancode.inlay.compose

import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.ui.platform.LocalContext
import androidx.lifecycle.DefaultLifecycleObserver
import androidx.lifecycle.LifecycleOwner
import co.leancode.inlay.FlutterDialogRoute
import co.leancode.inlay.InlayNavigator

/**
 * Present a Flutter dialog over the current Compose screen.
 *
 * The Compose counterpart of SwiftUI's `.inlayDialog` modifier. While
 * [isPresented] is `true`, the framework's transparent
 * `InlayFlutterDialogFragment` is shown over the Activity - the underlying
 * screen stays visible and Flutter renders the dialog content (barrier,
 * animation, positioning).
 *
 * Do **not** wrap this in a Compose `Dialog` or a Compose Navigation
 * `dialog()` destination - the fragment manages its own window.
 *
 * ```kotlin
 * var showDialog by remember { mutableStateOf(false) }
 * var lastResult by remember { mutableStateOf<String?>(null) }
 *
 * Button(onClick = { showDialog = true }) { Text("Delete") }
 * InlayFlutterDialog(
 *     isPresented = showDialog,
 *     route = ConfirmDeleteDialog(itemId = "42"),
 *     onDismissRequest = { showDialog = false },
 *     onResult = { raw -> lastResult = ConfirmDeleteDialog.decodeResult(raw)?.toString() },
 * )
 * ```
 *
 * [onDismissRequest] is called when the dialog goes away for any reason
 * (Flutter pop, barrier tap, back) - flip [isPresented] back to `false`
 * there. [onResult] is invoked exactly once - with the popped result, or
 * `null` on dismissal without one. Decode raw values with the generated
 * `decodeResult`.
 */
@Composable
fun InlayFlutterDialog(
    isPresented: Boolean,
    route: FlutterDialogRoute,
    onDismissRequest: () -> Unit,
    onResult: ((Any?) -> Unit)? = null,
) {
    val activity = LocalContext.current.findFragmentActivity()
        ?: error("InlayFlutterDialog must be hosted in a FragmentActivity")
    val currentOnResult by rememberUpdatedState(onResult)
    val currentOnDismissRequest by rememberUpdatedState(onDismissRequest)

    if (!isPresented) return

    DisposableEffect(route) {
        val fragment = InlayNavigator.createDialogFragment(activity, route) { raw ->
            currentOnResult?.invoke(raw)
        }
        fragment.lifecycle.addObserver(object : DefaultLifecycleObserver {
            override fun onDestroy(owner: LifecycleOwner) {
                currentOnDismissRequest()
            }
        })
        fragment.show(activity.supportFragmentManager, route.toPageSettings().routeId)

        onDispose {
            // isPresented flipped to false (or the host left the
            // composition) while the dialog is still up - dismiss it.
            if (fragment.isAdded) {
                fragment.dismissAllowingStateLoss()
            }
        }
    }
}
