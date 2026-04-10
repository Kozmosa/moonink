///|
/// Build context aggregating config, pages, and inventory for the build pipeline.
pub(all) struct BuildContext {
  config : MooninkConfig
  pages : Array[PageMeta]
  inventory : ContentInventory
} derive(Debug, Eq)

///|
/// Site-level page view derived from PageMeta for site assembly stages.
pub(all) struct SitePage {
  title : String
  description : String
  source_path : String
  url_path : String
  content_kind : ContentKind
  is_index : Bool
} derive(Debug, Eq)

///|
/// Tree node used by the auto-navigation site assembly stage.
pub(all) struct NavigationItem {
  title : String
  url_path : String
  source_path : String
  content_kind : ContentKind
  children : Array[NavigationItem]
  is_index : Bool
} derive(Debug, Eq)

///|
/// Root navigation model assembled from site pages.
pub(all) struct NavigationModel {
  items : Array[NavigationItem]
  total_items : Int
  note : String
} derive(Debug, Eq)

///|
/// Site assembly result used by build orchestration before templating.
pub(all) struct SiteAssemblyModel {
  pages : Array[SitePage]
  navigation : NavigationModel
  page_count : Int
  article_count : Int
  navigation_items : Int
  note : String
} derive(Debug, Eq)

///|
pub fn build_site_model_dummy(
  _config : MooninkConfig,
  inventory : ContentInventory,
) -> SiteAssemblyModel {
  {
    pages: [],
    navigation: {
      items: [],
      total_items: 0,
      note: "Navigation assembly is a placeholder in the scaffold stage.",
    },
    page_count: inventory.total_pages,
    article_count: inventory.total_articles,
    navigation_items: 0,
    note: "Site model building is a placeholder in the scaffold stage.",
  }
}
