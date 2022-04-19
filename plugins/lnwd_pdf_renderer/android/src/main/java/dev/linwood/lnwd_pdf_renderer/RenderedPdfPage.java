package dev.linwood.lnwd_pdf_renderer;

public class RenderedPdfPage {
    final byte[] data;
    final int width, height;

    public RenderedPdfPage(byte[] data, int width, int height) {
        this.data = data;
        this.width = width;
        this.height = height;
    }
}
