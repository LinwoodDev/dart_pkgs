package dev.linwood.lw_file_system

import android.app.Activity
import android.content.ContentResolver
import android.content.Context
import android.content.Intent
import android.database.Cursor
import android.net.Uri
import android.provider.DocumentsContract
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry.ActivityResultListener
import java.io.File
import java.io.FileInputStream
import java.io.FileOutputStream
import java.io.IOException
import java.io.InputStream

class LwFileSystemPlugin : FlutterPlugin, MethodCallHandler, ActivityAware, ActivityResultListener {
    private lateinit var channel: MethodChannel
    private lateinit var context: Context
    private var activity: Activity? = null
    private var pendingDirectoryResult: Result? = null

    private val contentResolver: ContentResolver
        get() = context.contentResolver

    private data class SafRoot(
        val treeUri: Uri,
        val basePath: String
    )

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, CHANNEL)
        channel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        binding.addActivityResultListener(this)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
        binding.addActivityResultListener(this)
    }

    override fun onDetachedFromActivity() {
        activity = null
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode != PICK_DIRECTORY_REQUEST) return false

        val result = pendingDirectoryResult ?: return true
        pendingDirectoryResult = null

        val uri = data?.data

        if (resultCode != Activity.RESULT_OK || uri == null) {
            result.success(null)
            return true
        }

        val flags = data.flags and (
            Intent.FLAG_GRANT_READ_URI_PERMISSION or
                Intent.FLAG_GRANT_WRITE_URI_PERMISSION
            )

        try {
            contentResolver.takePersistableUriPermission(uri, flags)
        } catch (_: SecurityException) {
        }

        result.success(uri.toString())
        return true
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        try {
            when (call.method) {
                "pickDirectory" -> pickDirectory(result)

                "safCanRead" -> {
                    val root = call.safRoot()
                    result.success(resolveDocument(root.treeUri, root.basePath) != null)
                }

                "safExists" -> {
                    val root = call.safRoot()
                    result.success(resolveDocument(root.treeUri, call.fullPath()) != null)
                }

                "safCreateDirectory" -> {
                    val root = call.safRoot()
                    ensureDirectory(root.treeUri, call.fullPath())
                    result.success(null)
                }

                "safReadAsset" -> {
                    val root = call.safRoot()
                    val path = call.fullPath()
                    val uri = resolveDocument(root.treeUri, path)

                    result.success(
                        uri?.let {
                            entityMap(
                                treeUri = root.treeUri,
                                uri = it,
                                path = path,
                                readData = call.argument<Boolean>("readData") == true,
                                includeChildren = true,
                                virtualBasePath = root.basePath
                            )
                        }
                    )
                }

                "safListDirectory" -> {
                    val root = call.safRoot()

                    result.success(
                        listDirectory(
                            treeUri = root.treeUri,
                            path = call.fullPath(),
                            readData = call.argument<Boolean>("readData") == true,
                            virtualBasePath = root.basePath
                        )
                    )
                }

                "safWriteFile" -> {
                    val root = call.safRoot()

                    writeFile(
                        treeUri = root.treeUri,
                        path = call.fullPath(),
                        data = call.argument<ByteArray>("data") ?: ByteArray(0)
                    )

                    result.success(null)
                }

                "safDeleteAsset" -> {
                    val root = call.safRoot()

                    resolveDocument(root.treeUri, call.fullPath())?.let {
                        DocumentsContract.deleteDocument(contentResolver, it)
                    }

                    result.success(null)
                }

                "safReadAbsolute" -> {
                    val rawUri = Uri.parse(
                        call.argument<String>("uri")
                            ?: throw IllegalArgumentException("Missing uri")
                    )

                    val root = parseSafRoot(rawUri)
                    val relativePath = call.argument<String>("path")

                    val inputUri = if (relativePath != null) {
                        resolveDocument(root.treeUri, joinPaths(root.basePath, relativePath))
                            ?: throw IOException("Could not resolve document: $relativePath")
                    } else if (root.basePath.isNotEmpty()) {
                        resolveDocument(root.treeUri, root.basePath)
                            ?: throw IOException("Could not resolve document: ${root.basePath}")
                    } else {
                        rawUri
                    }

                    contentResolver.openInputStream(inputUri).use { inputStream ->
                        result.success(inputStream?.readBytes())
                    }
                }

                "safResolveUri" -> {
                    val root = call.safRoot()
                    val uri = resolveDocument(root.treeUri, call.fullPath())
                    result.success(uri?.toString())
                }

                "importPathToSaf" -> {
                    val source = File(
                        call.argument<String>("sourcePath")
                            ?: throw IllegalArgumentException("Missing sourcePath")
                    )

                    if (!source.exists()) {
                        result.success(false)
                        return
                    }

                    val root = call.safRoot()
                    copyPathToSaf(source, root.treeUri, root.basePath)
                    deleteFileOrDirectory(source)

                    result.success(true)
                }

                "exportSafToPath" -> {
                    val root = call.safRoot()

                    copySafToPath(
                        treeUri = root.treeUri,
                        sourcePath = root.basePath,
                        target = File(
                            call.argument<String>("targetPath")
                                ?: throw IllegalArgumentException("Missing targetPath")
                        )
                    )

                    result.success(true)
                }

                "copySafToSaf" -> {
                    val sourceRoot = parseSafRoot(
                        Uri.parse(
                            call.argument<String>("sourceRootUri")
                                ?: throw IllegalArgumentException("Missing sourceRootUri")
                        )
                    )

                    val targetRoot = parseSafRoot(
                        Uri.parse(
                            call.argument<String>("targetRootUri")
                                ?: throw IllegalArgumentException("Missing targetRootUri")
                        )
                    )

                    copySafToSaf(
                        sourceTreeUri = sourceRoot.treeUri,
                        sourcePath = sourceRoot.basePath,
                        targetTreeUri = targetRoot.treeUri,
                        targetPath = targetRoot.basePath
                    )

                    result.success(true)
                }

                else -> result.notImplemented()
            }
        } catch (error: Exception) {
            result.error("saf_error", error.message, null)
        }
    }

    private fun MethodCall.safRoot(): SafRoot {
        val rawUri = Uri.parse(
            argument<String>("rootUri")
                ?: throw IllegalArgumentException("Missing rootUri")
        )

        return parseSafRoot(rawUri)
    }

    private fun MethodCall.fullPath(): String {
        val root = safRoot()
        val requestedPath = normalizePath(argument<String>("path"))
        return joinPaths(root.basePath, requestedPath)
    }

    private fun pickDirectory(result: Result) {
        val currentActivity = activity

        if (currentActivity == null) {
            result.error("no_activity", "An activity is required to pick a directory.", null)
            return
        }

        if (pendingDirectoryResult != null) {
            result.error("already_active", "A directory picker is already active.", null)
            return
        }

        pendingDirectoryResult = result

        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT_TREE).apply {
            addFlags(
                Intent.FLAG_GRANT_READ_URI_PERMISSION or
                    Intent.FLAG_GRANT_WRITE_URI_PERMISSION or
                    Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION or
                    Intent.FLAG_GRANT_PREFIX_URI_PERMISSION
            )
        }

        currentActivity.startActivityForResult(intent, PICK_DIRECTORY_REQUEST)
    }

    private fun parseSafRoot(uri: Uri): SafRoot {
        val encodedPath = uri.encodedPath ?: return SafRoot(uri, "")

        val encodedSegments = encodedPath
            .split("/")
            .filter { it.isNotEmpty() }

        val treeIndex = encodedSegments.indexOf("tree")

        if (treeIndex < 0 || treeIndex + 1 >= encodedSegments.size) {
            return SafRoot(uri, "")
        }

        val encodedTreeId = encodedSegments[treeIndex + 1]

        val realTreeUri = uri.buildUpon()
            .encodedPath("/tree/$encodedTreeId")
            .encodedQuery(null)
            .fragment(null)
            .build()

        val extraPath = encodedSegments
            .drop(treeIndex + 2)
            .joinToString("/") { Uri.decode(it) }

        return SafRoot(
            treeUri = realTreeUri,
            basePath = normalizePath(extraPath)
        )
    }

    private fun normalizePath(path: String?): String {
        if (path == null || path == "/" || path == ".") return ""

        var normalized = path.replace('\\', '/')

        while (normalized.startsWith("/")) {
            normalized = normalized.substring(1)
        }

        return normalized
            .split("/")
            .filter { it.isNotEmpty() && it != "." }
            .joinToString("/")
    }

    private fun joinPaths(first: String, second: String): String {
        val a = normalizePath(first)
        val b = normalizePath(second)

        return when {
            a.isEmpty() -> b
            b.isEmpty() -> a
            else -> "$a/$b"
        }
    }

    private fun stripBasePath(basePath: String, fullPath: String): String {
        val base = normalizePath(basePath)
        val path = normalizePath(fullPath)

        if (base.isEmpty()) return path
        if (path == base) return ""
        if (path.startsWith("$base/")) return path.substring(base.length + 1)

        return path
    }

    private fun treeDocumentUri(treeUri: Uri): Uri =
        DocumentsContract.buildDocumentUriUsingTree(
            treeUri,
            DocumentsContract.getTreeDocumentId(treeUri)
        )

    private fun findChild(parentUri: Uri, name: String): Uri? {
        val childrenUri = DocumentsContract.buildChildDocumentsUriUsingTree(
            parentUri,
            DocumentsContract.getDocumentId(parentUri)
        )

        query(
            childrenUri,
            arrayOf(
                DocumentsContract.Document.COLUMN_DOCUMENT_ID,
                DocumentsContract.Document.COLUMN_DISPLAY_NAME
            )
        )?.use { cursor ->
            while (cursor.moveToNext()) {
                if (name == cursor.getString(1)) {
                    return DocumentsContract.buildDocumentUriUsingTree(
                        parentUri,
                        cursor.getString(0)
                    )
                }
            }
        }

        return null
    }

    private fun resolveDocument(treeUri: Uri, path: String): Uri? {
        var current: Uri? = treeDocumentUri(treeUri)
        val normalized = normalizePath(path)

        if (normalized.isEmpty()) return current

        for (part in normalized.split("/")) {
            if (part.isEmpty()) continue

            current = current?.let { findChild(it, part) } ?: return null
        }

        return current
    }

    private fun ensureDirectory(treeUri: Uri, path: String): Uri {
        var current = treeDocumentUri(treeUri)
        val normalized = normalizePath(path)

        if (normalized.isEmpty()) return current

        for (part in normalized.split("/")) {
            val child = findChild(current, part)
                ?: DocumentsContract.createDocument(
                    contentResolver,
                    current,
                    DocumentsContract.Document.MIME_TYPE_DIR,
                    part
                )
                ?: throw IOException("Could not create directory: $part")

            if (!isDirectory(child)) {
                throw IOException("Path segment is not a directory: $part")
            }

            current = child
        }

        return current
    }

    private fun parentPath(path: String): String {
        val normalized = normalizePath(path)
        val index = normalized.lastIndexOf("/")
        return if (index < 0) "" else normalized.substring(0, index)
    }

    private fun fileName(path: String): String {
        val normalized = normalizePath(path)
        val index = normalized.lastIndexOf("/")
        return if (index < 0) normalized else normalized.substring(index + 1)
    }

    private fun entityMap(
        treeUri: Uri,
        uri: Uri,
        path: String,
        readData: Boolean,
        includeChildren: Boolean,
        virtualBasePath: String = ""
    ): Map<String, Any?> {
        val map = HashMap<String, Any?>()

        map["path"] = stripBasePath(virtualBasePath, path)
        map["isDirectory"] = false

        query(
            uri,
            arrayOf(
                DocumentsContract.Document.COLUMN_MIME_TYPE,
                DocumentsContract.Document.COLUMN_SIZE,
                DocumentsContract.Document.COLUMN_LAST_MODIFIED
            )
        )?.use { cursor ->
            if (cursor.moveToFirst()) {
                val mime = cursor.getString(0)

                map["isDirectory"] = DocumentsContract.Document.MIME_TYPE_DIR == mime

                if (!cursor.isNull(1)) {
                    map["size"] = cursor.getLong(1)
                }

                if (!cursor.isNull(2)) {
                    map["lastModified"] = cursor.getLong(2)
                }
            }
        }

        if (map["isDirectory"] == true) {
            if (includeChildren) {
                map["assets"] = listDirectory(
                    treeUri = treeUri,
                    path = path,
                    readData = readData,
                    virtualBasePath = virtualBasePath
                )
            }
        } else if (readData) {
            contentResolver.openInputStream(uri).use { inputStream ->
                if (inputStream != null) {
                    map["data"] = inputStream.readBytes()
                }
            }
        }

        return map
    }

    private fun listDirectory(
        treeUri: Uri,
        path: String,
        readData: Boolean,
        virtualBasePath: String = ""
    ): List<Map<String, Any?>> {
        val directory = resolveDocument(treeUri, path) ?: return emptyList()
        val normalizedPath = normalizePath(path)
        val files = ArrayList<Map<String, Any?>>()

        val childrenUri = DocumentsContract.buildChildDocumentsUriUsingTree(
            directory,
            DocumentsContract.getDocumentId(directory)
        )

        query(
            childrenUri,
            arrayOf(
                DocumentsContract.Document.COLUMN_DOCUMENT_ID,
                DocumentsContract.Document.COLUMN_DISPLAY_NAME
            )
        )?.use { cursor ->
            while (cursor.moveToNext()) {
                val docId = cursor.getString(0)
                val name = cursor.getString(1)

                val childUri = DocumentsContract.buildDocumentUriUsingTree(
                    treeUri,
                    docId
                )

                val childPath = if (normalizedPath.isEmpty()) {
                    name
                } else {
                    "$normalizedPath/$name"
                }

                files.add(
                    entityMap(
                        treeUri = treeUri,
                        uri = childUri,
                        path = childPath,
                        readData = readData,
                        includeChildren = false,
                        virtualBasePath = virtualBasePath
                    )
                )
            }
        }

        return files
    }

    private fun writeFile(treeUri: Uri, path: String, data: ByteArray) {
        data.inputStream().use {
            writeStreamToFile(treeUri, path, it)
        }
    }

    private fun writeStreamToFile(treeUri: Uri, path: String, inputStream: InputStream) {
        val parent = ensureDirectory(treeUri, parentPath(path))
        val name = fileName(path)

        if (name.isEmpty()) {
            throw IOException("Missing file name")
        }

        var file = findChild(parent, name)

        if (file == null) {
            file = DocumentsContract.createDocument(
                contentResolver,
                parent,
                "application/octet-stream",
                name
            )
        }

        if (file == null) {
            throw IOException("Could not create file: $name")
        }

        if (isDirectory(file)) {
            throw IOException("Target is a directory: $name")
        }

        contentResolver.openOutputStream(file, "wt").use { outputStream ->
            if (outputStream == null) {
                throw IOException("Could not open output stream")
            }

            inputStream.copyTo(outputStream)
        }
    }

    private fun copyPathToSaf(source: File, treeUri: Uri, targetPath: String) {
        if (source.isDirectory) {
            ensureDirectory(treeUri, targetPath)

            source.listFiles()?.forEach { child ->
                val childPath = if (normalizePath(targetPath).isEmpty()) {
                    child.name
                } else {
                    "${normalizePath(targetPath)}/${child.name}"
                }

                copyPathToSaf(child, treeUri, childPath)
            }
        } else {
            FileInputStream(source).use {
                writeStreamToFile(treeUri, targetPath, it)
            }
        }
    }

    private fun copySafToPath(treeUri: Uri, sourcePath: String, target: File) {
        val source = resolveDocument(treeUri, sourcePath) ?: return

        if (isDirectory(source)) {
            if (!target.exists() && !target.mkdirs()) {
                throw IOException("Could not create directory: $target")
            }

            listDirectory(
                treeUri = treeUri,
                path = sourcePath,
                readData = false
            ).forEach { child ->
                val childPath = child["path"] as String

                copySafToPath(
                    treeUri = treeUri,
                    sourcePath = if (sourcePath.isEmpty()) {
                        childPath
                    } else {
                        joinPaths(sourcePath, fileName(childPath))
                    },
                    target = File(target, fileName(childPath))
                )
            }
        } else {
            val parent = target.parentFile

            if (parent != null && !parent.exists() && !parent.mkdirs()) {
                throw IOException("Could not create directory: $parent")
            }

            contentResolver.openInputStream(source).use { inputStream ->
                FileOutputStream(target).use { outputStream ->
                    if (inputStream == null) {
                        throw IOException("Could not open input stream")
                    }

                    inputStream.copyTo(outputStream)
                }
            }
        }
    }

    private fun copySafToSaf(
        sourceTreeUri: Uri,
        sourcePath: String,
        targetTreeUri: Uri,
        targetPath: String
    ) {
        val source = resolveDocument(sourceTreeUri, sourcePath) ?: return

        if (isDirectory(source)) {
            ensureDirectory(targetTreeUri, targetPath)

            listDirectory(
                treeUri = sourceTreeUri,
                path = sourcePath,
                readData = false
            ).forEach { child ->
                val childPath = child["path"] as String

                val fullChildSourcePath = if (sourcePath.isEmpty()) {
                    childPath
                } else {
                    joinPaths(sourcePath, fileName(childPath))
                }

                val childTargetPath = if (normalizePath(targetPath).isEmpty()) {
                    fileName(childPath)
                } else {
                    "${normalizePath(targetPath)}/${fileName(childPath)}"
                }

                copySafToSaf(
                    sourceTreeUri = sourceTreeUri,
                    sourcePath = fullChildSourcePath,
                    targetTreeUri = targetTreeUri,
                    targetPath = childTargetPath
                )
            }
        } else {
            contentResolver.openInputStream(source).use { inputStream ->
                if (inputStream == null) {
                    throw IOException("Could not open input stream")
                }

                writeStreamToFile(targetTreeUri, targetPath, inputStream)
            }
        }
    }

    private fun deleteFileOrDirectory(file: File) {
        if (file.isDirectory) {
            file.listFiles()?.forEach {
                deleteFileOrDirectory(it)
            }
        }

        file.delete()
    }

    private fun isDirectory(uri: Uri): Boolean {
        query(
            uri,
            arrayOf(DocumentsContract.Document.COLUMN_MIME_TYPE)
        )?.use { cursor ->
            return cursor.moveToFirst() &&
                cursor.getString(0) == DocumentsContract.Document.MIME_TYPE_DIR
        }

        return false
    }

    private fun query(uri: Uri, projection: Array<String>): Cursor? =
        contentResolver.query(uri, projection, null, null, null)

    companion object {
        private const val CHANNEL = "linwood.dev/lw_file_system/saf"
        private const val PICK_DIRECTORY_REQUEST = 4204
    }
}