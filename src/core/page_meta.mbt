///|
/// Page metadata for routing and generation, enriched after frontmatter parsing.
pub(all) struct PageMeta {
  source_path : String
  url_path : String
  content_kind : ContentKind
  format : SourceFormat
  frontmatter : Frontmatter
  layout_override : String?
  sort_key : String
} derive(Debug, Eq)

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
  {
    source_path,
    url_path: generate_route(source_path, route_style),
    content_kind,
    format,
    layout_override: normalize_layout_override(frontmatter.layout),
    frontmatter,
    sort_key: source_path,
  }
}
