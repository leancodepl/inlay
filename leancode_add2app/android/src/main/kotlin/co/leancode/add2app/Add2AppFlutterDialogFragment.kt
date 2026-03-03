package co.leancode.add2app

import android.graphics.Color
import android.graphics.drawable.ColorDrawable
import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.view.WindowManager
import androidx.fragment.app.DialogFragment
import androidx.fragment.app.FragmentContainerView

/**
 * A [DialogFragment] that hosts a Flutter engine with a fullscreen transparent window.
 *
 * The dialog presents a transparent overlay — Flutter renders the dialog content
 * (barrier, animation, positioning). No manifest or theme changes are needed;
 * the transparent window is configured programmatically.
 *
 * Usage:
 * ```kotlin
 * val dialogFragment = Add2AppNavigator.createDialogFragment(
 *     context, ConfirmDeleteDialog(itemId = "42")
 * )
 * dialogFragment.show(supportFragmentManager, "confirm-delete")
 * ```
 *
 * The child [Add2AppFlutterFragment] uses back-dispatcher mode, so Flutter's
 * `pop()` calls `onBackPressedDispatcher.onBackPressed()` which dismisses
 * this DialogFragment.
 */
class Add2AppFlutterDialogFragment : DialogFragment() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setStyle(STYLE_NO_FRAME, android.R.style.Theme_Translucent_NoTitleBar)
    }

    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?,
    ): View {
        return FragmentContainerView(requireContext()).apply {
            id = View.generateViewId()
        }
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)
        if (savedInstanceState == null) {
            val routeId = arguments?.getString(EXTRA_DIALOG_ROUTE_ID)
            val routeData = Add2AppNavigator.consumePendingRouteData(routeId)
                ?: return
            val fragment = Add2AppNavigator.createDialogFlutterFragment(
                requireContext(),
                routeData,
            )
            childFragmentManager.beginTransaction()
                .replace(view.id, fragment)
                .commitNow()
        }
    }

    override fun onStart() {
        super.onStart()
        dialog?.window?.apply {
            setLayout(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.MATCH_PARENT,
            )
            setBackgroundDrawable(ColorDrawable(Color.TRANSPARENT))
            clearFlags(WindowManager.LayoutParams.FLAG_DIM_BEHIND)
        }
    }

    companion object {
        internal const val EXTRA_DIALOG_ROUTE_ID = "add2app_dialog_route_id"
    }
}
