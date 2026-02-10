package org.thoughtcrime.securesms.flutter

import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.view.View
import android.widget.Button
import android.widget.LinearLayout
import android.widget.ScrollView
import android.widget.Switch
import android.widget.TextView
import androidx.appcompat.app.AlertDialog
import androidx.appcompat.app.AppCompatActivity
import co.leancode.signal_module.navigator.PageSettings
import co.leancode.signal_module.StorageEntry

/**
 * ADD2APP: Native Android duplicate of the Sounds & Notifications screen.
 *
 * Reads/writes the same [KeyValueStorageImpl] that the Flutter screen uses
 * via Pigeon.  The framework handles:
 * - **Self-notification suppression**: writes via [putFromAndroid] with our
 *   [observerId] do not trigger our own observer callback, so there is no
 *   need for `updatingUi` guard flags.
 * - **Main-thread delivery**: observer callbacks always arrive on the UI
 *   thread.
 *
 * Also provides a button to launch the Flutter equivalent via [Add2AppNavigator].
 */
class NativeSoundsNotificationsActivity : AppCompatActivity() {

    private lateinit var recipientId: String

    // UI references
    private lateinit var muteSwitch: Switch
    private lateinit var previewsSwitch: Switch
    private lateinit var soundValue: TextView
    private lateinit var vibrationValue: TextView

    /** Handle returned by [KeyValueStorageImpl.addAndroidObserver]. */
    private var observerId: Int = 0

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        recipientId = intent.getStringExtra(EXTRA_RECIPIENT_ID) ?: "1"

        buildUi()
        loadState()

        observerId = KeyValueStorageImpl.addAndroidObserver { entries ->
            onStorageChanged(entries)
        }
    }

    override fun onResume() {
        super.onResume()
        loadState()
    }

    override fun onDestroy() {
        super.onDestroy()
        KeyValueStorageImpl.removeAndroidObserver(observerId)
    }

    // ── Storage key helpers ──────────────────────────────────────────────

    private fun key(field: String) = "sounds_notifications/$recipientId/$field"

    // ── Load from storage ────────────────────────────────────────────────

    private fun loadState() {
        muteSwitch.isChecked = KeyValueStorageImpl.getFromAndroid(key("mute")) == "true"
        previewsSwitch.isChecked = KeyValueStorageImpl.getFromAndroid(key("previews")) != "false"
        soundValue.text = KeyValueStorageImpl.getFromAndroid(key("sound")) ?: "Default"
        vibrationValue.text = KeyValueStorageImpl.getFromAndroid(key("vibration")) ?: "Default"
    }

    // ── Observer callback (only fires for changes from OTHER sources) ───

    private fun onStorageChanged(entries: List<StorageEntry>) {
        val prefix = "sounds_notifications/$recipientId/"
        for (entry in entries) {
            if (!entry.key.startsWith(prefix)) continue
            when (entry.key.removePrefix(prefix)) {
                "mute" -> muteSwitch.isChecked = entry.value == "true"
                "previews" -> previewsSwitch.isChecked = entry.value != "false"
                "sound" -> soundValue.text = entry.value.ifEmpty { "Default" }
                "vibration" -> vibrationValue.text = entry.value.ifEmpty { "Default" }
            }
        }
    }

    // ── Build programmatic layout ────────────────────────────────────────

    @Suppress("SetTextI18n")
    private fun buildUi() {
        val dp = resources.displayMetrics.density
        fun dp(v: Int) = (v * dp).toInt()

        val root = ScrollView(this).apply {
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.MATCH_PARENT
            )
        }

        val content = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(dp(16), dp(16), dp(16), dp(32))
        }

        // ── Title ──
        content.addView(TextView(this).apply {
            text = "Sounds & Notifications (Native Android)"
            textSize = 22f
            setTypeface(typeface, android.graphics.Typeface.BOLD)
            setPadding(0, 0, 0, dp(4))
        })

        content.addView(TextView(this).apply {
            text = "Contact: $recipientId"
            textSize = 14f
            setTextColor(0xFF888888.toInt())
            setPadding(0, 0, 0, dp(16))
        })

        content.addView(divider(dp))

        // ── Mute switch ──
        muteSwitch = Switch(this).apply {
            text = "Mute notifications"
            textSize = 16f
            setPadding(0, dp(12), 0, dp(12))
            setOnCheckedChangeListener { _, isChecked ->
                KeyValueStorageImpl.putFromAndroid(key("mute"), isChecked.toString(), observerId)
            }
        }
        content.addView(muteSwitch)

        content.addView(divider(dp))

        // ── Notification sound ──
        content.addView(TextView(this).apply {
            text = "Notification sound"
            textSize = 16f
            setPadding(0, dp(12), 0, dp(4))
        })
        soundValue = TextView(this).apply {
            text = "Default"
            textSize = 14f
            setTextColor(0xFF888888.toInt())
            setPadding(0, 0, 0, dp(12))
        }
        content.addView(soundValue)

        content.addView(Button(this).apply {
            text = "Change sound"
            setOnClickListener { showSoundPicker() }
        })

        content.addView(divider(dp))

        // ── Vibration ──
        content.addView(TextView(this).apply {
            text = "Vibration pattern"
            textSize = 16f
            setPadding(0, dp(12), 0, dp(4))
        })
        vibrationValue = TextView(this).apply {
            text = "Default"
            textSize = 14f
            setTextColor(0xFF888888.toInt())
            setPadding(0, 0, 0, dp(12))
        }
        content.addView(vibrationValue)

        content.addView(Button(this).apply {
            text = "Change vibration"
            setOnClickListener { showVibrationPicker() }
        })

        content.addView(divider(dp))

        // ── Show previews ──
        previewsSwitch = Switch(this).apply {
            text = "Show previews"
            textSize = 16f
            setPadding(0, dp(12), 0, dp(12))
            setOnCheckedChangeListener { _, isChecked ->
                KeyValueStorageImpl.putFromAndroid(key("previews"), isChecked.toString(), observerId)
            }
        }
        content.addView(previewsSwitch)

        content.addView(divider(dp))

        // ── Info ──
        content.addView(TextView(this).apply {
            text = "This native screen reads/writes the same Pigeon KeyValueStorage " +
                "that the Flutter Sounds & Notifications screen uses. " +
                "Changes sync in real-time across all Flutter engine isolates and this Activity."
            textSize = 13f
            setTextColor(0xFF888888.toInt())
            setPadding(0, dp(16), 0, dp(16))
        })

        content.addView(divider(dp))

        // ── Open Flutter entrypoint button ──
        content.addView(Button(this).apply {
            text = "Open Flutter Sounds & Notifications"
            setPadding(0, dp(8), 0, dp(8))
            setOnClickListener {
                Add2AppNavigator.push(
                    this@NativeSoundsNotificationsActivity,
                    PageSettings(
                        "soundsNotifications",
                        mapOf("contactId" to recipientId)
                    )
                )
            }
        })

        root.addView(content)
        setContentView(root)
    }

    private fun divider(dp: Float): View {
        return View(this).apply {
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                (1 * dp).toInt()
            ).apply {
                topMargin = (4 * dp).toInt()
                bottomMargin = (4 * dp).toInt()
            }
            setBackgroundColor(0xFFDDDDDD.toInt())
        }
    }

    // ── Pickers ──────────────────────────────────────────────────────────

    private fun showSoundPicker() {
        val sounds = arrayOf("Default", "Signal", "Pulse", "Chime", "Bamboo", "None")
        AlertDialog.Builder(this)
            .setTitle("Notification Sound")
            .setItems(sounds) { _, which ->
                KeyValueStorageImpl.putFromAndroid(key("sound"), sounds[which], observerId)
                soundValue.text = sounds[which]
            }
            .show()
    }

    private fun showVibrationPicker() {
        val patterns = arrayOf("Default", "Short", "Long", "Double", "None")
        AlertDialog.Builder(this)
            .setTitle("Vibration Pattern")
            .setItems(patterns) { _, which ->
                KeyValueStorageImpl.putFromAndroid(key("vibration"), patterns[which], observerId)
                vibrationValue.text = patterns[which]
            }
            .show()
    }

    // ── Companion ────────────────────────────────────────────────────────

    companion object {
        private const val EXTRA_RECIPIENT_ID = "recipient_id"

        @JvmStatic
        fun createIntent(context: Context, recipientId: String?): Intent {
            return Intent(context, NativeSoundsNotificationsActivity::class.java).apply {
                putExtra(EXTRA_RECIPIENT_ID, recipientId ?: "1")
            }
        }
    }
}
