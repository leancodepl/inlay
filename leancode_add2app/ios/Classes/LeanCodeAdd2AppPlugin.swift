import Flutter

/// No-op Flutter plugin class.
///
/// This class exists solely so that Flutter's build system recognises
/// `leancode_add2app` as a plugin and bundles the Swift sources into
/// the iOS framework artifact. All actual engine/channel setup is
/// performed explicitly by `Add2AppNavigator`.
public class LeanCodeAdd2AppPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        // No-op.
    }
}
