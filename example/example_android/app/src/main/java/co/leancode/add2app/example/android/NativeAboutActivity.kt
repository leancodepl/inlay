package co.leancode.add2app.example.android

import android.os.Bundle
import android.widget.Button
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity

class NativeAboutActivity : AppCompatActivity() {
  override fun onCreate(savedInstanceState: Bundle?) {
    super.onCreate(savedInstanceState)
    setContentView(R.layout.activity_native_about)

    title = "Native About"
    val version = ExampleNativeRouteHandler.readVersion(intent)
    findViewById<TextView>(R.id.textVersion).text = "Version: $version"
    findViewById<Button>(R.id.btnClose).setOnClickListener { finish() }
  }
}
