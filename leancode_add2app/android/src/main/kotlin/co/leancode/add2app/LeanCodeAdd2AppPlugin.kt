package co.leancode.add2app

import io.flutter.embedding.engine.plugins.FlutterPlugin

/**
 * No-op Flutter plugin class.
 *
 * This class exists solely so that Flutter's build system recognises
 * `leancode_add2app` as a plugin and bundles the Kotlin sources into
 * the AAR artifact. All actual engine/channel setup is performed
 * explicitly by [Add2AppNavigator].
 */
class LeanCodeAdd2AppPlugin : FlutterPlugin {
    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        // No-op.
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        // No-op.
    }
}
