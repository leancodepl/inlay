package co.leancode.inlay.example.android

import android.os.Bundle
import android.widget.Button
import android.widget.EditText
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity

class NativeAboutActivity : AppCompatActivity() {
  private var feedbackDelivered = false

  override fun onCreate(savedInstanceState: Bundle?) {
    super.onCreate(savedInstanceState)
    setContentView(R.layout.activity_native_about)

    title = "Native About"
    val version = ExampleNativeRouteHandler.readVersion(intent)
    findViewById<TextView>(R.id.textVersion).text = "Version: $version"

    val input = findViewById<EditText>(R.id.inputFeedback)
    findViewById<Button>(R.id.btnSendFeedback).setOnClickListener {
      deliver(input.text.toString())
      finish()
    }
  }

  override fun onDestroy() {
    // Closed without sending (system back, task swipe): the Flutter caller
    // still gets its result, empty.
    if (isFinishing) {
      deliver("")
    }
    super.onDestroy()
  }

  /** Delivers [feedback] to the awaiting Flutter caller exactly once. */
  private fun deliver(feedback: String) {
    if (feedbackDelivered) return
    feedbackDelivered = true
    ExampleNativeRouteHandler.deliverAboutFeedback(feedback)
  }
}
