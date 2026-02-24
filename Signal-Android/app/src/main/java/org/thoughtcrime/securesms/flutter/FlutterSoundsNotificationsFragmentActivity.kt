package org.thoughtcrime.securesms.flutter

import android.content.Context
import android.content.Intent
import android.os.Bundle
import androidx.appcompat.app.AppCompatActivity
import co.leancode.add2app.Add2AppNavigator
import co.leancode.signal_module.generated.DeliveryChannel
import co.leancode.signal_module.generated.NotificationPreferences
import co.leancode.signal_module.generated.NotificationPreset
import co.leancode.signal_module.generated.NotificationSound
import co.leancode.signal_module.generated.QuietHours
import co.leancode.signal_module.generated.SoundsNotificationsPage

/**
 * ADD2APP: Activity that hosts a Flutter Fragment for the Sounds & Notifications
 * screen.
 *
 * This demonstrates the **Fragment-based** approach: instead of launching a
 * full Flutter Activity (like [Add2AppFlutterActivity]), the Flutter content is
 * embedded as a [co.leancode.add2app.Add2AppFlutterFragment] inside this
 * Activity's view hierarchy.
 *
 * Benefits of the Fragment approach:
 * - The Flutter view lives inside an existing Activity, so it can coexist with
 *   native Views, toolbars, bottom bars, etc.
 * - Fragment lifecycle is managed by the hosting Activity.
 * - Navigation is handled via FragmentManager (back stack, transitions, etc.).
 */
class FlutterSoundsNotificationsFragmentActivity : AppCompatActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Only add the fragment on first creation to avoid duplicates on
        // configuration changes (e.g. rotation).
        if (savedInstanceState == null) {
            val recipientId = intent.getStringExtra(EXTRA_RECIPIENT_ID) ?: "1"
            val fragment = Add2AppNavigator.createFragment(
                this,
                SoundsNotificationsPage(
                    contactId = recipientId,
                    preferences = NotificationPreferences(
                        sound = NotificationSound.chime,
                        channels = listOf(DeliveryChannel.push, DeliveryChannel.email),
                        quietHours = QuietHours(fromHour = 22, toHour = 7),
                    ),
                    presets = listOf(
                        NotificationPreset(
                            name = "Work",
                            preferences = NotificationPreferences(
                                sound = NotificationSound.pop,
                                channels = listOf(DeliveryChannel.push),
                                quietHours = null,
                            ),
                        ),
                        NotificationPreset(
                            name = "Silent",
                            preferences = NotificationPreferences(
                                sound = NotificationSound.defaultSound,
                                channels = listOf(DeliveryChannel.sms),
                                quietHours = QuietHours(fromHour = 0, toHour = 24),
                            ),
                        ),
                    ),
                    fallbackChannel = DeliveryChannel.sms,
                )
            )
            supportFragmentManager.beginTransaction()
                .replace(android.R.id.content, fragment, TAG_FLUTTER_FRAGMENT)
                .commit()
        }
    }

    companion object {
        private const val EXTRA_RECIPIENT_ID = "recipient_id"
        private const val TAG_FLUTTER_FRAGMENT = "flutter_fragment"

        @JvmStatic
        fun createIntent(context: Context, recipientId: String?): Intent {
            return Intent(context, FlutterSoundsNotificationsFragmentActivity::class.java).apply {
                putExtra(EXTRA_RECIPIENT_ID, recipientId ?: "1")
            }
        }
    }
}
