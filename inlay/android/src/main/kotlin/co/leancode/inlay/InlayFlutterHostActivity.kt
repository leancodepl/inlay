package co.leancode.inlay

import android.content.Intent
import androidx.fragment.app.FragmentActivity

/**
 * Convenience base class for Activities that host [InlayFlutterFragment]
 * directly (via [InlayNavigator.createFragment]) or indirectly (e.g.
 * through `InlayFlutterScreen` from the optional `inlay_compose` plugin,
 * or [InlayFlutterDialogFragment]).
 *
 * Flutter's `FlutterFragment` requires the host Activity to forward seven
 * callbacks to it. This class does that forwarding using
 * [InlayFragmentHostDelegate], so subclasses don't have to remember.
 *
 * If you need a different base class (typically
 * [androidx.appcompat.app.AppCompatActivity]), use
 * [InlayFragmentHostDelegate] from your own Activity overrides instead.
 */
open class InlayFlutterHostActivity : FragmentActivity() {
    private val inlayHost by lazy { InlayFragmentHostDelegate(this) }

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
}
