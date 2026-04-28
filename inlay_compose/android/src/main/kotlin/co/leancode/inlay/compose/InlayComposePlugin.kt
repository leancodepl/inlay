package co.leancode.inlay.compose

import io.flutter.embedding.engine.plugins.FlutterPlugin

/**
 * No-op Flutter plugin class.
 *
 * Exists solely so that Flutter's build system recognises `inlay_compose`
 * as a plugin and bundles the Kotlin sources into the AAR artifact. All
 * actual Compose helpers are public top-level composables in this package.
 */
class InlayComposePlugin : FlutterPlugin {
    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        // No-op.
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        // No-op.
    }
}
