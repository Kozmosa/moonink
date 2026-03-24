///|
/// Placeholder content discovery summary for the scaffold build pipeline.
pub(all) struct ContentInventory {
  docs_root : String
  articles_root : String
  discovered_documents : Int
  discovered_assets : Int
  note : String
} derive(Show, Eq)

///|
pub fn discover_content_dummy(config : LoadedConfig) -> ContentInventory {
  {
    docs_root: config.docs_dir,
    articles_root: config.articles_dir,
    discovered_documents: 2,
    discovered_assets: 0,
    note: "Content discovery is still simulated during the scaffold stage.",
  }
}
