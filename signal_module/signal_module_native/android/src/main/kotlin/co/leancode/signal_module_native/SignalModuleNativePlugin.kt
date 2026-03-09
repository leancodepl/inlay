package co.leancode.signal_module_native

import io.flutter.embedding.engine.plugins.FlutterPlugin

/**
 * No-op Flutter plugin class.
 *
 * This class exists solely so that Flutter's build system recognises
 * `signal_module_native` as a plugin and bundles the Kotlin sources
 * into the AAR artifact.
 */
class SignalModuleNativePlugin : FlutterPlugin {
    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        // No-op.
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        // No-op.
    }
}
