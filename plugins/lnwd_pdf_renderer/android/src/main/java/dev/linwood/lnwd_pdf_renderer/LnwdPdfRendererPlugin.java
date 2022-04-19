package dev.linwood.lnwd_pdf_renderer;

import android.graphics.Bitmap;
import android.graphics.pdf.PdfRenderer;
import android.os.ParcelFileDescriptor;

import androidx.annotation.NonNull;

import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.FileDescriptor;
import java.io.FileOutputStream;
import java.io.FileWriter;
import java.io.IOException;
import java.io.OutputStream;
import java.io.OutputStreamWriter;
import java.nio.file.Files;
import java.util.ArrayList;
import java.util.List;
import java.util.stream.IntStream;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;

/**
 * LnwdPdfRendererPlugin
 */
public class LnwdPdfRendererPlugin implements FlutterPlugin, MethodCallHandler {
    /// The MethodChannel that will the communication between Flutter and native Android
    ///
    /// This local reference serves to register the plugin with the Flutter Engine and unregister it
    /// when the Flutter Engine is detached from the Activity
    private MethodChannel channel;

    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
        channel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), "lnwd_pdf_renderer");
        channel.setMethodCallHandler(this);
    }

    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
        if (call.method.equals("render")) {
            try {
                result.success(render(call.argument("data")));
            } catch (IOException e) {
                result.error("IOException", e.getMessage(), e.getStackTrace());
            }
        } else {
            result.notImplemented();
        }
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        channel.setMethodCallHandler(null);
    }

    private ParcelFileDescriptor constructDescriptorFromData(byte[] data) throws IOException {
        File file = File.createTempFile("temp", ".pdf");
        file.deleteOnExit();
        FileOutputStream outputStream = new FileOutputStream(file);
        outputStream.write(data);
        return ParcelFileDescriptor.open(file, ParcelFileDescriptor.MODE_READ_ONLY);
    }

    public RenderedPdfDocument render(byte[] data) throws IOException {
        PdfRenderer renderer = new PdfRenderer(constructDescriptorFromData(data));
        List<RenderedPdfPage> pages = new ArrayList<>();
        for (int i = 0; i < renderer.getPageCount(); i++) {
            PdfRenderer.Page current = renderer.openPage(i);
            Bitmap bitmap = Bitmap.createBitmap(current.getWidth(), current.getHeight(), Bitmap.Config.ARGB_8888);
            current.render(bitmap, null, null, PdfRenderer.Page.RENDER_MODE_FOR_DISPLAY);
            // Compress and save as byte array
            ByteArrayOutputStream outputStream = new ByteArrayOutputStream();
            bitmap.compress(Bitmap.CompressFormat.PNG, 100, outputStream);
            byte[] byteArray = outputStream.toByteArray();
            pages.add(new RenderedPdfPage(byteArray, current.getWidth(), current.getHeight()));
        }
        return new RenderedPdfDocument(pages.toArray(new RenderedPdfPage[0]));
    }


}
