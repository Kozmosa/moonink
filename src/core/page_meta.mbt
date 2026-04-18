///|
/// Page metadata for routing and generation, enriched after frontmatter parsing.
pub(all) struct PageMeta {
  source_path : String
  url_path : String
  output_path : String
  content_kind : ContentKind
  format : SourceFormat
  frontmatter : Frontmatter
  layout_override : String?
  resolved_title : String
  sort_key : String
  is_index : Bool
} derive(Debug, Eq)

///|
fn is_index_source_path(path : String) -> Bool {
  path == "index.md" ||
  path == "index.html" ||
  path == "index.htm" ||
  path.has_suffix("/index.md") ||
  path.has_suffix("/index.html") ||
  path.has_suffix("/index.htm")
}

///|
fn normalize_layout_override(layout : String?) -> String? {
  match layout {
    Some(value) => {
      let normalized = value.trim().to_string()
      if normalized.is_empty() {
        None
      } else {
        Some(normalized)
      }
    }
    None => None
  }
}

///|
pub fn PageMeta::new(
  source_path : String,
  content_kind : ContentKind,
  format : SourceFormat,
  frontmatter : Frontmatter,
  route_style : RouteStyle,
) -> PageMeta {
  let is_index = is_index_source_path(source_path)
  {
    source_path,
    url_path: generate_route(source_path, route_style),
    output_path: output_html_path(source_path, route_style),
    content_kind,
    format,
    layout_override: normalize_layout_override(frontmatter.layout),
    frontmatter,
    resolved_title: "",
    sort_key: source_path,
    is_index,
  }
}

///|
pub fn page_meta_with_title(meta : PageMeta, title : String) -> PageMeta {
  { ..meta, resolved_title: title }
}

///|
pub fn page_meta_as_home(meta : PageMeta) -> PageMeta {
  { ..meta, url_path: "/", output_path: "index.html", is_index: true }
}
