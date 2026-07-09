package co.leancode.inlay.example.android

import android.os.Bundle
import android.widget.Button
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity
import androidx.appcompat.widget.SwitchCompat
import co.leancode.inlay.InlayAppearance
import co.leancode.inlay.InlayNavigator
import co.leancode.inlay.InlayThemeMode
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
  private lateinit var routingValue: TextView

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
    routingValue = findViewById(R.id.valueRouting)

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
    // App-level appearance (InlayAppearance): applied by every Flutter
    // engine's MaterialApp, unlike the store-based theme demo above which
    // is plain shared state.
    findViewById<Button>(R.id.btnFlutterThemeSystem).setOnClickListener {
      InlayAppearance.themeMode = InlayThemeMode.SYSTEM
    }
    findViewById<Button>(R.id.btnFlutterThemeDark).setOnClickListener {
      InlayAppearance.themeMode = InlayThemeMode.DARK
    }
    findViewById<Button>(R.id.btnFlutterLangPolish).setOnClickListener {
      InlayAppearance.localeLanguageTag = "pl"
    }
    findViewById<Button>(R.id.btnFlutterLangSystem).setOnClickListener {
      InlayAppearance.localeLanguageTag = null
    }
    findViewById<Button>(R.id.btnOpenFlutterProfile).setOnClickListener {
      InlayNavigator.push(this, ProfilePage(userId = "42", badges = null))
    }
    // Framework-level controls: engine prewarming + the Dart entrypoint
    // used for new engines (routing integration demo).
    findViewById<SwitchCompat>(R.id.switchPrewarm).apply {
      isChecked = InlayNavigator.isPrewarmEnabled
      setOnCheckedChangeListener { _, isChecked ->
        InlayNavigator.setPrewarmEnabled(isChecked)
      }
    }
    findViewById<Button>(R.id.btnRoutingGoRouter).setOnClickListener {
      setRouting("inlayGoRouterMain")
    }
    findViewById<Button>(R.id.btnRoutingAutoRoute).setOnClickListener {
      setRouting("inlayAutoRouteMain")
    }
    findViewById<Button>(R.id.btnRoutingImperative).setOnClickListener {
      setRouting("inlayImperativeMain")
    }

    render()
  }

  private fun setRouting(entrypoint: String) {
    InlayNavigator.setDartEntrypoint(entrypoint)
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
    routingValue.text = InlayNavigator.dartEntrypoint
  }
}
