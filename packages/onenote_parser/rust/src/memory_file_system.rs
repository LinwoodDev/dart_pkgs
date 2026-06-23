use onenote_parser::FileSystem;
use std::io::{Error, ErrorKind, Read};
use typed_path::{TypedPath, TypedPathBuf};

#[derive(Clone, Copy)]
pub(crate) struct MemoryFileSystem<'a> {
    pub(crate) data: &'a [u8],
}

impl FileSystem for MemoryFileSystem<'_> {
    fn is_directory(&self, _path: TypedPath) -> Result<bool, Error> {
        Ok(false)
    }

    fn read_dir(&self, _path: TypedPath) -> Result<Vec<TypedPathBuf>, Error> {
        Ok(Vec::new())
    }

    fn read_file(&self, _path: TypedPath) -> Result<Vec<u8>, Error> {
        Ok(self.data.to_vec())
    }

    fn write_file(&self, _path: TypedPath, _data: &[u8]) -> Result<(), Error> {
        Err(unsupported())
    }

    fn stream_to_file(&self, _path: TypedPath, _reader: &mut dyn Read) -> Result<(), Error> {
        Err(unsupported())
    }

    fn make_dir(&self, _path: TypedPath) -> Result<(), Error> {
        Err(unsupported())
    }

    fn canonicalize(&self, path: TypedPath) -> Result<TypedPathBuf, Error> {
        Ok(path.to_path_buf())
    }

    fn exists(&self, _path: TypedPath) -> Result<bool, Error> {
        Ok(true)
    }
}

fn unsupported() -> Error {
    Error::new(ErrorKind::Unsupported, "read-only in-memory file system")
}
