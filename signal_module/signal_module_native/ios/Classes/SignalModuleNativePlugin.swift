import Flutter

/// No-op Flutter plugin class.
///
/// This class exists solely so that Flutter's build system recognises
/// `signal_module_native` as a plugin and bundles the Swift sources
/// into the iOS framework artifact.
public class SignalModuleNativePlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        // No-op.
    }
}
