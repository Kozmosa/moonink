///|
/// Build context aggregating config, pages, and inventory for the build pipeline.
pub(all) struct BuildContext {
  config : MooninkConfig
  pages : Array[PageMeta]
  inventory : ContentInventory
} derive(Debug, Eq)

///|
/// Placeholder site model for the scaffold build pipeline.
pub(all) struct SiteModel {
  page_count : Int
  article_count : Int
  navigation_items : Int
  note : String
} derive(Debug, Eq)

///|
pub fn build_site_model_dummy(
  _config : MooninkConfig,
  inventory : ContentInventory,
) -> SiteModel {
  {
    page_count: inventory.total_pages,
    article_count: inventory.total_articles,
    navigation_items: 0,
    note: "Site model building is a placeholder in the scaffold stage.",
  }
}
