package co.leancode.inlay

import co.leancode.inlay.navigator.PageSettings

interface FlutterRoute {
    fun toPageSettings(): PageSettings
}

interface FlutterDialogRoute {
    fun toPageSettings(): PageSettings
}

/**
 * A [FlutterRoute] whose screen returns a typed result of type [R].
 *
 * Generated route classes with a `result:` type implement this interface,
 * which lets [InlayNavigator.push] and the embedding wrappers deliver an
 * already-decoded `R?` instead of a raw `Any?`.
 */
interface FlutterRouteWithResult<R : Any> : FlutterRoute {
    /** Decodes the wire-format result into [R]; `null` stays `null`. */
    fun decodeResult(raw: Any?): R?
}

/**
 * A [FlutterDialogRoute] whose dialog returns a typed result of type [R].
 */
interface FlutterDialogRouteWithResult<R : Any> : FlutterDialogRoute {
    /** Decodes the wire-format result into [R]; `null` stays `null`. */
    fun decodeResult(raw: Any?): R?
}
