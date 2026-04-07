package co.leancode.inlay

import co.leancode.inlay.navigator.PageSettings

interface FlutterRoute {
    fun toPageSettings(): PageSettings
}

interface FlutterDialogRoute {
    fun toPageSettings(): PageSettings
}
