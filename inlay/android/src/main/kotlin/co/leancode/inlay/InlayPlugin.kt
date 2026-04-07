package co.leancode.inlay

import io.flutter.embedding.engine.plugins.FlutterPlugin

/**
 * No-op Flutter plugin class.
 *
 * This class exists solely so that Flutter's build system recognises
 * `inlay` as a plugin and bundles the Kotlin sources into
 * the AAR artifact. All actual engine/channel setup is performed
 * explicitly by [InlayNavigator].
 */
class InlayPlugin : FlutterPlugin {
    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        // No-op.
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        // No-op.
    }
}
