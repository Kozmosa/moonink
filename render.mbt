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
fn run_build_command() -> CliOutcome {
  let config = load_config_dummy()
  let inventory = discover_content_dummy(config)
  let model = build_site_model_dummy(config, inventory)
  let render_plan = render_site_dummy(config, model)
  {
    exit_code: 0,
    message:
      "[build] scaffold pipeline executed\nconfig: \{config.config_path}\noutput: \{render_plan.output_dir}\nstatus: placeholder only",
  }
}
