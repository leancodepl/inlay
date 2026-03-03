package co.leancode.add2app

import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier

/**
 * Compose-ready wrapper that renders a Flutter dialog described by [route]
 * as a regular Compose destination.
 *
 * Use in a Compose Navigation `dialog()` destination:
 * ```kotlin
 * NavHost(navController, startDestination = "home") {
 *     composable("home") { HomeScreen() }
 *     dialog("confirm-delete/{itemId}") { entry ->
 *         Add2AppFlutterDialogScreen(
 *             route = ConfirmDeleteDialog(itemId = entry.arguments!!.getString("itemId")!!),
 *             modifier = Modifier.fillMaxSize(),
 *         )
 *     }
 * }
 * ```
 *
 * Under the hood this delegates to [Add2AppFlutterScreen] with the dialog
 * route's [PageSettings]. Flutter handles the visual overlay.
 */
@Composable
fun Add2AppFlutterDialogScreen(
    route: FlutterDialogRoute,
    modifier: Modifier = Modifier,
) {
    Add2AppFlutterScreen(route = route.toPageSettings(), modifier = modifier)
}
