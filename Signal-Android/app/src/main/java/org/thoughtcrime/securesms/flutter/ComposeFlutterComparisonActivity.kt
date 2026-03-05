package org.thoughtcrime.securesms.flutter

import android.content.Context
import android.content.Intent
import android.os.Bundle
import androidx.activity.compose.setContent
import androidx.appcompat.app.AppCompatActivity
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.ListItem
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Surface
import androidx.compose.material3.Switch
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import co.leancode.add2app.Add2AppFlutterScreen
import co.leancode.add2app.KeyValueStorageImpl
import co.leancode.signal_module.generated.DeliveryChannel
import co.leancode.signal_module.generated.NotificationBehavior
import co.leancode.signal_module.generated.NotificationPreferences
import co.leancode.signal_module.generated.NotificationPreset
import co.leancode.signal_module.generated.NotificationSound
import co.leancode.signal_module.generated.QuietHours
import co.leancode.signal_module.generated.SoundsNotificationsPage
import co.leancode.signal_module.generated.SoundsNotificationsStore
import co.leancode.signal_module.generated.VibrationLevel

/**
 * ADD2APP: Compose Activity that demonstrates [Add2AppFlutterScreen] inside a
 * Jetpack Compose [NavHost].
 *
 * The nav graph contains three destinations:
 *
 * 1. **Hub** — lets the user choose between the native Compose implementation
 *    and the Flutter implementation.
 * 2. **Native Compose** — a full Sounds & Notifications screen built purely
 *    with Jetpack Compose, reading/writing [KeyValueStorageImpl].
 * 3. **Flutter** — the same screen rendered by the Flutter engine via
 *    [Add2AppFlutterScreen], also reading/writing [KeyValueStorageImpl].
 *
 * Both implementations share state in real-time through the framework's
 * Pigeon KeyValueStorage.
 */
class ComposeFlutterComparisonActivity : AppCompatActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val recipientId = intent.getStringExtra(EXTRA_RECIPIENT_ID) ?: "1"

        setContent {
            MaterialTheme {
                ComparisonNavHost(
                    recipientId = recipientId,
                    onFinish = { finish() },
                )
            }
        }
    }

    companion object {
        private const val EXTRA_RECIPIENT_ID = "recipient_id"

        @JvmStatic
        fun createIntent(context: Context, recipientId: String?): Intent {
            return Intent(context, ComposeFlutterComparisonActivity::class.java).apply {
                putExtra(EXTRA_RECIPIENT_ID, recipientId ?: "1")
            }
        }
    }
}

// ── Navigation graph ─────────────────────────────────────────────────────

@Composable
private fun ComparisonNavHost(
    recipientId: String,
    onFinish: () -> Unit,
) {
    val navController = rememberNavController()

    NavHost(navController, startDestination = "hub") {

        composable("hub") {
            ComparisonHubScreen(
                recipientId = recipientId,
                onOpenNativeCompose = { navController.navigate("native/$recipientId") },
                onOpenFlutter = { navController.navigate("flutter/$recipientId") },
                onBack = onFinish,
            )
        }

        // ── Native Compose destination ───────────────────────────────
        composable("native/{id}") { entry ->
            NativeComposeSoundsNotifications(
                recipientId = entry.arguments!!.getString("id")!!,
                onBack = { navController.popBackStack() },
            )
        }

        // ── Flutter destination (seamless!) ──────────────────────────
        composable("flutter/{id}") { entry ->
            Add2AppFlutterScreen(
                route = SoundsNotificationsPage(
                    contactId = entry.arguments!!.getString("id")!!,
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
                    ),
                    fallbackChannel = DeliveryChannel.sms,
                ),
                modifier = Modifier.fillMaxSize(),
            )
        }
    }
}

// ── Hub screen ───────────────────────────────────────────────────────────

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun ComparisonHubScreen(
    recipientId: String,
    onOpenNativeCompose: () -> Unit,
    onOpenFlutter: () -> Unit,
    onBack: () -> Unit,
) {
    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Sounds & Notifications") },
                navigationIcon = {
                    TextButton(onClick = onBack) { Text("←", fontSize = 20.sp) }
                },
            )
        },
    ) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp),
        ) {
            Text(
                text = "Contact: $recipientId",
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
            )

            Text(
                text = "Choose implementation",
                style = MaterialTheme.typography.titleLarge,
                fontWeight = FontWeight.Bold,
            )

            Text(
                text = "Both screens read/write the same Pigeon KeyValueStorage. " +
                    "Changes made in one sync to the other in real-time.",
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
            )

            Spacer(modifier = Modifier.height(8.dp))

            // ── Native Compose card ──
            Card(
                onClick = onOpenNativeCompose,
                modifier = Modifier.fillMaxWidth(),
                colors = CardDefaults.cardColors(
                    containerColor = MaterialTheme.colorScheme.primaryContainer,
                ),
            ) {
                Row(
                    modifier = Modifier.padding(20.dp),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(16.dp),
                ) {
                    Text("📱", fontSize = 28.sp)
                    Column {
                        Text(
                            "Native Jetpack Compose",
                            style = MaterialTheme.typography.titleMedium,
                            fontWeight = FontWeight.Bold,
                            color = MaterialTheme.colorScheme.onPrimaryContainer,
                        )
                        Text(
                            "Compose screen inside this NavHost",
                            style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.onPrimaryContainer.copy(alpha = 0.7f),
                        )
                    }
                }
            }

            // ── Flutter card ──
            Card(
                onClick = onOpenFlutter,
                modifier = Modifier.fillMaxWidth(),
                colors = CardDefaults.cardColors(
                    containerColor = MaterialTheme.colorScheme.tertiaryContainer,
                ),
            ) {
                Row(
                    modifier = Modifier.padding(20.dp),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(16.dp),
                ) {
                    Text("🦋", fontSize = 28.sp)
                    Column {
                        Text(
                            "Flutter (Add2AppFlutterScreen)",
                            style = MaterialTheme.typography.titleMedium,
                            fontWeight = FontWeight.Bold,
                            color = MaterialTheme.colorScheme.onTertiaryContainer,
                        )
                        Text(
                            "Flutter screen via composable in same NavHost",
                            style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.onTertiaryContainer.copy(alpha = 0.7f),
                        )
                    }
                }
            }

            Spacer(modifier = Modifier.weight(1f))

            Text(
                text = "Both screens are destinations in the same Compose NavHost. " +
                    "The Flutter screen is embedded seamlessly using the " +
                    "Add2AppFlutterScreen composable from leancode_add2app. " +
                    "Back navigation and pop() work correctly via onBackPressedDispatcher.",
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
            )
        }
    }
}

// ── Native Compose Sounds & Notifications screen ─────────────────────────

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun NativeComposeSoundsNotifications(
    recipientId: String,
    onBack: () -> Unit,
) {
    // ── Storage scope — created once per recipientId, during composition.
    //    Read/write works immediately; observation starts in DisposableEffect. ──
    val storage = remember(recipientId) {
        KeyValueStorageImpl.createScope()
    }
    val store = remember(recipientId) {
        SoundsNotificationsStore(storage, contactId = recipientId)
    }

    // ── State — initialised from real storage values, no guessed defaults ──
    var muteNotifications by remember(recipientId) {
        mutableStateOf(store.mute)
    }
    var showPreviews by remember(recipientId) {
        mutableStateOf(store.showPreviews)
    }
    var notificationSound by remember(recipientId) {
        mutableStateOf(store.sound)
    }
    var vibrationLevel by remember(recipientId) {
        mutableStateOf(store.vibration)
    }
    var behavior by remember(recipientId) {
        mutableStateOf(store.behavior)
    }

    var showSoundPicker by remember { mutableStateOf(false) }
    var showVibrationPicker by remember { mutableStateOf(false) }
    var showBehaviorPicker by remember { mutableStateOf(false) }

    // ── Start observing after state is declared (runs after composition) ──
    DisposableEffect(recipientId) {
        storage.startObserving { entries ->
            if (store.containsChanges(entries)) {
                muteNotifications = store.mute
                showPreviews = store.showPreviews
                notificationSound = store.sound
                vibrationLevel = store.vibration
                behavior = store.behavior
            }
        }
        onDispose { storage.dispose() }
    }

    // ── UI ──

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Sounds & Notifications") },
                navigationIcon = {
                    TextButton(onClick = onBack) { Text("←", fontSize = 20.sp) }
                },
            )
        },
    ) { padding ->
        LazyColumn(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding),
        ) {
            // ── Banner ──
            item {
                Surface(
                    color = MaterialTheme.colorScheme.primaryContainer,
                    modifier = Modifier.fillMaxWidth(),
                ) {
                    Text(
                        text = "Native Jetpack Compose",
                        modifier = Modifier.padding(horizontal = 16.dp, vertical = 8.dp),
                        style = MaterialTheme.typography.labelMedium,
                        fontWeight = FontWeight.Bold,
                        color = MaterialTheme.colorScheme.onPrimaryContainer,
                    )
                }
            }

            // ── Contact info ──
            item {
                Text(
                    text = "Contact: $recipientId",
                    modifier = Modifier.padding(horizontal = 16.dp, vertical = 8.dp),
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                )
            }

            // ── Mute ──
            item {
                ListItem(
                    headlineContent = { Text("Mute notifications") },
                    supportingContent = if (muteNotifications) {
                        { Text("Notifications are muted") }
                    } else {
                        null
                    },
                    leadingContent = {
                        Text(if (muteNotifications) "🔕" else "🔔", fontSize = 22.sp)
                    },
                    trailingContent = {
                        Switch(
                            checked = muteNotifications,
                            onCheckedChange = { checked ->
                                muteNotifications = checked
                                store.mute = checked
                            },
                        )
                    },
                )
            }

            item { HorizontalDivider(modifier = Modifier.padding(start = 56.dp)) }

            // ── Notification sound ──
            item {
                ListItem(
                    headlineContent = { Text("Notification sound") },
                    supportingContent = { Text(notificationSound) },
                    leadingContent = { Text("🎵", fontSize = 22.sp) },
                    trailingContent = { Text("›", fontSize = 22.sp, color = MaterialTheme.colorScheme.onSurfaceVariant) },
                    modifier = Modifier.clickable { showSoundPicker = true },
                )
            }

            item { HorizontalDivider(modifier = Modifier.padding(start = 56.dp)) }

            // ── Vibration ──
            item {
                ListItem(
                    headlineContent = { Text("Vibrate") },
                    supportingContent = { Text(vibrationLevel.label) },
                    leadingContent = { Text("📳", fontSize = 22.sp) },
                    trailingContent = { Text("›", fontSize = 22.sp, color = MaterialTheme.colorScheme.onSurfaceVariant) },
                    modifier = Modifier.clickable { showVibrationPicker = true },
                )
            }

            item { HorizontalDivider(modifier = Modifier.padding(start = 56.dp)) }

            // ── Behavior ──
            item {
                ListItem(
                    headlineContent = { Text("Notification behavior") },
                    supportingContent = { Text(behavior.label) },
                    leadingContent = { Text("🎚", fontSize = 22.sp) },
                    trailingContent = { Text("›", fontSize = 22.sp, color = MaterialTheme.colorScheme.onSurfaceVariant) },
                    modifier = Modifier.clickable { showBehaviorPicker = true },
                )
            }

            // ── Section header ──
            item {
                Spacer(modifier = Modifier.height(24.dp))
                Text(
                    text = "MESSAGE NOTIFICATIONS",
                    modifier = Modifier.padding(horizontal = 16.dp, vertical = 8.dp),
                    style = MaterialTheme.typography.labelSmall,
                    fontWeight = FontWeight.Bold,
                    color = MaterialTheme.colorScheme.primary,
                    letterSpacing = 0.5.sp,
                )
            }

            // ── Show previews ──
            item {
                ListItem(
                    headlineContent = { Text("Show previews") },
                    supportingContent = { Text("Display message content in notifications") },
                    leadingContent = { Text("👁", fontSize = 22.sp) },
                    trailingContent = {
                        Switch(
                            checked = showPreviews,
                            onCheckedChange = { checked ->
                                showPreviews = checked
                                store.showPreviews = checked
                            },
                        )
                    },
                )
            }

            // ── Info text ──
            item {
                Spacer(modifier = Modifier.height(32.dp))
                Text(
                    text = "These settings override the default notification settings " +
                        "for this conversation.\n\n" +
                        "State is synced across all Flutter engines & Android via " +
                        "Pigeon KeyValueStorage. Changes you make here will appear " +
                        "instantly on the Flutter version and vice versa.",
                    modifier = Modifier.padding(horizontal = 16.dp),
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                )
            }

            item { Spacer(modifier = Modifier.height(48.dp)) }
        }
    }

    // ── Sound picker dialog ──

    if (showSoundPicker) {
        val sounds = listOf("Default", "Signal", "Pulse", "Chime", "Bamboo", "None")
        AlertDialog(
            onDismissRequest = { showSoundPicker = false },
            title = { Text("Notification Sound") },
            text = {
                Column {
                    sounds.forEach { sound ->
                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .clickable {
                                    notificationSound = sound
                                    store.sound = sound
                                    showSoundPicker = false
                                }
                                .padding(vertical = 12.dp, horizontal = 8.dp),
                            horizontalArrangement = Arrangement.SpaceBetween,
                            verticalAlignment = Alignment.CenterVertically,
                        ) {
                            Text(sound, style = MaterialTheme.typography.bodyLarge)
                            if (notificationSound == sound) {
                                Text("✓", color = MaterialTheme.colorScheme.primary, fontWeight = FontWeight.Bold)
                            }
                        }
                    }
                }
            },
            confirmButton = {},
        )
    }

    // ── Vibration picker dialog ──

    if (showVibrationPicker) {
        val patterns = VibrationLevel.entries
        AlertDialog(
            onDismissRequest = { showVibrationPicker = false },
            title = { Text("Vibration Pattern") },
            text = {
                Column {
                    patterns.forEach { pattern ->
                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .clickable {
                                    vibrationLevel = pattern
                                    store.vibration = pattern
                                    showVibrationPicker = false
                                }
                                .padding(vertical = 12.dp, horizontal = 8.dp),
                            horizontalArrangement = Arrangement.SpaceBetween,
                            verticalAlignment = Alignment.CenterVertically,
                        ) {
                            Text(pattern.label, style = MaterialTheme.typography.bodyLarge)
                            if (vibrationLevel == pattern) {
                                Text("✓", color = MaterialTheme.colorScheme.primary, fontWeight = FontWeight.Bold)
                            }
                        }
                    }
                }
            },
            confirmButton = {},
        )
    }

    // ── Behavior picker dialog ──

    if (showBehaviorPicker) {
        val behaviors = NotificationBehavior.entries
        AlertDialog(
            onDismissRequest = { showBehaviorPicker = false },
            title = { Text("Notification Behavior") },
            text = {
                Column {
                    behaviors.forEach { item ->
                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .clickable {
                                    behavior = item
                                    store.behavior = item
                                    showBehaviorPicker = false
                                }
                                .padding(vertical = 12.dp, horizontal = 8.dp),
                            horizontalArrangement = Arrangement.SpaceBetween,
                            verticalAlignment = Alignment.CenterVertically,
                        ) {
                            Text(item.label, style = MaterialTheme.typography.bodyLarge)
                            if (behavior == item) {
                                Text("✓", color = MaterialTheme.colorScheme.primary, fontWeight = FontWeight.Bold)
                            }
                        }
                    }
                }
            },
            confirmButton = {},
        )
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
