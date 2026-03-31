///|
/// Placeholder render summary for the scaffold build pipeline.
pub(all) struct RenderPlan {
  output_dir : String
  emitted_html_files : Int
  emitted_assets : Int
  note : String
} derive(Show, Eq)

///|
pub fn render_site_dummy(config : LoadedConfig, model : SiteModel) -> RenderPlan {
  {
    output_dir: config.output_dir,
    emitted_html_files: model.page_count,
    emitted_assets: 1,
    note: "Rendering is still simulated in the scaffold stage.",
  }
}

///|
fn format_runtime_config_error(err : ConfigError) -> String {
  match err {
    ConfigError::IOError(io_error) =>
      "[build] failed during config loading\nio error:\n\{format_project_io_error(io_error)}"
    _ => "[build] failed during config loading\nerror: \{err}"
  }
}

///|
fn format_runtime_content_error(err : ContentDiscoveryError) -> String {
  match err {
    ContentDiscoveryError::IOError(io_error) =>
      "[build] failed during content discovery\nio error:\n\{format_project_io_error(io_error)}"
    _ => "[build] failed during content discovery\nerror: \{err}"
  }
}

///|
pub fn run_build_command_runtime() -> CliOutcome {
  let config = try load_config() catch {
    err => {
      return {
        exit_code: 1,
        message: format_runtime_config_error(err),
      }
    }
  }
  let inventory = try discover_content(config) catch {
    err => {
      return {
        exit_code: 1,
        message: format_runtime_content_error(err),
      }
    }
  }
  summarize_build_ready(config, inventory)
}

///|
fn summarize_build_ready(config : LoadedConfig, inventory : ContentInventory) -> CliOutcome {
  let model = build_site_model_dummy(config, inventory)
  let render_plan = render_site_dummy(config, model)
  {
    exit_code: 0,
    message:
      "[build] phase 1a input ready\nsite: \{config.site_name}\nconfig: \{config.config_path}\ndocs root: \{inventory.docs_root}\narticles root: \{inventory.articles_root}\ndocs files: \{inventory.discovered_docs}\narticle files: \{inventory.discovered_articles}\noutput: \{render_plan.output_dir}\nstatus: config and content discovery ready",
  }
}

///|
fn run_build_command() -> CliOutcome {
  {
    exit_code: 0,
    message:
      "[build] runtime execution required\nstatus: use cli_exec or the runtime IO boundary to load config and discover content",
  }
}
