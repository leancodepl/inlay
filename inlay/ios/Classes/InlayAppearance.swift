import Foundation

/// Theme preference propagated to all Flutter engines.
public enum InlayThemeMode: String {
    case system
    case light
    case dark
}

/// Host-side control of app-level appearance settings shared with every
/// Flutter engine: theme mode and an optional in-app locale override.
///
/// Values live in the framework's cross-engine storage, so every engine
/// (including ones created later) reads the current values at startup and
/// follows changes live via `InlayAppearance` on the Dart side.
///
/// ```swift
/// InlayAppearance.shared.themeMode = .dark
/// InlayAppearance.shared.localeLanguageTag = "pl-PL"
/// InlayAppearance.shared.localeLanguageTag = nil  // follow system again
/// ```
public final class InlayAppearance {

    public static let shared = InlayAppearance()

    private static let themeModeKey = "__inlay/appearance/themeMode"
    private static let localeKey = "__inlay/appearance/locale"

    private let scope: NativeStorageScope

    private init() {
        scope = KeyValueStorageImpl.shared.createScope()
    }

    /// The app-wide theme mode. `.system` when never set.
    public var themeMode: InlayThemeMode {
        get {
            scope.get(key: Self.themeModeKey)
                .flatMap(InlayThemeMode.init(rawValue:)) ?? .system
        }
        set {
            scope.put(key: Self.themeModeKey, value: newValue.rawValue)
        }
    }

    /// The in-app locale override as a BCP-47 language tag (e.g. "pl-PL"),
    /// or `nil` to follow the system locale.
    public var localeLanguageTag: String? {
        get {
            scope.get(key: Self.localeKey)
        }
        set {
            if let tag = newValue {
                scope.put(key: Self.localeKey, value: tag)
            } else {
                _ = scope.remove(key: Self.localeKey)
            }
        }
    }
}
