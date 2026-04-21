package co.leancode.inlay

import android.content.Intent
import androidx.fragment.app.FragmentActivity
import androidx.fragment.app.FragmentManager

/**
 * Forwards Activity callbacks to every [InlayFlutterFragment] attached
 * under an Activity's [FragmentActivity.getSupportFragmentManager].
 *
 * `FlutterFragment` documents that a host Activity MUST forward
 * `onPostResume()`, `onNewIntent()`, `onBackPressed()`, `onActivityResult()`,
 * `onRequestPermissionsResult()`, `onUserLeaveHint()`, and `onTrimMemory()`
 * — without this, deep links, back handling, lifecycle hooks, and memory
 * trimming never reach Flutter.
 *
 * If you can extend [InlayFlutterHostActivity], do that — it wires
 * the forwarding automatically. Use this delegate from your own Activity
 * when you must extend a different base class (e.g.
 * [androidx.appcompat.app.AppCompatActivity]):
 *
 * ```kotlin
 * class MyActivity : AppCompatActivity() {
 *     private val inlayHost by lazy { InlayFragmentHostDelegate(this) }
 *
 *     override fun onPostResume() {
 *         super.onPostResume(); inlayHost.onPostResume()
 *     }
 *     override fun onNewIntent(intent: Intent) {
 *         super.onNewIntent(intent); inlayHost.onNewIntent(intent)
 *     }
 *     override fun onBackPressed() {
 *         if (!inlayHost.onBackPressed()) super.onBackPressed()
 *     }
 *     override fun onUserLeaveHint() {
 *         super.onUserLeaveHint(); inlayHost.onUserLeaveHint()
 *     }
 *     override fun onTrimMemory(level: Int) {
 *         super.onTrimMemory(level); inlayHost.onTrimMemory(level)
 *     }
 *     override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
 *         super.onActivityResult(requestCode, resultCode, data)
 *         inlayHost.onActivityResult(requestCode, resultCode, data)
 *     }
 *     override fun onRequestPermissionsResult(
 *         requestCode: Int, permissions: Array<out String>, grantResults: IntArray,
 *     ) {
 *         super.onRequestPermissionsResult(requestCode, permissions, grantResults)
 *         inlayHost.onRequestPermissionsResult(requestCode, permissions, grantResults)
 *     }
 * }
 * ```
 *
 * Traversal descends into every fragment's child FragmentManager, so
 * nested [InlayFlutterFragment]s (including the one inside
 * [InlayFlutterDialogFragment]) are covered.
 */
class InlayFragmentHostDelegate(private val activity: FragmentActivity) {

    private fun fragments(): List<InlayFlutterFragment> =
        collect(activity.supportFragmentManager)

    fun onPostResume() {
        fragments().forEach { it.onPostResume() }
    }

    fun onNewIntent(intent: Intent) {
        fragments().forEach { it.onNewIntent(intent) }
    }

    /**
     * Dispatches the back press to every attached [InlayFlutterFragment].
     *
     * @return `true` if at least one fragment received the event — caller
     *   should skip `super.onBackPressed()` in that case, letting Flutter
     *   decide whether to finish the Activity.
     */
    fun onBackPressed(): Boolean {
        val fs = fragments()
        if (fs.isEmpty()) return false
        fs.forEach { it.onBackPressed() }
        return true
    }

    fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        fragments().forEach { it.onActivityResult(requestCode, resultCode, data) }
    }

    fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        fragments().forEach {
            it.onRequestPermissionsResult(requestCode, permissions, grantResults)
        }
    }

    fun onUserLeaveHint() {
        fragments().forEach { it.onUserLeaveHint() }
    }

    fun onTrimMemory(level: Int) {
        fragments().forEach { it.onTrimMemory(level) }
    }

    private fun collect(fm: FragmentManager): List<InlayFlutterFragment> {
        val out = mutableListOf<InlayFlutterFragment>()
        walk(fm, out)
        return out
    }

    private fun walk(fm: FragmentManager, out: MutableList<InlayFlutterFragment>) {
        for (f in fm.fragments) {
            if (f is InlayFlutterFragment) out += f
            if (f.isAdded) walk(f.childFragmentManager, out)
        }
    }
}
