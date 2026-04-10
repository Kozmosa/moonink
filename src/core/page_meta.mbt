///|
/// Page metadata for routing and generation, enriched after frontmatter parsing.
pub(all) struct PageMeta {
  source_path : String
  url_path : String
  content_kind : ContentKind
  format : SourceFormat
  frontmatter : Frontmatter
  sort_key : String
} derive(Debug, Eq)

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
    frontmatter,
    sort_key: source_path,
  }
}
