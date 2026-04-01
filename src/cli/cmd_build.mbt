///|
/// Placeholder render summary for the scaffold build pipeline.
pub(all) struct RenderPlan {
  output_dir : String
  emitted_html_files : Int
  emitted_assets : Int
  note : String
} derive(Show, Eq)

///|
pub fn render_site_dummy(
  config : @core.MooninkConfig,
  model : @core.SiteModel,
) -> RenderPlan {
  {
    output_dir: config.output_dir,
    emitted_html_files: model.page_count + model.article_count,
    emitted_assets: 1,
    note: "Rendering is still simulated in the scaffold stage.",
  }
}

///|
fn format_runtime_config_error(err : @core.ConfigError) -> String {
  "[build] failed during config loading\n\{@core.format_config_error(err)}"
}

///|
fn format_runtime_content_error(err : @core.ContentDiscoveryError) -> String {
  "[build] failed during content discovery\n\{@core.format_content_discovery_error(err)}"
}

///|
pub fn run_build_command_runtime() -> CliOutcome {
  let config_result = @runtime.load_config_result("moonink.json")
  let config = match config_result {
    Ok(config) => config
    Err(err) =>
      return { exit_code: 1, message: format_runtime_config_error(err) }
  }
  let inventory = match
    @runtime.run_runtime_io_task(@runtime.discover_content_task(config)) {
    Ok(inventory) => inventory
    Err(err) =>
      return { exit_code: 1, message: format_runtime_content_error(err) }
  }
  summarize_build_ready(config, inventory)
}

///|
fn summarize_build_ready(
  config : @core.MooninkConfig,
  inventory : @core.ContentInventory,
) -> CliOutcome {
  let model = @core.build_site_model_dummy(config, inventory)
  let render_plan = render_site_dummy(config, model)
  {
    exit_code: 0,
    message: "[build] phase 1a input ready\nsite: \{config.site_name}\nconfig: \{config.config_path}\ncontent root: \{inventory.root}\narticles: \{inventory.total_articles}\npages: \{inventory.total_pages}\noutput: \{render_plan.output_dir}\nstatus: config and content discovery ready",
  }
}

///|
fn run_build_command() -> CliOutcome {
  {
    exit_code: 0,
    message: "[build] runtime execution required\nstatus: use cli_exec or the runtime IO boundary to load config and discover content",
  }
}

///|
fn run_native_build_command() -> CliOutcome {
  @runtime.run_native_runtime_io_task_with_policy(
    @runtime.RuntimeIOTask::Ready(run_build_command_runtime()),
    @runtime.native_runtime_adapter().policy,
  )
}
