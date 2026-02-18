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
import co.leancode.add2app.Add2AppNavigator
import co.leancode.add2app.KeyValueStorageImpl
import co.leancode.add2app.NativeStorageScope
import co.leancode.add2app.navigator.PageSettings
import co.leancode.add2app.storage.StorageEntry
import co.leancode.signal_module.generated.NotificationBehavior
import co.leancode.signal_module.generated.SoundsNotificationsStore
import co.leancode.signal_module.generated.VibrationLevel

/**
 * ADD2APP: Native Android duplicate of the Sounds & Notifications screen.
 *
 * Reads/writes the same [KeyValueStorageImpl] that the Flutter screen uses
 * via Pigeon.  Uses [NativeStorageScope] which handles:
 * - **Self-notification suppression**: writes through the scope do not trigger
 *   the scope's own observer callback, so there is no need for `updatingUi`
 *   guard flags or manual `observerId` tracking.
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
    private lateinit var behaviorValue: TextView

    /** Scoped storage handle — read, write, and observe with auto-suppression. */
    private lateinit var storage: NativeStorageScope
    private lateinit var store: SoundsNotificationsStore

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        recipientId = intent.getStringExtra(EXTRA_RECIPIENT_ID) ?: "1"

        buildUi()

        storage = KeyValueStorageImpl.createScope()
        store = SoundsNotificationsStore(storage, contactId = recipientId)
        loadState()

        storage.startObserving { entries ->
            onStorageChanged(entries)
        }
    }

    override fun onResume() {
        super.onResume()
        loadState()
    }

    override fun onDestroy() {
        super.onDestroy()
        storage.dispose()
    }

    // ── Load from storage ────────────────────────────────────────────────

    private fun loadState() {
        muteSwitch.isChecked = store.mute
        previewsSwitch.isChecked = store.showPreviews
        soundValue.text = store.sound
        vibrationValue.text = store.vibration.label
        behaviorValue.text = store.behavior.label
    }

    // ── Observer callback (only fires for changes from OTHER sources) ───

    private fun onStorageChanged(entries: List<StorageEntry>) {
        val prefix = "sounds_notifications/$recipientId/"
        if (entries.any { it.key.startsWith(prefix) }) {
            loadState()
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
                store.mute = isChecked
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

        // ── Behavior ──
        content.addView(TextView(this).apply {
            text = "Notification behavior"
            textSize = 16f
            setPadding(0, dp(12), 0, dp(4))
        })
        behaviorValue = TextView(this).apply {
            text = NotificationBehavior.defaultBehavior.label
            textSize = 14f
            setTextColor(0xFF888888.toInt())
            setPadding(0, 0, 0, dp(12))
        }
        content.addView(behaviorValue)

        content.addView(Button(this).apply {
            text = "Change behavior"
            setOnClickListener { showBehaviorPicker() }
        })

        content.addView(divider(dp))

        // ── Show previews ──
        previewsSwitch = Switch(this).apply {
            text = "Show previews"
            textSize = 16f
            setPadding(0, dp(12), 0, dp(12))
            setOnCheckedChangeListener { _, isChecked ->
                store.showPreviews = isChecked
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
                store.sound = sounds[which]
                soundValue.text = sounds[which]
            }
            .show()
    }

    private fun showVibrationPicker() {
        val levels = VibrationLevel.entries.toTypedArray()
        val labels = levels.map { it.label }.toTypedArray()
        AlertDialog.Builder(this)
            .setTitle("Vibration Pattern")
            .setItems(labels) { _, which ->
                val level = levels[which]
                store.vibration = level
                vibrationValue.text = level.label
            }
            .show()
    }

    private fun showBehaviorPicker() {
        val behaviors = NotificationBehavior.entries.toTypedArray()
        val labels = behaviors.map { it.label }.toTypedArray()
        AlertDialog.Builder(this)
            .setTitle("Notification Behavior")
            .setItems(labels) { _, which ->
                val behavior = behaviors[which]
                store.behavior = behavior
                behaviorValue.text = behavior.label
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

private val VibrationLevel.label: String
    get() = when (this) {
        VibrationLevel.off -> "Off"
        VibrationLevel.normal -> "Normal"
        VibrationLevel.intense -> "Intense"
    }

private val NotificationBehavior.label: String
    get() = when (this) {
        NotificationBehavior.defaultBehavior -> "Default"
        NotificationBehavior.mentionsOnly -> "Mentions only"
        NotificationBehavior.muted -> "Muted"
    }
