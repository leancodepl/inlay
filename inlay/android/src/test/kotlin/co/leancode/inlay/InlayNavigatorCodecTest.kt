package co.leancode.inlay

import co.leancode.inlay.navigator.PageSettings
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

/**
 * The encoded route string is the cross-platform wire format for
 * router-based navigation, so encode/decode must round-trip on every
 * platform. The special-character fixture mirrors the one in the Dart
 * `decodeInitialRoute` test.
 */
class InlayNavigatorCodecTest {

    @Test
    fun `path takes precedence over route id`() {
        val page = PageSettings("greeting", null, "/greeting/Marcin")

        assertEquals("/greeting/Marcin", InlayNavigator.encodePageSettings(page))
    }

    @Test
    fun `null params encode to the bare route id`() {
        assertEquals("counter", InlayNavigator.encodePageSettings(PageSettings("counter")))
    }

    @Test
    fun `map params round-trip including special characters`() {
        val params = mapOf("q" to "a&b=c d/ż", "plain" to "1")
        val encoded = InlayNavigator.encodePageSettings(PageSettings("page", params))

        val decoded = InlayNavigator.decodePageSettings(encoded)

        assertEquals("page", decoded.routeId)
        assertEquals(params, decoded.params)
    }

    @Test
    fun `pigeon-encoded list params are not urlencoded`() {
        val page = PageSettings("nativeAbout", listOf("1.0.0"))

        assertEquals("nativeAbout", InlayNavigator.encodePageSettings(page))
    }

    @Test
    fun `decode without a query yields null params`() {
        val decoded = InlayNavigator.decodePageSettings("counter")

        assertEquals("counter", decoded.routeId)
        assertNull(decoded.params)
    }
}
