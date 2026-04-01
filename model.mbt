///|
/// Placeholder site model for the scaffold build pipeline.
pub(all) struct SiteModel {
  page_count : Int
  article_count : Int
  navigation_items : Int
  note : String
} derive(Show, Eq)

///|
pub fn build_site_model_dummy(
  _config : LoadedConfig,
  inventory : ContentInventory,
) -> SiteModel {
  {
    page_count: inventory.discovered_documents,
    article_count: 1,
    navigation_items: 2,
    note: "Site model building is a placeholder in the scaffold stage.",
  }
}
