package co.leancode.add2app.example.android

import android.os.Bundle
import android.widget.Button
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity
import co.leancode.add2app.Add2AppNavigator
import co.leancode.add2app.KeyValueStorageImpl
import co.leancode.add2app.NativeStorageScope
import co.leancode.example_module.generated.AppTheme
import co.leancode.example_module.generated.ProfilePage
import co.leancode.example_module.generated.UserPreferencesStore

class NativeSettingsActivity : AppCompatActivity() {
  private lateinit var storage: NativeStorageScope
  private lateinit var store: UserPreferencesStore

  private lateinit var displayNameValue: TextView
  private lateinit var emailValue: TextView
  private lateinit var darkModeValue: TextView
  private lateinit var themeValue: TextView

  override fun onCreate(savedInstanceState: Bundle?) {
    super.onCreate(savedInstanceState)
    setContentView(R.layout.activity_native_settings)

    title = "Native Settings"
    displayNameValue = findViewById(R.id.valueDisplayName)
    emailValue = findViewById(R.id.valueEmail)
    darkModeValue = findViewById(R.id.valueDarkMode)
    themeValue = findViewById(R.id.valueTheme)

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
    findViewById<Button>(R.id.btnOpenFlutterProfile).setOnClickListener {
      Add2AppNavigator.push(this, ProfilePage(userId = "42", badges = null))
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
  }
}
