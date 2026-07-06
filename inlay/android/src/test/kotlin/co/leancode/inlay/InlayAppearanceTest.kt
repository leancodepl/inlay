package co.leancode.inlay

import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

class InlayAppearanceTest {

    @After
    fun tearDown() {
        KeyValueStorageImpl.clearInternal()
    }

    @Test
    fun `theme mode defaults to system and round-trips`() {
        assertEquals(InlayThemeMode.SYSTEM, InlayAppearance.themeMode)

        InlayAppearance.themeMode = InlayThemeMode.DARK

        assertEquals(InlayThemeMode.DARK, InlayAppearance.themeMode)
        assertEquals(
            "dark",
            KeyValueStorageImpl.getInternal("__inlay/appearance/themeMode")?.value,
        )
    }

    @Test
    fun `locale override round-trips and clears`() {
        assertNull(InlayAppearance.localeLanguageTag)

        InlayAppearance.localeLanguageTag = "pl-PL"
        assertEquals("pl-PL", InlayAppearance.localeLanguageTag)

        InlayAppearance.localeLanguageTag = null
        assertNull(InlayAppearance.localeLanguageTag)
        assertNull(KeyValueStorageImpl.getInternal("__inlay/appearance/locale"))
    }

    @Test
    fun `unknown stored value falls back to system`() {
        KeyValueStorageImpl.putInternal(
            co.leancode.inlay.storage.StorageEntry("__inlay/appearance/themeMode", "purple"),
        )

        assertEquals(InlayThemeMode.SYSTEM, InlayAppearance.themeMode)
    }
}
