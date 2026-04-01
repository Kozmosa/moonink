///|
/// Content kind classification: article (default for .md) or page (.html or frontmatter type: page).
pub(all) enum ContentKind {
  Article
  Page
} derive(Show, Eq)

///|
/// Source format for parser dispatch.
pub(all) enum SourceFormat {
  Markdown
  Html
  Unknown
} derive(Show, Eq)

///|
/// A discovered content file with classification metadata.
pub(all) struct ContentFile {
  path : String
  content_kind : ContentKind
  format : SourceFormat
} derive(Show, Eq)

///|
/// Content discovery failures.
pub(all) suberror ContentDiscoveryError {
  IOError(ProjectIOError)
  InvalidPath(path~ : String, reason~ : String)
  MissingDirectory(String)
  NotDirectory(String)
} derive(Show, Eq)

///|
/// Result of content discovery: all files classified.
pub(all) struct ContentInventory {
  root : String
  files : Array[ContentFile]
  total_articles : Int
  total_pages : Int
  note : String
} derive(Show, Eq)

///|
/// Classify a file path by extension into a SourceFormat.
pub fn classify_source_format(path : String) -> SourceFormat {
  if path.has_suffix(".md") {
    SourceFormat::Markdown
  } else if path.has_suffix(".html") || path.has_suffix(".htm") {
    SourceFormat::Html
  } else {
    SourceFormat::Unknown
  }
}

///|
/// Classify content kind from format and optional frontmatter content_type field.
pub fn classify_content_kind(
  format : SourceFormat,
  frontmatter_type : String?,
) -> ContentKind {
  match format {
    SourceFormat::Html => ContentKind::Page
    _ =>
      match frontmatter_type {
        Some("page") => ContentKind::Page
        _ => ContentKind::Article
      }
  }
}

///|
/// Check if a directory name should be excluded during scanning.
pub fn should_exclude(name : String, exclude : Array[String]) -> Bool {
  if name.has_prefix(".") {
    return true
  }
  exclude.search_by(e => e == name) is Some(_)
}

///|
pub fn format_content_discovery_error(err : ContentDiscoveryError) -> String {
  match err {
    ContentDiscoveryError::IOError(io_error) =>
      "[discovery] io error:\n\{format_project_io_error(io_error)}"
    ContentDiscoveryError::InvalidPath(path~, reason~) =>
      "[discovery] invalid path: \{path}\nreason: \{reason}"
    ContentDiscoveryError::MissingDirectory(dir) =>
      "[discovery] missing directory: \{dir}"
    ContentDiscoveryError::NotDirectory(path) =>
      "[discovery] not a directory: \{path}"
  }
}
