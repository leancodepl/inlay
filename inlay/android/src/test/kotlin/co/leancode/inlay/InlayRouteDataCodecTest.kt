package co.leancode.inlay

import org.junit.Assert.assertArrayEquals
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

/**
 * Route data is persisted in Intent extras / Fragment arguments so a
 * container restored after process death still gets its full typed route.
 * The typed positional params go through the pigeon codec on the way in and
 * out, so the round trip must preserve every wire type.
 */
class InlayRouteDataCodecTest {

    @Test
    fun `params round-trip through the codec`() {
        val params = listOf(
            "id-1",
            42,
            1L shl 40,
            2.5,
            true,
            null,
            listOf("nested", 7),
            mapOf("k" to "v"),
            byteArrayOf(1, 2, 3),
        )

        val decoded = InlayNavigator.decodeRouteParams(
            InlayNavigator.encodeRouteParams(params),
        ) as List<*>

        assertEquals("id-1", decoded[0])
        assertEquals(42, decoded[1])
        assertEquals(1L shl 40, decoded[2])
        assertEquals(2.5, decoded[3])
        assertEquals(true, decoded[4])
        assertNull(decoded[5])
        assertEquals(listOf("nested", 7), decoded[6])
        assertEquals(mapOf("k" to "v"), decoded[7])
        assertArrayEquals(byteArrayOf(1, 2, 3), decoded[8] as ByteArray)
    }

    @Test
    fun `missing params stay null`() {
        assertNull(InlayNavigator.encodeRouteParams(null))
        assertNull(InlayNavigator.decodeRouteParams(null))
    }
}
