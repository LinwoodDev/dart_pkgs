package dev.linwood.lw_sysapi

import android.app.Activity
import android.content.Context
import android.net.Uri
import android.os.Handler
import android.os.Looper
import android.provider.OpenableColumns
import android.view.DragEvent
import android.view.View
import android.view.ViewGroup
import io.flutter.embedding.android.FlutterView
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executors

internal class LwSysapiDropTarget(private val context: Context, private val channel: MethodChannel) {
  private var activity: Activity? = null
  private var view: View? = null
  private var enabled = false
  private var disposed = false
  private val main = Handler(Looper.getMainLooper())
  private val worker = Executors.newSingleThreadExecutor()

  init {
    channel.setMethodCallHandler { call, result ->
      if (call.method == "setEnabled") {
        enabled = call.arguments as? Boolean ?: false
        result.success(true)
      } else {
        result.notImplemented()
      }
    }
  }

  fun attach(activity: Activity?) {
    view?.setOnDragListener(null)
    view = null
    this.activity = activity
    activity?.window?.decorView?.post {
      if (disposed || this.activity !== activity) return@post
      view = findFlutterView(activity.window.decorView)
      view?.setOnDragListener { _, event -> onDrag(event) }
    }
  }

  private fun findFlutterView(view: View): FlutterView? {
    if (view is FlutterView) return view
    if (view is ViewGroup) {
      for (i in 0 until view.childCount) findFlutterView(view.getChildAt(i))?.let { return it }
    }
    return null
  }

  private fun send(phase: String, x: Float, y: Float, items: List<Map<String, Any>> = emptyList()) {
    if (disposed) return
    val density = context.resources.displayMetrics.density.toDouble()
    channel.invokeMethod("dropEvent", mapOf("phase" to phase, "x" to x / density, "y" to y / density, "items" to items))
  }

  private fun readUri(uri: Uri): Map<String, Any>? {
    if (uri.scheme == "http" || uri.scheme == "https" || uri.scheme == "data") {
      return mapOf("uri" to uri.toString())
    }
    if (uri.scheme != "content" && uri.scheme != "file") return null
    return try {
      var name = uri.lastPathSegment ?: ""
      context.contentResolver.query(uri, arrayOf(OpenableColumns.DISPLAY_NAME), null, null, null)?.use { cursor ->
        if (cursor.moveToFirst()) {
          val column = cursor.getColumnIndex(OpenableColumns.DISPLAY_NAME)
          if (column >= 0) name = cursor.getString(column) ?: name
        }
      }
      val type = context.contentResolver.getType(uri) ?: "application/octet-stream"
      val bytes = context.contentResolver.openInputStream(uri)?.use { it.readBytes() } ?: return null
      mapOf("name" to name, "contents" to listOf(mapOf("type" to type, "data" to bytes)))
    } catch (_: Exception) {
      // Providers may reject metadata queries or revoke access during a drag.
      null
    }
  }

  private fun onDrag(event: DragEvent): Boolean {
    when (event.action) {
      DragEvent.ACTION_DRAG_STARTED -> return enabled
      DragEvent.ACTION_DRAG_ENTERED, DragEvent.ACTION_DRAG_LOCATION -> {
        if (enabled) send("hover", event.x, event.y)
      }
      DragEvent.ACTION_DRAG_EXITED, DragEvent.ACTION_DRAG_ENDED -> send("exit", 0f, 0f)
      DragEvent.ACTION_DROP -> {
        if (!enabled) return false
        val clip = event.clipData ?: return false
        val permissions = activity?.requestDragAndDropPermissions(event)
        val x = event.x
        val y = event.y
        worker.execute {
          try {
            val items = (0 until clip.itemCount).mapNotNull { index ->
              val item = clip.getItemAt(index)
              if (item.uri != null) {
                readUri(item.uri)
              } else {
                val contents = mutableListOf<Map<String, Any>>()
                item.htmlText?.let { contents.add(mapOf("type" to "text/html", "data" to it.toByteArray(Charsets.UTF_8))) }
                item.text?.let { contents.add(mapOf("type" to "text/plain", "data" to it.toString().toByteArray(Charsets.UTF_8))) }
                if (contents.isEmpty()) null else mapOf("contents" to contents)
              }
            }
            main.post { send("drop", x, y, items) }
          } finally {
            permissions?.release()
          }
        }
      }
    }
    return true
  }

  fun dispose() {
    disposed = true
    attach(null)
    channel.setMethodCallHandler(null)
    worker.shutdown()
  }
}
