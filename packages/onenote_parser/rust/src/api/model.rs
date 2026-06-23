#[derive(Clone, Debug)]
pub struct OneNoteNotebook {
    pub entries: Vec<OneNoteSectionEntry>,
    pub color: Option<OneNoteColor>,
    pub warnings: Vec<OneNoteWarning>,
}

#[derive(Clone, Debug)]
pub enum OneNoteSectionEntry {
    Section(OneNoteSection),
    SectionGroup(OneNoteSectionGroup),
}

#[derive(Clone, Debug)]
pub struct OneNoteSection {
    pub display_name: String,
    pub page_series: Vec<OneNotePageSeries>,
    pub color: Option<OneNoteColor>,
    pub warnings: Vec<OneNoteWarning>,
}

#[derive(Clone, Debug)]
pub struct OneNoteSectionGroup {
    pub display_name: String,
    pub entries: Vec<OneNoteSectionEntry>,
}

#[derive(Clone, Debug)]
pub struct OneNotePageSeries {
    pub pages: Vec<OneNotePage>,
}

#[derive(Clone, Debug)]
pub struct OneNotePage {
    pub link_target_id: String,
    pub title: Option<String>,
    pub level: i32,
    pub created_at: String,
    pub updated_at: String,
    pub author: Option<String>,
    pub height: Option<f32>,
    pub contents: Vec<OneNotePageContent>,
    pub recognized_text: Option<String>,
}

#[derive(Clone, Debug)]
pub enum OneNotePageContent {
    Outline(OneNoteOutline),
    Image(OneNoteImage),
    EmbeddedFile(OneNoteEmbeddedFile),
    Ink(OneNoteInk),
    Unknown,
}

#[derive(Clone, Debug)]
pub struct OneNoteOutline {
    pub child_level: u8,
    pub list_spacing: Option<f32>,
    pub indents: Vec<f32>,
    pub alignment_in_parent: Option<String>,
    pub alignment_self: Option<String>,
    pub layout_max_height: Option<f32>,
    pub layout_max_width: Option<f32>,
    pub layout_reserved_width: Option<f32>,
    pub layout_minimum_width: Option<f32>,
    pub is_layout_size_set_by_user: bool,
    pub offset_horizontal: Option<f32>,
    pub offset_vertical: Option<f32>,
    pub items: Vec<OneNoteOutlineItem>,
}

#[derive(Clone, Debug)]
pub enum OneNoteOutlineItem {
    Group(OneNoteOutlineGroup),
    Element(OneNoteOutlineElement),
}

#[derive(Clone, Debug)]
pub struct OneNoteOutlineGroup {
    pub child_level: u8,
    pub items: Vec<OneNoteOutlineItem>,
}

#[derive(Clone, Debug)]
pub struct OneNoteOutlineElement {
    pub contents: Vec<OneNoteContent>,
    pub list_spacing: Option<f32>,
    pub child_level: u8,
    pub children: Vec<OneNoteOutlineItem>,
}

#[derive(Clone, Debug)]
pub enum OneNoteContent {
    RichText(OneNoteRichText),
    Table(OneNoteTable),
    Image(OneNoteImage),
    EmbeddedFile(OneNoteEmbeddedFile),
    Ink(OneNoteInk),
    Unknown,
}

#[derive(Clone, Debug)]
pub struct OneNoteRichText {
    pub text: String,
    pub text_run_indices: Vec<u32>,
    pub text_run_styles: Vec<OneNoteTextStyle>,
    pub paragraph_style: OneNoteTextStyle,
    pub paragraph_space_before: f32,
    pub paragraph_space_after: f32,
    pub paragraph_line_spacing_exact: Option<f32>,
    pub paragraph_alignment: String,
    pub embedded_objects: Vec<OneNoteEmbeddedObject>,
}


#[derive(Clone, Debug)]
pub enum OneNoteEmbeddedObject {
    Ink(OneNoteEmbeddedInk),
    InkSpace(OneNoteEmbeddedInkSpace),
    InkLineBreak,
}

#[derive(Clone, Debug)]
pub struct OneNoteEmbeddedInk {
    pub ink: OneNoteInk,

    // This is separate from ink.bounding_box.
    pub display_bounding_box: Option<OneNoteInkBoundingBox>,
}

#[derive(Clone, Debug)]
pub struct OneNoteEmbeddedInkSpace {
    pub width: f32,
    pub height: f32,
}
#[derive(Clone, Debug)]
pub struct OneNoteTextStyle {
    pub bold: bool,
    pub italic: bool,
    pub underline: bool,
    pub strikethrough: bool,
    pub superscript: bool,
    pub subscript: bool,
    pub font: Option<String>,
    pub font_size: Option<u16>,
    pub next_style: Option<String>,
    pub style_id: Option<String>,
    pub paragraph_alignment: Option<String>,
    pub language_code: Option<u32>,
    pub math_formatting: bool,
    pub hyperlink: bool,
    pub hyperlink_protected: bool,
    pub hidden: bool,
}

#[derive(Clone, Debug)]
pub struct OneNoteTable {
    pub row_count: u32,
    pub column_count: u32,
    pub rows: Vec<OneNoteTableRow>,
    pub locked_columns: Vec<u8>,
    pub column_widths: Vec<f32>,
    pub borders_visible: bool,
}

#[derive(Clone, Debug)]
pub struct OneNoteTableRow {
    pub cells: Vec<OneNoteTableCell>,
}

#[derive(Clone, Debug)]
pub struct OneNoteTableCell {
    pub contents: Vec<OneNoteOutlineElement>,
    pub background_color: Option<OneNoteColor>,
    pub layout_max_width: Option<f32>,
    pub indents: Vec<f32>,
}

#[derive(Clone, Debug)]
pub struct OneNoteImage {
    pub data: Option<Vec<u8>>,
    pub size: Option<u64>,
    pub extension: Option<String>,
    pub filename: Option<String>,
    pub alt_text: Option<String>,
    pub ocr_text: Option<String>,
    pub text_language_code: Option<u32>,
    pub hyperlink_url: Option<String>,
    pub displayed_page_number: Option<u32>,
    pub picture_width: Option<f32>,
    pub picture_height: Option<f32>,
    pub layout_max_width: Option<f32>,
    pub layout_max_height: Option<f32>,
    pub offset_horizontal: Option<f32>,
    pub offset_vertical: Option<f32>,
    pub is_background: bool,
}

#[derive(Clone, Debug)]
pub struct OneNoteEmbeddedFile {
    pub filename: String,
    pub file_type: String,
    pub data: Vec<u8>,
    pub size: u64,
    pub layout_max_width: Option<f32>,
    pub layout_max_height: Option<f32>,
    pub offset_horizontal: Option<f32>,
    pub offset_vertical: Option<f32>,
}

#[derive(Clone, Debug)]
pub struct OneNoteInk {
    pub strokes: Vec<OneNoteInkStroke>,
    pub child_groups: Vec<OneNoteInk>,
    pub bounding_box: Option<OneNoteInkBoundingBox>,
    pub offset_horizontal: Option<f32>,
    pub offset_vertical: Option<f32>,
}

#[derive(Clone, Debug)]
pub struct OneNoteInkStroke {
    pub path: Vec<OneNoteInkPoint>,
    pub pen_tip: Option<u8>,
    pub transparency: Option<u8>,
    pub height: f32,
    pub width: f32,
    pub color: Option<u32>,
    pub recognized_text: Option<String>,
}

#[derive(Clone, Debug)]
pub struct OneNoteInkPoint {
    pub x: f32,
    pub y: f32,
}

#[derive(Clone, Debug)]
pub struct OneNoteInkBoundingBox {
    pub x: f32,
    pub y: f32,
    pub height: f32,
    pub width: f32,
}

#[derive(Clone, Debug)]
pub struct OneNoteColor {
    pub alpha: u8,
    pub red: u8,
    pub green: u8,
    pub blue: u8,
}

#[derive(Clone, Debug)]
pub struct OneNoteWarning {
    pub message: String,
    pub page_id: Option<String>,
    pub page_title: Option<String>,
}
