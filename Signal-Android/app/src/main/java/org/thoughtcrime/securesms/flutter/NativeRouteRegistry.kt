package org.thoughtcrime.securesms.flutter

import android.content.Intent
import co.leancode.add2app.Add2AppNavigator

/**
 * Registers native Android screens that Flutter can navigate to via
 * [Add2AppNavigator.instance.pushNativeRoute(...)][co.leancode.add2app.NativeRouteHandler].
 *
 * Call [registerAll] once at app startup (e.g. `Application.onCreate`) — before
 * any Flutter engine could send a `pushNativeRoute` message.
 *
 * Each route maps a `routeId` (matching a Dart [Add2AppPage.routeId]) to a
 * lambda that launches the corresponding Android Activity.
 */
object NativeRouteRegistry {

    /**
     * Register all native route handlers.
     * Idempotent — safe to call multiple times (handlers are overwritten).
     */
    @JvmStatic
    fun registerAll() {

        // ── nativeEditProfile ────────────────────────────────────────────
        // Opens NativeSoundsNotificationsActivity — a native Android screen
        // that shares state with Flutter via Pigeon KeyValueStorage.
        //
        // Flutter side:
        //   Add2AppNavigator.instance.pushNativeRoute(
        //     NativeEditProfilePage(contactId: '42'),
        //   );
        Add2AppNavigator.registerNativeRoute("nativeEditProfile") { context, params ->
            val contactId = params?.get("contactId") ?: "1"
            context.startActivity(
                NativeSoundsNotificationsActivity.createIntent(context, contactId)
            )
        }

        // ── nativeMediaViewer ────────────────────────────────────────────
        // Opens ComposeFlutterComparisonActivity — a Jetpack Compose screen
        // that demonstrates native/Flutter side-by-side comparison.
        //
        // Flutter side:
        //   Add2AppNavigator.instance.pushNativeRoute(
        //     NativeMediaViewerPage(mediaId: '123', mediaType: 'photo'),
        //   );
        Add2AppNavigator.registerNativeRoute("nativeMediaViewer") { context, params ->
            val mediaId = params?.get("mediaId") ?: "1"
            context.startActivity(
                ComposeFlutterComparisonActivity.createIntent(context, mediaId)
            )
        }
    }
}
