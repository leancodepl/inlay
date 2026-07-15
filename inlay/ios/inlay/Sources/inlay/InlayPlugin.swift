import Flutter

/// No-op Flutter plugin class.
///
/// This class exists solely so that Flutter's build system recognises
/// `inlay` as a plugin and bundles the Swift sources into
/// the iOS framework artifact. All actual engine/channel setup is
/// performed explicitly by `InlayNavigator`.
public class InlayPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        // No-op.
    }
}
