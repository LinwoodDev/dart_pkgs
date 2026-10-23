package dev.linwood.lw_sysapi

import java.io.ByteArrayOutputStream
import java.io.IOException
import java.io.OutputStream
import java.io.PipedInputStream
import java.io.PipedOutputStream
import java.util.concurrent.atomic.AtomicReference
import org.junit.jupiter.api.Test
import kotlin.test.assertContentEquals
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue

internal class LwSysapiClipboardProviderTest {
  @Test
  fun clipboardDataIsWrittenInFullAndStreamIsClosed() {
    var closed = false
    val output = object : ByteArrayOutputStream() {
      override fun close() {
        closed = true
        super.close()
      }
    }
    val data = ByteArray(1024 * 1024) { (it % 256).toByte() }

    writeClipboardStream(output, data)

    assertContentEquals(data, output.toByteArray())
    assertTrue(closed)
  }

  @Test
  fun readerDisconnectDoesNotEscapeWriterThread() {
    val input = PipedInputStream()
    var closed = false
    val output = object : PipedOutputStream(input) {
      override fun close() {
        closed = true
        super.close()
      }
    }
    // Clipboard previews can open a URI then close it without reading its data.
    input.close()
    val uncaught = AtomicReference<Throwable?>()
    val writer = Thread { writeClipboardStream(output, ByteArray(1024 * 1024)) }
    writer.uncaughtExceptionHandler = Thread.UncaughtExceptionHandler { _, error ->
      uncaught.set(error)
    }

    writer.start()
    writer.join(5000)

    assertFalse(writer.isAlive, "Clipboard writer must stop after the reader disconnects")
    assertNull(uncaught.get(), "A broken clipboard pipe must not crash the app")
    assertTrue(closed)
  }

  @Test
  fun streamCloseFailureDoesNotEscapeWriterThread() {
    val output = object : OutputStream() {
      override fun write(value: Int) {}
      override fun close() {
        throw IOException("Reader disconnected during close")
      }
    }

    writeClipboardStream(output, byteArrayOf(1, 2, 3))
  }
}
