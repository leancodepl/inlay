package co.leancode.inlay

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
 * val dialogFragment = InlayNavigator.createDialogFragment(
 *     context, ConfirmDeleteDialog(itemId = "42")
 * )
 * dialogFragment.show(supportFragmentManager, "confirm-delete")
 * ```
 *
 * The child [InlayFlutterFragment] uses back-dispatcher mode, so Flutter's
 * `pop()` calls `onBackPressedDispatcher.onBackPressed()` which dismisses
 * this DialogFragment.
 */
class InlayFlutterDialogFragment : DialogFragment() {

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
            // Route data lives in this fragment's arguments (see
            // InlayNavigator.createDialogFragment).
            val routeData = InlayNavigator.readRouteData(arguments) ?: return
            val fragment = InlayNavigator.createDialogFlutterFragment(
                requireContext(),
                routeData,
            )
            // The result callback (if any) is registered under this dialog's
            // result id; the child fragment's engine delivers pop(result) to it.
            arguments?.getString(InlayNavigator.EXTRA_RESULT_ID)?.let {
                fragment.requireArguments().putString(InlayNavigator.EXTRA_RESULT_ID, it)
            }
            // Dismiss the DialogFragment directly instead of going through
            // onBackPressedDispatcher, which would re-enter the FlutterFragment's
            // own back-pressed callback and finish the activity.
            fragment.onPopOverride = { dismiss() }
            childFragmentManager.beginTransaction()
                .replace(view.id, fragment)
                .commitNow()
        }
    }

    override fun onDestroyView() {
        // Dismissed without an explicit result (barrier tap, back) - the
        // caller still gets its callback, with null. deliverResult is
        // exactly-once, so this is a no-op after pop(result).
        InlayNavigator.deliverResult(arguments?.getString(InlayNavigator.EXTRA_RESULT_ID), null)
        super.onDestroyView()
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
            // Extend the window behind system bars so no black bars appear.
            addFlags(WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS)
        }
    }

}
