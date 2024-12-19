use std::{path::Path, sync::Mutex};

use flutter_rust_bridge::frb;
pub use onenote_parser::{errors::Error, page::*, property::common::*, section::*, Parser};

pub fn parse_one_note(data: &[u8]) -> Result<OneNoteSection, Error> {
    let mut parser = Parser::new();
    let section = parser.parse_section_buffer(data, Path::new("section.one"))?;
    return Ok(OneNoteSection(Mutex::new(section)));
}

#[frb(opaque)]
pub struct OneNoteSection(pub(crate) Mutex<Section>);

impl OneNoteSection {
    #[frb(sync)]
    pub fn display_name(self) -> String {
        self.0.lock().unwrap().display_name().to_string()
    }

    #[frb(sync)]
    pub fn pages(self) -> Vec<OneNotePage> {
        self.0
            .lock()
            .unwrap()
            .page_series()
            .iter()
            .map(|x| OneNotePage(Mutex::new(x.clone())).into())
            .collect()
    }
}

#[frb(opaque)]
pub struct OneNotePage(pub(crate) Mutex<PageSeries>);

#[frb(init)]
pub fn init_app() {
    // Default utilities - feel free to customize
    flutter_rust_bridge::setup_default_user_utils();
}
