package dev.linwood.lw_sysapi

import android.app.Activity
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

  override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
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

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }
}
