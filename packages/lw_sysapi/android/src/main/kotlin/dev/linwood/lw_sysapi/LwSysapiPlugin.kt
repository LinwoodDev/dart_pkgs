package dev.linwood.lw_sysapi

import android.app.Activity
import android.content.ClipData
import android.content.ClipDescription
import android.content.ClipboardManager
import android.content.Context
import android.content.Intent
import android.net.Uri
import androidx.core.app.ActivityCompat.startActivityForResult
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry.ActivityResultListener
import java.io.IOException
import java.io.OutputStream


/** LwSysapiPlugin */
class LwSysapiPlugin: FlutterPlugin, MethodCallHandler, ActivityResultListener, ActivityAware {
  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
  private lateinit var channel : MethodChannel
  private val SAVE_REQUEST_CODE = 77777
  private var saveData: ByteArray? = null
  private var saveResult: MethodChannel.Result? = null
  private var act: Activity? = null
  private var context: Context? = null

  override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    context = flutterPluginBinding.applicationContext
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "linwood.dev/lw_sysapi")
    channel.setMethodCallHandler(this)
  }
  
  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
    act = binding.activity
    binding.addActivityResultListener(this)
  }

  override fun onDetachedFromActivityForConfigChanges() {
  }

  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
  }

  override fun onDetachedFromActivity() {
    act = null
  }

  override fun onMethodCall(call: MethodCall, result: Result) {
    if (call.method == "saveFile") {
      saveResult = result
      saveData = call.argument("data")
      saveFile(call.argument("mime")!!, call.argument("name")!!)
    } else if (call.method == "writeClipboard") {
      val mimeType = call.argument<String>("type")
      val data = call.argument<ByteArray>("data")
      if (mimeType == null || data == null) {
        result.success(false)
        return
      }
      result.success(writeClipboard(mimeType, data))
    } else if (call.method == "readClipboard") {
      val types = call.argument<List<String>>("types")
      result.success(readClipboard(types))
    } else {
      result.notImplemented()
    }
  }


  private fun saveFile(mime: String, fileName: String) {
    // when you create document, you need to add Intent.ACTION_CREATE_DOCUMENT
    val intent: Intent = Intent(Intent.ACTION_CREATE_DOCUMENT)

    // filter to only show openable items.
    intent.addCategory(Intent.CATEGORY_OPENABLE)

    // Create a file with the requested Mime type
    intent.setType(mime)
    intent.putExtra(Intent.EXTRA_TITLE, fileName)

    act?.let { startActivityForResult(it, intent, SAVE_REQUEST_CODE, null) }
  }

  @Override
  override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
    if (requestCode == SAVE_REQUEST_CODE) {
      when (resultCode) {
        Activity.RESULT_OK -> data?.data?.let { saveInFile(it) } //data.getData() is Uri
        Activity.RESULT_CANCELED -> saveResult?.success(false)
      }
      return true
    }
    return false
  }

  private fun saveInFile(uri: Uri) {
    try {
      val outputStream = act?.contentResolver?.openOutputStream(uri)
      if (outputStream == null) {
        saveResult?.success(false)
        return
      }
      outputStream.write(saveData)
      outputStream.flush()
      outputStream.close()
      saveResult?.success(true)
    } catch (e: IOException) {
      saveResult?.error("ERROR", "Unable to write", null)
    }
  }

  private fun writeClipboard(mimeType: String, data: ByteArray): Boolean {
    val currentContext = context ?: return false
    val manager = currentContext.getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
    if (mimeType == "text/plain") {
      manager.setPrimaryClip(ClipData.newPlainText("lw_sysapi", String(data, Charsets.UTF_8)))
      return true
    }
    if (mimeType == "text/html") {
      val html = String(data, Charsets.UTF_8)
      manager.setPrimaryClip(ClipData.newHtmlText("lw_sysapi", html, html))
      return true
    }
    val id = LwSysapiClipboardProvider.add(mimeType, data)
    val uri = Uri.Builder()
      .scheme("content")
      .authority("${currentContext.packageName}.lw_sysapi_clipboard")
      .appendPath(id)
      .build()
    val clip = ClipData(
      ClipDescription("lw_sysapi", arrayOf(mimeType)),
      ClipData.Item(uri),
    )
    manager.setPrimaryClip(clip)
    return true
  }

  private fun readClipboard(types: List<String>?): Map<String, Any>? {
    val currentContext = context ?: return null
    val manager = currentContext.getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
    val clip = manager.primaryClip ?: return null
    val description = manager.primaryClipDescription ?: return null
    val requestedTypes = types ?: listOf(
      "image/png",
      "image/jpeg",
      "image/gif",
      "image/webp",
      "image/tiff",
      "image/bmp",
      "application/pdf",
      "image/svg+xml",
      "text/plain",
      "text/html",
      "application/json",
      "text/csv",
      "application/rtf",
      "application/zip",
      "application/gzip",
      "application/x-tar",
      "application/x-7z-compressed",
      "image/x-icon",
      "image/heic",
      "image/heif",
      "image/avif",
      "audio/mpeg",
      "audio/wav",
      "video/mp4",
      "video/webm",
    )
    for (type in requestedTypes) {
      if (!hasClipboardMimeType(description, type)) continue
      for (i in 0 until clip.itemCount) {
        val item = clip.getItemAt(i)
        if (type == "text/plain") {
          item.coerceToText(currentContext)?.let {
            return mapOf("type" to type, "data" to it.toString().toByteArray(Charsets.UTF_8))
          }
        }
        if (type == "text/html") {
          item.htmlText?.let {
            return mapOf("type" to type, "data" to it.toByteArray(Charsets.UTF_8))
          }
        }
        val uri = item.uri ?: continue
        val uriType = currentContext.contentResolver.getType(uri)
        if (uriType != null && !ClipDescription.compareMimeTypes(uriType, type)) continue
        val data = currentContext.contentResolver.openInputStream(uri)?.use {
          it.readBytes()
        } ?: continue
        return mapOf("type" to type, "data" to data)
      }
    }
    return null
  }

  private fun hasClipboardMimeType(description: ClipDescription, mimeType: String): Boolean {
    if (description.hasMimeType(mimeType)) return true
    val slashIndex = mimeType.indexOf("/")
    if (slashIndex <= 0) return false
    return description.hasMimeType("${mimeType.substring(0, slashIndex)}/*")
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
    context = null
  }
}
