///|
pub(all) suberror BuildCommandError {
  ContentDiscovery(@core.ContentDiscoveryError)
  AdapterRegistry(@docflow.AdapterRegistryError)
  FatalParse(@docflow.FatalParseError)
  ProjectIO(@core.ProjectIOError)
} derive(Debug, Eq)

///|
pub(all) struct BuildSummary {
  output_dir : String
  processed_sources : Int
  emitted_html_files : Int
  article_count : Int
  page_count : Int
} derive(Debug, Eq)

///|
fn format_runtime_config_error(err : @core.ConfigError) -> String {
  "[build] failed during config loading\n\{@core.format_config_error(err)}"
}

///|
fn format_runtime_content_error(err : @core.ContentDiscoveryError) -> String {
  "[build] failed during content discovery\n\{@core.format_content_discovery_error(err)}"
}

///|
fn format_build_command_error(err : BuildCommandError) -> String {
  match err {
    BuildCommandError::ContentDiscovery(inner) =>
      "[build] failed during content preparation\n\{@core.format_content_discovery_error(inner)}"
    BuildCommandError::AdapterRegistry(inner) =>
      "[build] failed during adapter lookup\n\{inner.to_string()}"
    BuildCommandError::FatalParse(inner) =>
      "[build] failed during document parsing\n\{inner.to_string()}"
    BuildCommandError::ProjectIO(inner) =>
      "[build] failed during file emission\n\{@core.format_project_io_error(inner)}"
  }
}

///|
fn parser_for_format(
  format : @core.SourceFormat,
) -> Result[@docflow.ParserAdapter, BuildCommandError] {
  let registry = @docflow.register_parser_adapter(
    @docflow.register_parser_adapter(
      @docflow.empty_parser_registry(),
      @core.SourceFormat::Markdown,
      @docflow.markdown_parser_adapter(),
    ),
    @core.SourceFormat::Html,
    @docflow.html_passthrough_parser_adapter(),
  )
  match @docflow.lookup_parser_adapter(registry, format) {
    Ok(adapter) => Ok(adapter)
    Err(err) => Err(BuildCommandError::AdapterRegistry(err))
  }
}

///|
fn renderer_for_format(
  format : @core.SourceFormat,
) -> Result[@docflow.RenderAdapter, BuildCommandError] {
  let registry = @docflow.register_render_adapter(
    @docflow.register_render_adapter(
      @docflow.empty_render_registry(),
      @core.SourceFormat::Markdown,
      @docflow.markdown_render_adapter(),
    ),
    @core.SourceFormat::Html,
    @docflow.fake_render_adapter(
      "html-render-adapter",
      note="HTML passthrough render adapter for real build output.",
    ),
  )
  match @docflow.lookup_render_adapter(registry, format) {
    Ok(adapter) => Ok(adapter)
    Err(err) => Err(BuildCommandError::AdapterRegistry(err))
  }
}

///|
fn output_root(config : @core.MooninkConfig) -> String {
  @core.join_relative_path(config.project_root, config.output_dir) catch {
    _ => panic()
  }
}

///|
fn prepare_output_dir(
  config : @core.MooninkConfig,
) -> Unit raise BuildCommandError {
  let root = output_root(config)
  @runtime.io_remove_dir_all(root) catch {
    err => raise BuildCommandError::ProjectIO(err)
  }
  @runtime.io_ensure_dir(root) catch {
    err => raise BuildCommandError::ProjectIO(err)
  }
}

///|
fn write_build_output(
  config : @core.MooninkConfig,
  relative_output_path : String,
  html : String,
) -> Unit raise BuildCommandError {
  let full_path = @core.join_relative_path(
    output_root(config),
    relative_output_path,
  ) catch {
    err =>
      raise BuildCommandError::ProjectIO(
        @core.project_io_error(
          "write_file",
          relative_output_path,
          @core.format_path_policy_error(err),
        ),
      )
  }
  let parent = @core.dirname_relative_path(full_path) catch {
    err =>
      raise BuildCommandError::ProjectIO(
        @core.project_io_error("write_file", full_path, err.to_string()),
      )
  }
  @runtime.io_ensure_dir(parent) catch {
    err => raise BuildCommandError::ProjectIO(err)
  }
  @runtime.io_write_string(full_path, html) catch {
    err => raise BuildCommandError::ProjectIO(err)
  }
}

///|
fn build_site_result(
  config : @core.MooninkConfig,
  inventory : @core.ContentInventory,
) -> Result[BuildSummary, BuildCommandError] {
  let inputs = match @runtime.load_build_inputs_result(config, inventory) {
    Ok(inputs) => inputs
    Err(err) => return Err(BuildCommandError::ContentDiscovery(err))
  }
  prepare_output_dir(config) catch {
    err => return Err(err)
  }
  let mut emitted_html_files = 0
  let mut article_count = 0
  let mut page_count = 0
  for input in inputs {
    let parser = match parser_for_format(input.meta.format) {
      Ok(parser) => parser
      Err(err) => return Err(err)
    }
    let renderer = match renderer_for_format(input.meta.format) {
      Ok(renderer) => renderer
      Err(err) => return Err(err)
    }
    let source_input : @docflow.SourceDocumentInput = {
      path: input.meta.source_path,
      format: input.meta.format,
      content: input.docflow_content,
      uuid: input.meta.source_path,
    }
    let parsed = match
      @docflow.parse_with_adapter_result(parser, source_input) {
      Ok(parsed) => parsed
      Err(err) => return Err(BuildCommandError::FatalParse(err))
    }
    let linked = @docflow.apply_wikilinker(@docflow.noop_wikilinker(), parsed)
    let rendered = @docflow.render_with_adapter(renderer, linked)
    let templated = @docflow.apply_dummy_template(rendered)
    let output_path = @core.output_html_path(
      input.meta.source_path,
      config.route_style,
    )
    write_build_output(config, output_path, templated.html) catch {
      err => return Err(err)
    }
    emitted_html_files = emitted_html_files + 1
    match input.meta.content_kind {
      @core.ContentKind::Article => article_count = article_count + 1
      @core.ContentKind::Page => page_count = page_count + 1
    }
  }
  Ok({
    output_dir: config.output_dir,
    processed_sources: inputs.length(),
    emitted_html_files,
    article_count,
    page_count,
  })
}

///|
fn summarize_build_success(
  config : @core.MooninkConfig,
  inventory : @core.ContentInventory,
  summary : BuildSummary,
) -> CliOutcome {
  {
    exit_code: 0,
    message: "[build] completed\nsite: \{config.site_name}\nconfig: \{config.config_path}\ncontent root: \{inventory.root}\nprocessed: \{summary.processed_sources}\narticles: \{summary.article_count}\npages: \{summary.page_count}\noutput: \{summary.output_dir}\nemitted html: \{summary.emitted_html_files}",
  }
}

///|
pub fn run_build_command_runtime_from_config(
  config_path : String,
) -> CliOutcome {
  let config_result = @runtime.load_config_result(config_path)
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
  let summary = match build_site_result(config, inventory) {
    Ok(summary) => summary
    Err(err) =>
      return { exit_code: 1, message: format_build_command_error(err) }
  }
  summarize_build_success(config, inventory, summary)
}

///|
pub fn run_build_command_runtime() -> CliOutcome {
  run_build_command_runtime_from_config("moonink.json")
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
