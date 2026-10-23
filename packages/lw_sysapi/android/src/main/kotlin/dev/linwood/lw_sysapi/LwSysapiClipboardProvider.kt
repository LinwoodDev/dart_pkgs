package dev.linwood.lw_sysapi

import android.content.ContentProvider
import android.content.ContentValues
import android.database.Cursor
import android.net.Uri
import android.os.ParcelFileDescriptor
import java.io.FileNotFoundException
import java.io.IOException
import java.io.OutputStream
import java.util.UUID

class LwSysapiClipboardProvider : ContentProvider() {
  data class ClipboardEntry(val mimeType: String, val data: ByteArray)

  companion object {
    private val entries = mutableMapOf<String, ClipboardEntry>()

    fun add(mimeType: String, data: ByteArray): String {
      val id = UUID.randomUUID().toString()
      entries[id] = ClipboardEntry(mimeType, data)
      return id
    }

    fun get(uri: Uri): ClipboardEntry? = entries[uri.lastPathSegment]
  }

  override fun onCreate(): Boolean = true

  override fun getType(uri: Uri): String? = get(uri)?.mimeType

  override fun getStreamTypes(uri: Uri, mimeTypeFilter: String): Array<String>? {
    val mimeType = get(uri)?.mimeType ?: return null
    return if (android.content.ClipDescription.compareMimeTypes(mimeType, mimeTypeFilter)) {
      arrayOf(mimeType)
    } else {
      null
    }
  }

  override fun openFile(uri: Uri, mode: String): ParcelFileDescriptor {
    if (!mode.contains("r")) throw FileNotFoundException(uri.toString())
    val entry = get(uri) ?: throw FileNotFoundException(uri.toString())
    val pipe = ParcelFileDescriptor.createPipe()
    Thread {
      writeClipboardStream(ParcelFileDescriptor.AutoCloseOutputStream(pipe[1]), entry.data)
    }.start()
    return pipe[0]
  }

  override fun query(
    uri: Uri,
    projection: Array<out String>?,
    selection: String?,
    selectionArgs: Array<out String>?,
    sortOrder: String?,
  ): Cursor? = null

  override fun insert(uri: Uri, values: ContentValues?): Uri? = null

  override fun delete(uri: Uri, selection: String?, selectionArgs: Array<out String>?): Int = 0

  override fun update(
    uri: Uri,
    values: ContentValues?,
    selection: String?,
    selectionArgs: Array<out String>?,
  ): Int = 0
}

// Clipboard previews may close their end of the pipe before consuming all the data.
// An uncaught IOException here would terminate the app from the writer thread.
internal fun writeClipboardStream(output: OutputStream, data: ByteArray) {
  try {
    output.use { it.write(data) }
  } catch (_: IOException) {
    // The reader disconnected; the stream is closed by use even when writing fails.
  }
}
