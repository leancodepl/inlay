import Foundation

public protocol FlutterRoute {
    func toPageSettings() -> PageSettings
}

public protocol FlutterDialogRoute {
    func toPageSettings() -> PageSettings
}

/// A ``FlutterRoute`` whose screen returns a typed result.
///
/// Generated route structs with a `result:` type conform to this protocol
/// (`ResultValue` is inferred from the generated `decodeResult`), which lets
/// `InlayNavigator.push` and the SwiftUI wrappers deliver an already-decoded
/// `ResultValue?` instead of a raw `Any?`.
public protocol FlutterRouteWithResult: FlutterRoute {
    associatedtype ResultValue
    /// Decodes the wire-format result into `ResultValue`; `nil` stays `nil`.
    static func decodeResult(_ raw: Any?) -> ResultValue?
}

/// A ``FlutterDialogRoute`` whose dialog returns a typed result.
public protocol FlutterDialogRouteWithResult: FlutterDialogRoute {
    associatedtype ResultValue
    /// Decodes the wire-format result into `ResultValue`; `nil` stays `nil`.
    static func decodeResult(_ raw: Any?) -> ResultValue?
}
