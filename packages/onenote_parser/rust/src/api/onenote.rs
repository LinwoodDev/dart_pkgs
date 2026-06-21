use super::{
    OneNoteColor, OneNoteContent, OneNoteEmbeddedFile, OneNoteImage, OneNoteInk,
    OneNoteInkBoundingBox, OneNoteInkPoint, OneNoteInkStroke, OneNoteNotebook, OneNoteOutline,
    OneNoteOutlineElement, OneNoteOutlineGroup, OneNoteOutlineItem, OneNotePage,
    OneNotePageContent, OneNotePageSeries, OneNoteRichText, OneNoteSection, OneNoteSectionEntry,
    OneNoteSectionGroup, OneNoteTable, OneNoteTableCell, OneNoteTableRow, OneNoteTextStyle,
    OneNoteWarning,
};
use crate::memory_file_system::MemoryFileSystem;
use onenote_parser::contents::{
    Content, EmbeddedFile, Image, Ink, InkBoundingBox, InkPoint, InkStroke, Outline,
    OutlineElement, OutlineGroup, OutlineItem, RichText, Table, TableCell, TableRow,
};
use onenote_parser::notebook::Notebook;
use onenote_parser::page::{Page, PageContent, PageSeries};
use onenote_parser::property::common::Color;
use onenote_parser::section::{Section, SectionEntry, SectionGroup};
use onenote_parser::Parser;
use std::io::Read;
use typed_path::TypedPath;

/// Parse a `.onetoc2` notebook file.
pub fn parse_notebook(path: String) -> Result<OneNoteNotebook, String> {
    #[cfg(not(target_family = "wasm"))]
    {
        Parser::new()
            .parse_notebook(TypedPath::derive(&path))
            .map(|value| notebook(&value))
            .map_err(|error| error.to_string())
    }
    #[cfg(target_family = "wasm")]
    {
        let _ = path;
        Err("path-based parsing is unavailable on web; pass file bytes instead".to_owned())
    }
}

/// Parse a `.one` section file.
pub fn parse_section(path: String) -> Result<OneNoteSection, String> {
    #[cfg(not(target_family = "wasm"))]
    {
        Parser::new()
            .parse_section(TypedPath::derive(&path))
            .map(|value| section(&value))
            .map_err(|error| error.to_string())
    }
    #[cfg(target_family = "wasm")]
    {
        let _ = path;
        Err("path-based parsing is unavailable on web; pass file bytes instead".to_owned())
    }
}

/// Parse a `.onepkg` notebook archive.
pub fn parse_package(path: String) -> Result<OneNoteNotebook, String> {
    #[cfg(not(target_family = "wasm"))]
    {
        Parser::new()
            .parse_package(TypedPath::derive(&path))
            .map(|value| notebook(&value))
            .map_err(|error| error.to_string())
    }
    #[cfg(target_family = "wasm")]
    {
        let _ = path;
        Err("path-based parsing is unavailable on web; pass file bytes instead".to_owned())
    }
}

/// Parse a `.one` section from bytes. This works on native platforms and web.
pub fn parse_section_bytes(data: Vec<u8>, file_name: String) -> Result<OneNoteSection, String> {
    Parser::new_with_fs(MemoryFileSystem { data: &[] })
        .parse_section_buffer(&data, TypedPath::derive(&file_name))
        .map(|value| section(&value))
        .map_err(|error| error.to_string())
}

/// Parse a `.onepkg` archive from bytes. This works on native platforms and web.
pub fn parse_package_bytes(data: Vec<u8>) -> Result<OneNoteNotebook, String> {
    Parser::new_with_fs(MemoryFileSystem { data: &data })
        .parse_package(TypedPath::unix("notebook.onepkg"))
        .map(|value| notebook(&value))
        .map_err(|error| error.to_string())
}

/// Dump the low-level OneStore representation for diagnostic tools.
pub fn dump_onestore(data: Vec<u8>) -> Result<String, String> {
    Parser::new_with_fs(MemoryFileSystem { data: &[] })
        .dump_onestore(&data)
        .map_err(|error| error.to_string())
}

fn notebook(value: &Notebook) -> OneNoteNotebook {
    OneNoteNotebook {
        entries: value.entries().iter().map(section_entry).collect(),
        color: value.color().map(color),
        warnings: warnings(value.report()),
    }
}

fn section_entry(value: &SectionEntry) -> OneNoteSectionEntry {
    match value {
        SectionEntry::Section(value) => OneNoteSectionEntry::Section(section(value)),
        SectionEntry::SectionGroup(value) => {
            OneNoteSectionEntry::SectionGroup(section_group(value))
        }
    }
}

fn section(value: &Section) -> OneNoteSection {
    OneNoteSection {
        display_name: value.display_name().to_owned(),
        page_series: value.page_series().iter().map(page_series).collect(),
        color: value.color().map(color),
        warnings: warnings(value.report()),
    }
}

fn section_group(value: &SectionGroup) -> OneNoteSectionGroup {
    OneNoteSectionGroup {
        display_name: value.display_name().to_owned(),
        entries: value.entries().iter().map(section_entry).collect(),
    }
}

fn page_series(value: &PageSeries) -> OneNotePageSeries {
    OneNotePageSeries {
        pages: value.pages().iter().map(page).collect(),
    }
}

fn page(value: &Page) -> OneNotePage {
    OneNotePage {
        link_target_id: value.link_target_id().to_owned(),
        title: value.title_text().map(str::to_owned),
        level: value.level(),
        created_at: value.created_time().to_string(),
        updated_at: value.updated_time().to_string(),
        author: value.author().map(str::to_owned),
        height: value.height(),
        contents: value.contents().iter().map(page_content).collect(),
        recognized_text: value.ink_recognition().map(|value| value.text()),
    }
}

fn page_content(value: &PageContent) -> OneNotePageContent {
    match value {
        PageContent::Outline(value) => OneNotePageContent::Outline(outline(value)),
        PageContent::Image(value) => OneNotePageContent::Image(image(value)),
        PageContent::EmbeddedFile(value) => {
            OneNotePageContent::EmbeddedFile(embedded_file(value))
        }
        PageContent::Ink(value) => OneNotePageContent::Ink(ink(value)),
        PageContent::Unknown => OneNotePageContent::Unknown,
    }
}

fn outline(value: &Outline) -> OneNoteOutline {
    OneNoteOutline {
        child_level: value.child_level(),
        list_spacing: value.list_spacing(),
        indents: value.indents().to_vec(),
        alignment_in_parent: value.alignment_in_parent().map(debug),
        alignment_self: value.alignment_self().map(debug),
        layout_max_height: value.layout_max_height(),
        layout_max_width: value.layout_max_width(),
        layout_reserved_width: value.layout_reserved_width(),
        layout_minimum_width: value.layout_minimum_outline_width(),
        is_layout_size_set_by_user: value.is_layout_size_set_by_user(),
        offset_horizontal: value.offset_horizontal(),
        offset_vertical: value.offset_vertical(),
        items: value.items().iter().map(outline_item).collect(),
    }
}

fn outline_item(value: &OutlineItem) -> OneNoteOutlineItem {
    match value {
        OutlineItem::Group(value) => OneNoteOutlineItem::Group(outline_group(value)),
        OutlineItem::Element(value) => OneNoteOutlineItem::Element(outline_element(value)),
    }
}

fn outline_group(value: &OutlineGroup) -> OneNoteOutlineGroup {
    OneNoteOutlineGroup {
        child_level: value.child_level(),
        items: value.outlines().iter().map(outline_item).collect(),
    }
}

fn outline_element(value: &OutlineElement) -> OneNoteOutlineElement {
    OneNoteOutlineElement {
        contents: value.contents().iter().map(content).collect(),
        list_spacing: value.list_spacing(),
        child_level: value.child_level(),
        children: value.children().iter().map(outline_item).collect(),
    }
}

fn content(value: &Content) -> OneNoteContent {
    match value {
        Content::RichText(value) => OneNoteContent::RichText(rich_text(value)),
        Content::Table(value) => OneNoteContent::Table(table(value)),
        Content::Image(value) => OneNoteContent::Image(image(value)),
        Content::EmbeddedFile(value) => OneNoteContent::EmbeddedFile(embedded_file(value)),
        Content::Ink(value) => OneNoteContent::Ink(ink(value)),
        Content::Unknown => OneNoteContent::Unknown,
    }
}

fn rich_text(value: &RichText) -> OneNoteRichText {
    OneNoteRichText {
        text: value.text().to_owned(),
        text_run_indices: value.text_run_indices().to_vec(),
        text_run_styles: value
            .text_run_formatting()
            .iter()
            .map(text_style)
            .collect(),
        paragraph_style: text_style(value.paragraph_style()),
        paragraph_space_before: value.paragraph_space_before(),
        paragraph_space_after: value.paragraph_space_after(),
        paragraph_line_spacing_exact: value.paragraph_line_spacing_exact(),
        paragraph_alignment: debug(value.paragraph_alignment()),
    }
}

fn text_style(value: &onenote_parser::contents::ParagraphStyling) -> OneNoteTextStyle {
    OneNoteTextStyle {
        bold: value.bold(),
        italic: value.italic(),
        underline: value.underline(),
        strikethrough: value.strikethrough(),
        superscript: value.superscript(),
        subscript: value.subscript(),
        font: value.font().map(str::to_owned),
        font_size: value.font_size(),
        next_style: value.next_style().map(str::to_owned),
        style_id: value.style_id().map(str::to_owned),
        paragraph_alignment: value.paragraph_alignment().map(debug),
        language_code: value.language_code(),
        math_formatting: value.math_formatting(),
        hyperlink: value.hyperlink(),
        hyperlink_protected: value.hyperlink_protected(),
        hidden: value.hidden(),
    }
}

fn table(value: &Table) -> OneNoteTable {
    OneNoteTable {
        row_count: value.rows(),
        column_count: value.cols(),
        rows: value.contents().iter().map(table_row).collect(),
        locked_columns: value.cols_locked().to_vec(),
        column_widths: value.col_widths().to_vec(),
        borders_visible: value.borders_visible(),
    }
}

fn table_row(value: &TableRow) -> OneNoteTableRow {
    OneNoteTableRow {
        cells: value.contents().iter().map(table_cell).collect(),
    }
}

fn table_cell(value: &TableCell) -> OneNoteTableCell {
    OneNoteTableCell {
        contents: value.contents().iter().map(outline_element).collect(),
        background_color: value.background_color().map(color),
        layout_max_width: value.layout_max_width(),
        indents: value.outline_indent_distance().value().to_vec(),
    }
}

fn image(value: &Image) -> OneNoteImage {
    let data = value.read().and_then(read_all);
    OneNoteImage {
        size: value.size(),
        data,
        extension: value.extension().map(str::to_owned),
        filename: value.image_filename().map(str::to_owned),
        alt_text: value.alt_text().map(str::to_owned),
        ocr_text: value.text().map(str::to_owned),
        text_language_code: value.text_language_code(),
        hyperlink_url: value.hyperlink_url().map(str::to_owned),
        displayed_page_number: value.displayed_page_number(),
        picture_width: value.picture_width(),
        picture_height: value.picture_height(),
        layout_max_width: value.layout_max_width(),
        layout_max_height: value.layout_max_height(),
        offset_horizontal: value.offset_horizontal(),
        offset_vertical: value.offset_vertical(),
        is_background: value.is_background(),
    }
}

fn embedded_file(value: &EmbeddedFile) -> OneNoteEmbeddedFile {
    let size = value.size();
    let data = read_all(value.read()).unwrap_or_default();
    OneNoteEmbeddedFile {
        filename: value.filename().to_owned(),
        file_type: debug(value.file_type()),
        data,
        size,
        layout_max_width: value.layout_max_width(),
        layout_max_height: value.layout_max_height(),
        offset_horizontal: value.offset_horizontal(),
        offset_vertical: value.offset_vertical(),
    }
}

fn ink(value: &Ink) -> OneNoteInk {
    OneNoteInk {
        strokes: value.ink_strokes().iter().map(ink_stroke).collect(),
        child_groups: value.child_groups().iter().map(ink).collect(),
        bounding_box: value.bounding_box().map(ink_bounding_box),
        offset_horizontal: value.offset_horizontal(),
        offset_vertical: value.offset_vertical(),
    }
}

fn ink_stroke(value: &InkStroke) -> OneNoteInkStroke {
    OneNoteInkStroke {
        path: value.path().iter().map(ink_point).collect(),
        pen_tip: value.pen_tip(),
        transparency: value.transparency(),
        height: value.height(),
        width: value.width(),
        color: value.color(),
        recognized_text: value
            .recognized_word()
            .and_then(|value| value.text())
            .map(str::to_owned),
    }
}

fn ink_point(value: &InkPoint) -> OneNoteInkPoint {
    OneNoteInkPoint {
        x: value.x(),
        y: value.y(),
    }
}

fn ink_bounding_box(value: InkBoundingBox) -> OneNoteInkBoundingBox {
    OneNoteInkBoundingBox {
        x: value.x(),
        y: value.y(),
        height: value.height(),
        width: value.width(),
    }
}

fn color(value: Color) -> OneNoteColor {
    OneNoteColor {
        alpha: value.alpha(),
        red: value.r(),
        green: value.g(),
        blue: value.b(),
    }
}

fn warnings(value: &onenote_parser::warn::Report) -> Vec<OneNoteWarning> {
    value
        .warnings()
        .iter()
        .map(|warning| {
            let page = warning.page();
            OneNoteWarning {
                message: warning.message().to_owned(),
                page_id: page.map(|(id, _)| id.to_string()),
                page_title: page.map(|(_, title)| title.to_owned()),
            }
        })
        .collect()
}

fn read_all(mut reader: Box<dyn Read>) -> Option<Vec<u8>> {
    let mut data = Vec::new();
    reader.read_to_end(&mut data).ok().map(|_| data)
}

fn debug(value: impl std::fmt::Debug) -> String {
    format!("{value:?}")
}
