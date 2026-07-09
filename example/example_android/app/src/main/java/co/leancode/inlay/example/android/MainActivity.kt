package co.leancode.inlay.example.android

import android.content.Intent
import android.os.Bundle
import android.widget.Button
import androidx.appcompat.app.AlertDialog
import androidx.appcompat.app.AppCompatActivity
import co.leancode.inlay.InlayNavigator
import co.leancode.example_module.generated.BadgeLevel
import co.leancode.example_module.generated.ConfirmActionDialog
import co.leancode.example_module.generated.CounterPage
import co.leancode.example_module.generated.GreetingPage
import co.leancode.example_module.generated.GreetingStyle
import co.leancode.example_module.generated.ProfilePage
import co.leancode.example_module.generated.ThemePickerDialog
import co.leancode.example_module.generated.UserBadge

class MainActivity : AppCompatActivity() {
  override fun onCreate(savedInstanceState: Bundle?) {
    super.onCreate(savedInstanceState)
    setContentView(R.layout.activity_main)

    findViewById<Button>(R.id.btnGreeting).setOnClickListener {
      InlayNavigator.push(
        this,
        GreetingPage(name = "Android", style = GreetingStyle.casual),
      )
    }

    findViewById<Button>(R.id.btnCounter).setOnClickListener {
      // Native -> Flutter -> typed result back (count: Long?).
      InlayNavigator.push(this, CounterPage(seed = null)) { count ->
        showResult("Counter", count?.toString() ?: "dismissed")
      }
    }

    findViewById<Button>(R.id.btnProfile).setOnClickListener {
      InlayNavigator.push(
        this,
        ProfilePage(
          userId = "42",
          badges = listOf(UserBadge("Native badge", BadgeLevel.gold)),
        ),
      )
    }

    findViewById<Button>(R.id.btnNativeSettings).setOnClickListener {
      startActivity(Intent(this, NativeSettingsActivity::class.java))
    }

    findViewById<Button>(R.id.btnFragmentDemo).setOnClickListener {
      startActivity(Intent(this, FlutterCounterFragmentActivity::class.java))
    }

    findViewById<Button>(R.id.btnComposeDemo).setOnClickListener {
      startActivity(Intent(this, ComposeActivity::class.java))
    }

    findViewById<Button>(R.id.btnConfirmDialog).setOnClickListener {
      // Native -> Flutter dialog -> typed result back (confirmed: Boolean?).
      InlayNavigator.presentDialog(
        this,
        ConfirmActionDialog(action = "delete", message = "Are you sure?"),
      ) { confirmed ->
        showResult("Confirm dialog", confirmed?.toString() ?: "dismissed")
      }
    }

    findViewById<Button>(R.id.btnThemePickerDialog).setOnClickListener {
      InlayNavigator.presentDialog(
        this,
        ThemePickerDialog(userId = "42"),
      )
    }
  }

  private fun showResult(label: String, value: String) {
    AlertDialog.Builder(this)
      .setTitle("$label returned")
      .setMessage(value)
      .setPositiveButton("OK", null)
      .show()
  }
}
