package co.leancode.inlay.example.android

import android.content.Intent
import android.os.Bundle
import android.widget.Button
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity
import co.leancode.inlay.InlayFragmentHostDelegate
import co.leancode.inlay.InlayNavigator
import co.leancode.inlay.KeyValueStorageImpl
import co.leancode.inlay.NativeStorageScope
import co.leancode.example_module.generated.CounterPage
import co.leancode.example_module.generated.CounterStore

class FlutterCounterFragmentActivity : AppCompatActivity() {
  private val inlayHost by lazy { InlayFragmentHostDelegate(this) }
  private lateinit var storage: NativeStorageScope
  private lateinit var store: CounterStore
  private lateinit var value: TextView

  override fun onCreate(savedInstanceState: Bundle?) {
    super.onCreate(savedInstanceState)
    setContentView(R.layout.activity_fragment_counter)
    title = "Fragment + Flutter Counter"

    storage = KeyValueStorageImpl.createScope()
    store = CounterStore(storage)
    value = findViewById(R.id.counterValue)
    storage.startObserving { runOnUiThread { render() } }

    findViewById<Button>(R.id.btnNativePlus).setOnClickListener {
      store.count = store.count + 1
      store.lastUpdatedBy = "android-fragment"
      render()
    }
    findViewById<Button>(R.id.btnNativeMinus).setOnClickListener {
      store.count = store.count - 1
      store.lastUpdatedBy = "android-fragment"
      render()
    }

    if (savedInstanceState == null) {
      val fragment = InlayNavigator.createFragment(this, CounterPage(seed = null))
      supportFragmentManager
        .beginTransaction()
        .replace(R.id.flutterContainer, fragment)
        .commit()
    }

    render()
  }

  override fun onDestroy() {
    super.onDestroy()
    storage.dispose()
  }

  override fun onPostResume() {
    super.onPostResume()
    inlayHost.onPostResume()
  }

  override fun onNewIntent(intent: Intent) {
    super.onNewIntent(intent)
    inlayHost.onNewIntent(intent)
  }

  @Deprecated("Deprecated in Java")
  override fun onBackPressed() {
    if (!inlayHost.onBackPressed()) {
      @Suppress("DEPRECATION")
      super.onBackPressed()
    }
  }

  @Deprecated("Deprecated in Java")
  override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
    @Suppress("DEPRECATION")
    super.onActivityResult(requestCode, resultCode, data)
    inlayHost.onActivityResult(requestCode, resultCode, data)
  }

  override fun onRequestPermissionsResult(
    requestCode: Int,
    permissions: Array<out String>,
    grantResults: IntArray,
  ) {
    super.onRequestPermissionsResult(requestCode, permissions, grantResults)
    inlayHost.onRequestPermissionsResult(requestCode, permissions, grantResults)
  }

  override fun onUserLeaveHint() {
    super.onUserLeaveHint()
    inlayHost.onUserLeaveHint()
  }

  override fun onTrimMemory(level: Int) {
    super.onTrimMemory(level)
    inlayHost.onTrimMemory(level)
  }

  private fun render() {
    value.text = "Native counter mirror: ${store.count}"
  }
}
