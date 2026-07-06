package co.leancode.inlay

/** Theme preference propagated to all Flutter engines. */
enum class InlayThemeMode(val rawValue: String) {
    SYSTEM("system"),
    LIGHT("light"),
    DARK("dark");

    companion object {
        internal fun fromRaw(raw: String?): InlayThemeMode =
            entries.firstOrNull { it.rawValue == raw } ?: SYSTEM
    }
}

/**
 * Host-side control of app-level appearance settings shared with every
 * Flutter engine: theme mode and an optional in-app locale override.
 *
 * Values live in the framework's cross-engine storage, so every engine
 * (including ones created later) reads the current values at startup and
 * follows changes live via `InlayAppearance` on the Dart side.
 *
 * ```kotlin
 * InlayAppearance.themeMode = InlayThemeMode.DARK
 * InlayAppearance.localeLanguageTag = "pl-PL"
 * InlayAppearance.localeLanguageTag = null  // follow system again
 * ```
 */
object InlayAppearance {

    private const val THEME_MODE_KEY = "__inlay/appearance/themeMode"
    private const val LOCALE_KEY = "__inlay/appearance/locale"

    private val scope by lazy { KeyValueStorageImpl.createScope() }

    /** The app-wide theme mode. [InlayThemeMode.SYSTEM] when never set. */
    var themeMode: InlayThemeMode
        get() = InlayThemeMode.fromRaw(scope.get(THEME_MODE_KEY))
        set(value) {
            scope.put(THEME_MODE_KEY, value.rawValue)
        }

    /**
     * The in-app locale override as a BCP-47 language tag (e.g. "pl-PL"),
     * or `null` to follow the system locale.
     */
    var localeLanguageTag: String?
        get() = scope.get(LOCALE_KEY)
        set(value) {
            if (value != null) {
                scope.put(LOCALE_KEY, value)
            } else {
                scope.remove(LOCALE_KEY)
            }
        }
}
