import Flutter

/// No-op Flutter plugin class.
///
/// This class exists solely so that Flutter's build system recognises
/// `example_module_native` as a plugin and bundles the Swift sources
/// into the iOS artifact (Swift package or CocoaPods framework).
public class ExampleModuleNativePlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        // No-op.
    }
}
