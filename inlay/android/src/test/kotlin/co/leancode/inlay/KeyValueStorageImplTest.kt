package co.leancode.inlay

import co.leancode.inlay.storage.StorageEntry
import java.util.concurrent.CountDownLatch
import java.util.concurrent.atomic.AtomicReference
import kotlin.concurrent.thread
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

class KeyValueStorageImplTest {

    @After
    fun tearDown() {
        KeyValueStorageImpl.clearInternal()
    }

    @Test
    fun putAndGetRoundTrip() {
        KeyValueStorageImpl.putInternal(StorageEntry("a", "1"))
        assertEquals("1", KeyValueStorageImpl.getInternal("a")?.value)

        KeyValueStorageImpl.removeInternal("a")
        assertNull(KeyValueStorageImpl.getInternal("a"))
    }

    @Test
    fun getByPrefixReturnsOnlyMatchingEntries() {
        KeyValueStorageImpl.putAllInternal(
            listOf(
                StorageEntry("user/1/name", "a"),
                StorageEntry("user/1/email", "b"),
                StorageEntry("other/key", "c"),
            )
        )

        val entries = KeyValueStorageImpl.getByPrefixInternal("user/1/")
        assertEquals(2, entries.size)
    }

    /**
     * A multi-entry putAll must never be observed half-applied: a snapshot
     * read (getAll / getByPrefix) sees either the previous generation or the
     * new one for every key of the batch. Regression test for the previous
     * ConcurrentHashMap implementation, where batch writes were applied
     * key-by-key and readers could see torn snapshots.
     */
    @Test
    fun putAllIsAtomicWithRespectToSnapshotReads() {
        val keys = (0 until 8).map { "batch/k$it" }
        KeyValueStorageImpl.putAllInternal(keys.map { StorageEntry(it, "gen0") })

        val iterations = 3000
        val tornSnapshot = AtomicReference<List<String>?>(null)
        val start = CountDownLatch(1)

        val writer = thread {
            start.await()
            for (gen in 1..iterations) {
                KeyValueStorageImpl.putAllInternal(
                    keys.map { StorageEntry(it, "gen$gen") }
                )
            }
        }

        val reader = thread {
            start.await()
            while (writer.isAlive) {
                val snapshot = KeyValueStorageImpl
                    .getByPrefixInternal("batch/")
                    .map { it.value }
                if (snapshot.distinct().size > 1) {
                    tornSnapshot.compareAndSet(null, snapshot)
                    return@thread
                }
            }
        }

        start.countDown()
        writer.join()
        reader.join()

        assertNull(
            "Observed a half-applied batch write: ${tornSnapshot.get()}",
            tornSnapshot.get(),
        )
    }
}
