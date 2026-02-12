package co.leancode.add2app

import android.os.Bundle
import android.view.View
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.viewinterop.AndroidView
import androidx.fragment.app.FragmentActivity
import androidx.fragment.app.FragmentContainerView
import co.leancode.add2app.navigator.PageSettings

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
 *         Add2AppFlutterScreen(
 *             route = PageSettings(
 *                 "setWallpaper",
 *                 mapOf("recipientId" to entry.arguments!!.getString("recipientId")!!)
 *             ),
 *             modifier = Modifier.fillMaxSize(),
 *         )
 *     }
 *
 *     composable("contact/{contactId}") { entry ->
 *         Add2AppFlutterScreen(
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
 * Under the hood the composable creates an [Add2AppFlutterFragment] via
 * [Add2AppNavigator.createFragment] and embeds it with a
 * [FragmentContainerView]. The fragment is automatically added when the
 * composable enters the composition and removed when it leaves
 * (e.g. navigating away).
 *
 * ### Pop integration
 *
 * When Flutter code calls `pop()`, the composable uses
 * `onBackPressedDispatcher.onBackPressed()` (via the back-dispatcher mode
 * on [Add2AppFlutterFragment]), which integrates naturally with Compose
 * Navigation's back-stack management.
 *
 * @param route    a [PageSettings] describing the Flutter page to display.
 * @param modifier layout modifier applied to the Flutter surface.
 */
@Composable
fun Add2AppFlutterScreen(
    route: PageSettings,
    modifier: Modifier = Modifier,
) {
    val context = LocalContext.current
    val activity = context as FragmentActivity
    val fragmentManager = activity.supportFragmentManager

    val containerId = remember { View.generateViewId() }
    val fragmentTag = remember { "add2app_flutter_$containerId" }

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
        val fragment = Add2AppNavigator.createFragment(context, route).apply {
            arguments = (arguments ?: Bundle()).apply {
                putBoolean(Add2AppFlutterFragment.ARG_USE_BACK_DISPATCHER, true)
            }
        }

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
