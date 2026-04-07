package co.leancode.inlay.example.android

import android.os.Bundle
import android.widget.Button
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity
import co.leancode.inlay.InlayNavigator
import co.leancode.inlay.KeyValueStorageImpl
import co.leancode.inlay.NativeStorageScope
import co.leancode.example_module.generated.CounterPage
import co.leancode.example_module.generated.CounterStore

class FlutterCounterFragmentActivity : AppCompatActivity() {
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

  private fun render() {
    value.text = "Native counter mirror: ${store.count}"
  }
}
