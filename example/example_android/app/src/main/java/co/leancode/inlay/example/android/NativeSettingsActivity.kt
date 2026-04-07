package co.leancode.inlay.example.android

import android.os.Bundle
import android.widget.Button
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity
import co.leancode.inlay.InlayNavigator
import co.leancode.inlay.KeyValueStorageImpl
import co.leancode.inlay.NativeStorageScope
import co.leancode.example_module.generated.AppTheme
import co.leancode.example_module.generated.NotificationPreferences
import co.leancode.example_module.generated.ProfilePage
import co.leancode.example_module.generated.UserPreferencesStore

class NativeSettingsActivity : AppCompatActivity() {
  private lateinit var storage: NativeStorageScope
  private lateinit var store: UserPreferencesStore

  private lateinit var displayNameValue: TextView
  private lateinit var emailValue: TextView
  private lateinit var darkModeValue: TextView
  private lateinit var themeValue: TextView
  private lateinit var tagsValue: TextView
  private lateinit var notifPrefsValue: TextView

  override fun onCreate(savedInstanceState: Bundle?) {
    super.onCreate(savedInstanceState)
    setContentView(R.layout.activity_native_settings)

    title = "Native Settings"
    displayNameValue = findViewById(R.id.valueDisplayName)
    emailValue = findViewById(R.id.valueEmail)
    darkModeValue = findViewById(R.id.valueDarkMode)
    themeValue = findViewById(R.id.valueTheme)
    tagsValue = findViewById(R.id.valueTags)
    notifPrefsValue = findViewById(R.id.valueNotifPrefs)

    storage = KeyValueStorageImpl.createScope()
    store = UserPreferencesStore(storage, userId = "42")
    storage.startObserving { runOnUiThread { render() } }

    findViewById<Button>(R.id.btnSetDemoValues).setOnClickListener {
      store.displayName = "Native User"
      store.email = "native42@example.com"
      render()
    }
    findViewById<Button>(R.id.btnToggleDarkMode).setOnClickListener {
      store.darkMode = !store.darkMode
      render()
    }
    findViewById<Button>(R.id.btnThemeSystem).setOnClickListener {
      store.theme = AppTheme.system
      render()
    }
    findViewById<Button>(R.id.btnThemeLight).setOnClickListener {
      store.theme = AppTheme.light
      render()
    }
    findViewById<Button>(R.id.btnThemeDark).setOnClickListener {
      store.theme = AppTheme.dark
      render()
    }
    findViewById<Button>(R.id.btnAddTag).setOnClickListener {
      val current = store.tags
      if (!current.contains("android")) {
        store.tags = current + listOf("android")
      }
      render()
    }
    findViewById<Button>(R.id.btnSetNotifPrefs).setOnClickListener {
      store.notificationPreferences = NotificationPreferences("Bell", true)
      render()
    }
    findViewById<Button>(R.id.btnClearNotifPrefs).setOnClickListener {
      store.notificationPreferences = null
      render()
    }
    findViewById<Button>(R.id.btnOpenFlutterProfile).setOnClickListener {
      InlayNavigator.push(this, ProfilePage(userId = "42", badges = null))
    }

    render()
  }

  override fun onDestroy() {
    super.onDestroy()
    storage.dispose()
  }

  private fun render() {
    displayNameValue.text = store.displayName
    emailValue.text = store.email
    darkModeValue.text = if (store.darkMode) "on" else "off"
    themeValue.text = store.theme.name
    tagsValue.text = store.tags.ifEmpty { listOf("(none)") }.joinToString(", ")
    val prefs = store.notificationPreferences
    notifPrefsValue.text = if (prefs != null) "sound=${prefs.sound}, vibration=${prefs.vibration}" else "(not set)"
  }
}
