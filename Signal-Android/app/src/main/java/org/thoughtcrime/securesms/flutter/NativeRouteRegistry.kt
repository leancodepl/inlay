package org.thoughtcrime.securesms.flutter

import android.content.Context
import co.leancode.signal_module.generated.NativeEditProfilePage
import co.leancode.signal_module.generated.NativeMediaViewerPage
import co.leancode.signal_module.generated.NativeRouteHandler

/**
 * Typed native route handler for Signal-Android.
 *
 * Extends the generated [NativeRouteHandler] from signal_module so each
 * native route is handled via a compile-time checked `on*` method with
 * the pigeon-generated page object already decoded.
 *
 * Set once at app startup:
 * ```kotlin
 * Add2AppNavigator.setNativeRouteHandler(NativeRouteRegistry)
 * ```
 */
object NativeRouteRegistry : NativeRouteHandler() {

    override fun onNativeEditProfile(page: NativeEditProfilePage, context: Context) {
        context.startActivity(
            NativeSoundsNotificationsActivity.createIntent(context, page.contactId)
        )
    }

    override fun onNativeMediaViewer(page: NativeMediaViewerPage, context: Context) {
        context.startActivity(
            ComposeFlutterComparisonActivity.createIntent(context, page.mediaId)
        )
    }
}
