package dev.linwood.lw_sysapi

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Handler
import android.os.Looper
import android.provider.DocumentsContract
import android.provider.OpenableColumns
import android.webkit.MimeTypeMap
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executors

internal class LwSysapiFileDialogs(private val context: Context) {
  var activity: Activity? = null
  private var pending: MethodChannel.Result? = null
  private var operation = ""
  private var bytes: ByteArray? = null
  private var extension = ""
  private val main = Handler(Looper.getMainLooper())
  private val worker = Executors.newSingleThreadExecutor()
  private val requestCode = 4777
  private var generation = 0

  fun handle(call: MethodCall, result: MethodChannel.Result): Boolean {
    if (call.method == "readFile") {
      val path = call.argument<String>("path")
      if (path == null) {
        result.error("invalid_path", "Missing document URI", null)
      } else {
        worker.execute {
          try {
            val data = context.contentResolver.openInputStream(Uri.parse(path))?.use { it.readBytes() }
              ?: throw java.io.IOException("Unable to open the document")
            main.post { result.success(data) }
          } catch (error: Exception) {
            main.post { result.error("read_failed", error.message, path) }
          }
        }
      }
      return true
    }
    if (call.method !in listOf("pickFiles", "pickDirectory", "saveFile")) return false
    if (pending != null) {
      result.error("dialog_in_progress", "A file dialog is already open", null)
      return true
    }
    val host = activity
    if (host == null) {
      result.error("no_activity", "No activity is available for a file dialog", null)
      return true
    }
    val save = call.method == "saveFile"
    val folder = call.method == "pickDirectory"
    val intent = Intent(when {
      save -> Intent.ACTION_CREATE_DOCUMENT
      folder -> Intent.ACTION_OPEN_DOCUMENT_TREE
      else -> Intent.ACTION_OPEN_DOCUMENT
    })
    intent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION)
    if (folder || save) intent.addFlags(Intent.FLAG_GRANT_WRITE_URI_PERMISSION)
    if (folder) intent.addFlags(Intent.FLAG_GRANT_PREFIX_URI_PERMISSION)
    else {
      intent.addCategory(Intent.CATEGORY_OPENABLE)
      if (save) {
        extension = call.argument<String>("extension") ?: ""
        bytes = call.argument<ByteArray>("data")
        if (bytes == null) {
          result.error("invalid_arguments", "Save data is required", null)
          return true
        }
        intent.type = call.argument<String>("mime") ?: "application/octet-stream"
        intent.putExtra(Intent.EXTRA_TITLE, call.argument<String>("name"))
      } else {
        intent.putExtra(Intent.EXTRA_ALLOW_MULTIPLE, call.argument<Boolean>("multiple") ?: false)
        val extensions = call.argument<List<String>>("extensions") ?: emptyList()
        val types = extensions.map { MimeTypeMap.getSingleton().getMimeTypeFromExtension(it.lowercase()) }
        // SAF has MIME filters only. Unknown formats such as .bfly must remain selectable.
        if (types.isNotEmpty() && types.none { it == null }) {
          val known = types.filterNotNull().distinct()
          intent.type = known.singleOrNull() ?: "*/*"
          if (known.size > 1) intent.putExtra(Intent.EXTRA_MIME_TYPES, known.toTypedArray())
        } else intent.type = "*/*"
      }
    }
    pending = result
    generation++
    operation = call.method
    try {
      host.startActivityForResult(intent, requestCode)
    } catch (error: Exception) {
      finishError("dialog_failed", error.message)
    }
    return true
  }

  fun onActivityResult(code: Int, status: Int, data: Intent?): Boolean {
    if (code != requestCode) return false
    if (pending == null) return true
    if (status != Activity.RESULT_OK || data == null) {
      finish(if (operation == "saveFile") false else null)
      return true
    }
    val uris = if (data.clipData != null) {
      (0 until data.clipData!!.itemCount).map { data.clipData!!.getItemAt(it).uri }
    } else listOfNotNull(data.data)
    val resolver = context.contentResolver
    val ticket = generation
    for (uri in uris) {
      val flags = data.flags and (Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION)
      if (flags != 0) try { resolver.takePersistableUriPermission(uri, flags) } catch (_: SecurityException) {
        // Some providers grant access only for the current activity session.
      }
    }
    when (operation) {
      "pickDirectory" -> finish(uris.firstOrNull()?.toString())
      "pickFiles" -> {
        worker.execute {
          try {
            val files = uris.map { uri -> mapOf("path" to uri.toString(), "name" to displayName(uri)) }
            main.post { if (ticket == generation) finish(files) }
          } catch (error: Exception) {
            main.post { if (ticket == generation) finishError("read_failed", error.message) }
          }
        }
      }
      "saveFile" -> {
        val selected = uris.firstOrNull()
        val content = bytes
        val suffix = if (extension.isEmpty()) "" else "." + extension
        if (selected == null || content == null) {
          finish(false)
          return true
        }
        worker.execute {
          try {
            var uri = selected
            val name = displayName(uri)
            if (!name.endsWith(suffix, ignoreCase = true)) {
              uri = DocumentsContract.renameDocument(resolver, uri, name + suffix)
                ?: throw java.io.IOException("The document provider cannot preserve the requested extension")
            }
            if (!displayName(uri).endsWith(suffix, ignoreCase = true)) {
              throw java.io.IOException("The document provider changed the requested extension")
            }
            resolver.openOutputStream(uri, "wt")?.use { it.write(content) }
              ?: throw java.io.IOException("Unable to write the document")
            main.post { if (ticket == generation) finish(true) }
          } catch (error: Exception) {
            main.post { if (ticket == generation) finishError("save_failed", error.message) }
          }
        }
      }
    }
    return true
  }

  private fun displayName(uri: Uri): String {
    context.contentResolver.query(uri, arrayOf(OpenableColumns.DISPLAY_NAME), null, null, null)?.use {
      if (it.moveToFirst()) {
        val index = it.getColumnIndex(OpenableColumns.DISPLAY_NAME)
        if (index >= 0 && !it.isNull(index)) return it.getString(index)
      }
    }
    return uri.lastPathSegment ?: "document"
  }

  fun detach() {
    generation++
    activity = null
    if (pending != null) finishError("activity_detached", "The activity closed before the file dialog completed")
  }

  fun close() {
    detach()
    worker.shutdownNow()
  }

  private fun finish(value: Any?) {
    val callback = pending
    pending = null
    bytes = null
    operation = ""
    callback?.success(value)
  }

  private fun finishError(code: String, message: String?) {
    val callback = pending
    pending = null
    bytes = null
    operation = ""
    callback?.error(code, message, null)
  }
}
