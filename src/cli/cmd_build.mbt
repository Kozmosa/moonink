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
fn strip_link_target_extension(path : String) -> String {
  if path.has_suffix(".md") {
    path[:path.length() - 3].to_string()
  } else if path.has_suffix(".html") {
    path[:path.length() - 5].to_string()
  } else if path.has_suffix(".htm") {
    path[:path.length() - 4].to_string()
  } else {
    path
  }
}

///|
fn basename_without_extension(path : String) -> String {
  let stripped = strip_link_target_extension(path)
  let mut result = stripped
  for part_view in stripped.split("/") {
    result = part_view.to_string()
  }
  result
}

///|
fn index_alias_without_extension(path : String) -> String? {
  let stripped = strip_link_target_extension(path)
  if stripped == "index" {
    None
  } else if stripped.has_suffix("/index") {
    Some(stripped[:stripped.length() - 6].to_string())
  } else {
    None
  }
}

///|
fn collect_duplicate_keys(keys : Array[String]) -> Map[String, Bool] {
  let counts : Map[String, Int] = {}
  for key in keys {
    if key == "" {
      continue
    }
    match counts.get(key) {
      Some(count) => counts[key] = count + 1
      None => counts[key] = 1
    }
  }
  let duplicates : Map[String, Bool] = {}
  for entry in counts {
    let (key, count) = entry
    if count > 1 {
      duplicates[key] = true
    }
  }
  duplicates
}

///|
fn register_exact_target(
  targets : Map[String, String],
  key : String,
  url : String,
) -> Unit {
  if key == "" {
    return
  }
  targets[key] = url
}

///|
fn build_wikilinker(inputs : Array[@runtime.BuildInput]) -> @docflow.WikiLinker {
  let basename_keys : Array[String] = []
  let index_alias_keys : Array[String] = []
  for input in inputs {
    basename_keys.push(basename_without_extension(input.meta.source_path))
    match index_alias_without_extension(input.meta.source_path) {
      Some(index_key) => index_alias_keys.push(index_key)
      None => ()
    }
  }
  let duplicate_basenames = collect_duplicate_keys(basename_keys)
  let duplicate_index_aliases = collect_duplicate_keys(index_alias_keys)

  let exact_targets : Map[String, String] = {}
  let ambiguous_targets : Map[String, Array[String]] = {}
  for input in inputs {
    let source_path = input.meta.source_path
    let url = input.meta.url_path
    register_exact_target(exact_targets, source_path, url)
    register_exact_target(
      exact_targets,
      strip_link_target_extension(source_path),
      url,
    )

    let basename = basename_without_extension(source_path)
    if duplicate_basenames.get(basename) is Some(_) {
      let urls = match ambiguous_targets.get(basename) {
        Some(urls) => urls
        None => []
      }
      ambiguous_targets[basename] = urls + [url]
    } else {
      register_exact_target(exact_targets, basename, url)
    }

    match index_alias_without_extension(source_path) {
      Some(index_key) =>
        if duplicate_index_aliases.get(index_key) is Some(_) {
          let urls = match ambiguous_targets.get(index_key) {
            Some(urls) => urls
            None => []
          }
          ambiguous_targets[index_key] = urls + [url]
        } else {
          register_exact_target(exact_targets, index_key, url)
        }
      None => ()
    }
  }
  @docflow.indexed_wikilinker(exact_targets, ambiguous_targets)
}

///|
fn template_content_kind(kind : @core.ContentKind) -> String {
  match kind {
    @core.ContentKind::Article => "article"
    @core.ContentKind::Page => "page"
  }
}

///|
fn is_index_source_path(path : String) -> Bool {
  path == "index.md" ||
  path == "index.html" ||
  path == "index.htm" ||
  path.has_suffix("/index.md") ||
  path.has_suffix("/index.html") ||
  path.has_suffix("/index.htm")
}

///|
fn parent_navigation_key(path : String) -> String? {
  let stripped = strip_link_target_extension(path)
  let segments = stripped.split("/").map(StringView::to_string).collect()
  if segments.length() <= 1 {
    None
  } else {
    let parents : Array[String] = []
    let parent_count = segments.length() - 1
    for i in 0..<parent_count {
      parents.push(segments[i])
    }
    Some(parents.iter().join("/"))
  }
}

///|
fn navigation_node_key(page : @core.SitePage) -> String {
  let stripped = strip_link_target_extension(page.source_path)
  if page.is_index {
    match parent_navigation_key(page.source_path) {
      Some(parent) => parent
      None => ""
    }
  } else {
    stripped
  }
}

///|
fn navigation_parent_key(page : @core.SitePage) -> String? {
  parent_navigation_key(navigation_node_key(page))
}

///|
fn navigation_sort_key(page : @core.SitePage) -> String {
  if page.is_index {
    page.source_path
  } else {
    "zzz/" + page.source_path
  }
}

///|
fn find_navigation_children(
  pages : Array[@core.SitePage],
  parent_key : String,
) -> Array[@core.NavigationItem] {
  let children_pages : Array[@core.SitePage] = []
  for page in pages {
    match navigation_parent_key(page) {
      Some(candidate_parent) if candidate_parent == parent_key =>
        children_pages.push(page)
      _ => ()
    }
  }
  children_pages.sort_by(fn(a, b) {
    navigation_sort_key(a).compare(navigation_sort_key(b))
  })
  let children : Array[@core.NavigationItem] = []
  for page in children_pages {
    children.push(build_navigation_item(pages, page))
  }
  children
}

///|
fn build_navigation_item(
  pages : Array[@core.SitePage],
  page : @core.SitePage,
) -> @core.NavigationItem {
  {
    title: page.title,
    url_path: page.url_path,
    source_path: page.source_path,
    content_kind: page.content_kind,
    children: find_navigation_children(pages, navigation_node_key(page)),
    is_index: page.is_index,
  }
}

///|
pub fn build_navigation_model(
  pages : Array[@core.SitePage],
) -> @core.NavigationModel {
  let nav_pages : Array[@core.SitePage] = []
  for page in pages {
    if page.content_kind == @core.ContentKind::Page {
      nav_pages.push(page)
    }
  }
  nav_pages.sort_by(fn(a, b) {
    navigation_sort_key(a).compare(navigation_sort_key(b))
  })
  let items : Array[@core.NavigationItem] = []
  for page in nav_pages {
    match navigation_parent_key(page) {
      None => items.push(build_navigation_item(nav_pages, page))
      Some("") => items.push(build_navigation_item(nav_pages, page))
      _ => ()
    }
  }
  {
    items,
    total_items: nav_pages.length(),
    note: "Navigation model groups page content by source path hierarchy.",
  }
}

///|
fn escape_html_text(value : String) -> String {
  let mut cursor = 0
  let mut output = ""
  while cursor < value.length() {
    let char = value[cursor:cursor + 1].to_string()
    if char == "&" {
      output = output + "&amp;"
    } else if char == "<" {
      output = output + "&lt;"
    } else if char == ">" {
      output = output + "&gt;"
    } else if char == "\"" {
      output = output + "&quot;"
    } else if char == "'" {
      output = output + "&#39;"
    } else {
      output = output + char
    }
    cursor = cursor + 1
  }
  output
}

///|
fn navigation_bool_attr(value : Bool) -> String {
  if value {
    "true"
  } else {
    "false"
  }
}

///|
fn navigation_contains_url(
  item : @core.NavigationItem,
  current_url : String,
) -> Bool {
  if item.url_path == current_url {
    return true
  }
  for child in item.children {
    if navigation_contains_url(child, current_url) {
      return true
    }
  }
  false
}

///|
fn render_navigation_items(
  items : Array[@core.NavigationItem],
  current_url : String,
) -> String {
  let mut html = "<ul>"
  for item in items {
    let is_active = item.url_path == current_url
    let is_ancestor = !is_active && navigation_contains_url(item, current_url)
    let active_attr = navigation_bool_attr(is_active)
    let ancestor_attr = navigation_bool_attr(is_ancestor)
    let index_attr = navigation_bool_attr(item.is_index)
    html = html +
      "<li data-active=\"" +
      active_attr +
      "\" data-ancestor=\"" +
      ancestor_attr +
      "\" data-index=\"" +
      index_attr +
      "\"><a href=\"" +
      escape_html_text(item.url_path) +
      "\">" +
      escape_html_text(item.title) +
      "</a>"
    if !item.children.is_empty() {
      html = html + render_navigation_items(item.children, current_url)
    }
    html = html + "</li>"
  }
  html + "</ul>"
}

///|
pub fn render_navigation_html(
  navigation : @core.NavigationModel,
  current_url : String,
) -> String {
  "<nav data-moonink-nav=\"auto\">" +
  render_navigation_items(navigation.items, current_url) +
  "</nav>"
}

///|
pub fn site_page_title(meta : @core.PageMeta) -> String {
  match meta.frontmatter.title {
    Some(title) => title
    None =>
      if is_index_source_path(meta.source_path) {
        "Home"
      } else {
        basename_without_extension(meta.source_path)
      }
  }
}

///|
pub fn site_page_description(meta : @core.PageMeta) -> String {
  match meta.frontmatter.description {
    Some(description) => description
    None => ""
  }
}

///|
fn build_site_page(input : @runtime.BuildInput) -> @core.SitePage {
  {
    title: site_page_title(input.meta),
    description: site_page_description(input.meta),
    source_path: input.meta.source_path,
    url_path: input.meta.url_path,
    content_kind: input.meta.content_kind,
    is_index: is_index_source_path(input.meta.source_path),
  }
}

///|
pub fn build_site_pages(
  inputs : Array[@runtime.BuildInput],
) -> Array[@core.SitePage] {
  let pages : Array[@core.SitePage] = []
  for input in inputs {
    pages.push(build_site_page(input))
  }
  pages
}

///|
pub fn build_site_assembly_model(
  _config : @core.MooninkConfig,
  inputs : Array[@runtime.BuildInput],
  inventory : @core.ContentInventory,
) -> @core.SiteAssemblyModel {
  let pages = build_site_pages(inputs)
  let navigation = build_navigation_model(pages)
  {
    pages,
    navigation,
    page_count: inventory.total_pages,
    article_count: inventory.total_articles,
    navigation_items: navigation.total_items,
    note: "Site assembly combines page metadata and navigation before templating.",
  }
}

///|
fn build_template_context(
  config : @core.MooninkConfig,
  assembly : @core.SiteAssemblyModel,
  input : @runtime.BuildInput,
  rendered : @docflow.RenderedDocument,
) -> @docflow.TemplateContext {
  {
    site_name: config.site_name,
    site_url: match config.site_url {
      Some(site_url) => site_url
      None => ""
    },
    page_title: site_page_title(input.meta),
    page_description: site_page_description(input.meta),
    url_path: input.meta.url_path,
    source_path: input.meta.source_path,
    content_kind: template_content_kind(input.meta.content_kind),
    navigation_html: render_navigation_html(
      assembly.navigation,
      input.meta.url_path,
    ),
    body_html: rendered.html,
  }
}

///|
fn apply_build_template(
  config : @core.MooninkConfig,
  assembly : @core.SiteAssemblyModel,
  input : @runtime.BuildInput,
  rendered : @docflow.RenderedDocument,
  template_source : String?,
) -> @docflow.TemplatedPage {
  let context = build_template_context(config, assembly, input, rendered)
  match template_source {
    Some(template_source) =>
      @docflow.apply_template(rendered, context, template_source)
    None => @docflow.apply_built_in_template(rendered, context)
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
  let wikilinker = build_wikilinker(inputs)
  let assembly = build_site_assembly_model(config, inputs, inventory)
  let template_source = match @runtime.load_template_source_result(config) {
    Ok(template_source) => template_source
    Err(err) =>
      return Err(
        BuildCommandError::ProjectIO(
          @core.project_io_error(
            "load_template",
            match config.template_file {
              Some(path) => path
              None => config.config_path
            },
            @core.format_config_error(err),
          ),
        ),
      )
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
    let linked = @docflow.apply_wikilinker(wikilinker, parsed)
    let rendered = @docflow.render_with_adapter(renderer, linked)
    let templated = apply_build_template(
      config, assembly, input, rendered, template_source,
    )
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
