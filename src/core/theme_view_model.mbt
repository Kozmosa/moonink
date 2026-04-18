///|
pub fn theme_page_kind(meta : PageMeta) -> String {
  match meta.content_kind {
    ContentKind::Article => "article"
    ContentKind::Page => if meta.is_index { "index" } else { "page" }
  }
}

///|
pub(all) struct ThemePageViewModel {
  kind : String
  layout : String
  theme_meta : Map[String, ThemeConfigValue]
} derive(Debug, Eq)

///|
pub fn theme_page_layout_key(meta : PageMeta) -> String {
  match meta.layout_override {
    Some(layout) => layout
    None => theme_page_kind(meta)
  }
}

///|
pub fn page_view_model_from_meta(meta : PageMeta) -> ThemePageViewModel {
  {
    kind: theme_page_kind(meta),
    layout: theme_page_layout_key(meta),
    theme_meta: meta.frontmatter.theme_meta,
  }
}
