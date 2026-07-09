package co.leancode.inlay.compose

import android.content.Context
import android.content.ContextWrapper
import android.view.View
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.viewinterop.AndroidView
import androidx.fragment.app.FragmentActivity
import androidx.fragment.app.FragmentContainerView
import co.leancode.inlay.FlutterRoute
import co.leancode.inlay.InlayFlutterFragment
import co.leancode.inlay.InlayNavigator
import co.leancode.inlay.navigator.PageSettings

/**
 * Compose-ready wrapper that renders a Flutter page described by [route]
 * as a regular Compose destination.
 *
 * Drop it into a `NavHost` alongside native Compose screens:
 *
 * ```kotlin
 * NavHost(navController, startDestination = "home") {
 *     composable("home") { HomeScreen(...) }
 *
 *     composable("wallpaper/{recipientId}") { entry ->
 *         InlayFlutterScreen(
 *             route = PageSettings(
 *                 "setWallpaper",
 *                 mapOf("recipientId" to entry.arguments!!.getString("recipientId")!!)
 *             ),
 *             modifier = Modifier.fillMaxSize(),
 *         )
 *     }
 *
 *     composable("contact/{contactId}") { entry ->
 *         InlayFlutterScreen(
 *             route = PageSettings(
 *                 "contactDetails",
 *                 mapOf("contactId" to entry.arguments!!.getString("contactId")!!)
 *             ),
 *             modifier = Modifier.fillMaxSize(),
 *         )
 *     }
 *
 *     composable("settings") { NativeSettingsScreen() }
 * }
 * ```
 *
 * ### How it works
 *
 * Under the hood the composable creates an [InlayFlutterFragment] via
 * [InlayNavigator.createFragment] and embeds it with a
 * [FragmentContainerView]. The fragment is automatically added when the
 * composable enters the composition and removed when it leaves
 * (e.g. navigating away).
 *
 * ### Pop integration
 *
 * When Flutter code calls `pop()`, the composable uses
 * `onBackPressedDispatcher.onBackPressed()` (via the back-dispatcher mode
 * on [InlayFlutterFragment]), which integrates naturally with Compose
 * Navigation's back-stack management.
 *
 * @param route    a [PageSettings] describing the Flutter page to display.
 * @param modifier layout modifier applied to the Flutter surface.
 */
/**
 * Overload that accepts a type-safe [FlutterRoute] object.
 */
@Composable
fun InlayFlutterScreen(
    route: FlutterRoute,
    modifier: Modifier = Modifier,
    onResult: ((Any?) -> Unit)? = null,
) {
    InlayFlutterScreen(route = route.toPageSettings(), modifier = modifier, onResult = onResult)
}

/**
 * [onResult] is invoked exactly once — with the result the Flutter page
 * pops with, or `null` when the composable leaves the composition without
 * one. Decode raw values with the generated `decodeResult`.
 */
@Composable
fun InlayFlutterScreen(
    route: PageSettings,
    modifier: Modifier = Modifier,
    onResult: ((Any?) -> Unit)? = null,
) {
    val context = LocalContext.current
    // Inside dialog windows (e.g. a Compose Navigation dialog() destination)
    // LocalContext is a ContextThemeWrapper, not the Activity - unwrap it.
    val activity = context.findFragmentActivity()
        ?: error("InlayFlutterScreen must be hosted in a FragmentActivity")
    val fragmentManager = activity.supportFragmentManager

    val containerId = remember { View.generateViewId() }
    val fragmentTag = remember { "inlay_flutter_$containerId" }
    // The callback is registered once when the fragment is created; route
    // pop(result) to whatever onResult the caller passed most recently.
    val currentOnResult by rememberUpdatedState(onResult)

    // 1. Create the container view for the fragment.
    AndroidView(
        factory = { ctx ->
            FragmentContainerView(ctx).apply { id = containerId }
        },
        modifier = modifier,
    )

    // 2. Add the fragment when entering composition; remove on dispose.
    //    Both sides live in a single DisposableEffect so they are always
    //    paired correctly.
    DisposableEffect(containerId, fragmentTag) {
        val fragment = InlayNavigator.createFragment(
            context = activity,
            page = route,
            useBackDispatcher = true,
            onResult = { result -> currentOnResult?.invoke(result) },
        )

        fragmentManager.beginTransaction()
            .replace(containerId, fragment, fragmentTag)
            .commitNowAllowingStateLoss()

        onDispose {
            // Use async commit — the container view may already be detached
            // from the hierarchy by the time this runs, so a synchronous
            // commitNow can leave the FragmentManager in a broken state.
            try {
                if (!activity.isFinishing && !activity.isDestroyed) {
                    val existing = fragmentManager.findFragmentByTag(fragmentTag)
                    if (existing != null) {
                        fragmentManager.beginTransaction()
                            .remove(existing)
                            .commitAllowingStateLoss()
                    }
                }
            } catch (_: Exception) {
                // If cleanup fails the fragment will be destroyed together
                // with the hosting Activity — safe to swallow.
            }
        }
    }
}

internal tailrec fun Context.findFragmentActivity(): FragmentActivity? = when (this) {
    is FragmentActivity -> this
    is ContextWrapper -> baseContext.findFragmentActivity()
    else -> null
}
