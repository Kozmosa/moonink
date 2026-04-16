///|
pub(all) struct ThemePageViewModel {
  layout : String?
  theme_meta : Map[String, ThemeConfigValue]
  slots : Map[String, String]
} derive(Debug, Eq)

///|
pub fn page_view_model_from_meta(meta : PageMeta) -> ThemePageViewModel {
  {
    layout: meta.layout_override,
    theme_meta: meta.frontmatter.theme_meta,
    slots: {},
  }
}
