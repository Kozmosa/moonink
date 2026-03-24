///|
/// Placeholder configuration object for the scaffold build pipeline.
pub(all) struct LoadedConfig {
  config_path : String
  site_name : String
  docs_dir : String
  articles_dir : String
  output_dir : String
  note : String
} derive(Show, Eq)

///|
pub fn load_config_dummy() -> LoadedConfig {
  {
    config_path: "moonink.toml",
    site_name: "MoonInk Example",
    docs_dir: "docs",
    articles_dir: "articles",
    output_dir: "site",
    note: "Configuration loading is a dummy implementation in the scaffold stage.",
  }
}
