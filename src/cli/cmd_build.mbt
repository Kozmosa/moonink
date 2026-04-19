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
pub(all) struct BuildDiagnostic {
  source_path : String
  entry : @docflow.DocumentDiagnostic
} derive(Debug, Eq)

///|
pub(all) struct BuildWithDiagnostics {
  summary : BuildSummary
  diagnostics : Array[BuildDiagnostic]
} derive(Debug, Eq)

///|
pub(all) suberror CheckCommandError {
  ContentDiscovery(@core.ContentDiscoveryError)
  AdapterRegistry(@docflow.AdapterRegistryError)
  FatalParse(@docflow.FatalParseError)
  ThemeLoad(@core.ProjectIOError)
} derive(Debug, Eq)

///|
pub(all) struct CheckSummary {
  processed_sources : Int
  article_count : Int
  page_count : Int
  report : CheckReport
} derive(Debug, Eq)

///|
pub(all) enum CheckCategory {
  ThemeTemplate
  Frontmatter
  Wikilinks
  Routes
  Site
} derive(Debug, Eq)

///|
pub(all) enum CheckSeverity {
  Warning
  Error
} derive(Debug, Eq)

///|
pub(all) struct CheckEntry {
  category : CheckCategory
  severity : CheckSeverity
  source_path : String?
  message : String
  hint : String?
  line : Int?
} derive(Debug, Eq)

///|
pub(all) struct CheckReport {
  entries : Array[CheckEntry]
  error_count : Int
  warning_count : Int
} derive(Debug, Eq)

///|
pub(all) struct ArticleExperienceModel {
  toc : Map[String, Array[@core.HeadingEntry]]
  backlinks : Map[String, Array[@core.BacklinkEntry]]
  related : Map[String, Array[@core.RelatedEntry]]
  previous : Map[String, @core.PageLink]
  next : Map[String, @core.PageLink]
  series : Map[String, @core.SeriesNav]
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
fn format_check_runtime_config_error(err : @core.ConfigError) -> String {
  "[check] failed during config loading\n\{@core.format_config_error(err)}"
}

///|
fn format_check_runtime_content_error(
  err : @core.ContentDiscoveryError,
) -> String {
  "[check] failed during content discovery\n\{@core.format_content_discovery_error(err)}"
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
fn format_check_command_error(err : CheckCommandError) -> String {
  match err {
    CheckCommandError::ContentDiscovery(inner) =>
      "[check] failed during content preparation\n\{@core.format_content_discovery_error(inner)}"
    CheckCommandError::AdapterRegistry(inner) =>
      "[check] failed during adapter lookup\n\{inner.to_string()}"
    CheckCommandError::FatalParse(inner) =>
      "[check] failed during document parsing\n\{inner.to_string()}"
    CheckCommandError::ThemeLoad(inner) =>
      "[check] failed during theme loading\n\{@core.format_project_io_error(inner)}"
  }
}

///|
fn check_parser_for_format(
  format : @core.SourceFormat,
) -> Result[@docflow.ParserAdapter, CheckCommandError] {
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
    Err(err) => Err(CheckCommandError::AdapterRegistry(err))
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
fn copy_public_assets(
  config : @core.MooninkConfig,
) -> Unit raise BuildCommandError {
  let public_root = @core.join_relative_path(config.project_root, "public") catch {
    err =>
      raise BuildCommandError::ProjectIO(
        @core.project_io_error(
          "copy_public",
          "public",
          @core.format_path_policy_error(err),
        ),
      )
  }
  if !@runtime.io_path_exists(public_root) {
    return
  }
  let is_dir = @runtime.io_is_dir(public_root) catch {
    err => raise BuildCommandError::ProjectIO(err)
  }
  if !is_dir {
    raise BuildCommandError::ProjectIO(
      @core.project_io_error(
        "copy_public", public_root, "public path exists and is not a directory",
      ),
    )
  }
  @runtime.io_copy_dir_recursive(public_root, output_root(config)) catch {
    err => raise BuildCommandError::ProjectIO(err)
  }
}

///|
fn copy_assets_dir(
  config : @core.MooninkConfig,
  assets_root : String,
) -> Unit raise BuildCommandError {
  if !@runtime.io_path_exists(assets_root) {
    return
  }
  let is_dir = @runtime.io_is_dir(assets_root) catch {
    err => raise BuildCommandError::ProjectIO(err)
  }
  if !is_dir {
    raise BuildCommandError::ProjectIO(
      @core.project_io_error(
        "copy_theme_assets", assets_root, "theme assets path exists and is not a directory",
      ),
    )
  }
  let target_root = @core.join_relative_path(output_root(config), "assets") catch {
    err =>
      raise BuildCommandError::ProjectIO(
        @core.project_io_error(
          "copy_theme_assets",
          output_root(config),
          @core.format_path_policy_error(err),
        ),
      )
  }
  @runtime.io_copy_dir_recursive(assets_root, target_root) catch {
    err => raise BuildCommandError::ProjectIO(err)
  }
}

///|
fn copy_selected_theme_assets(
  config : @core.MooninkConfig,
  active_theme : @runtime.ActiveThemeLayout,
) -> Unit raise BuildCommandError {
  match active_theme.asset_source_dir {
    Some(path) => copy_assets_dir(config, path)
    None => ()
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
fn reserved_output_paths() -> Array[String] {
  ["search-index.json", "assets/theme-vars.css", "rss.xml"]
}

///|
fn validate_static_asset_output_conflicts(
  inventory : @core.ContentInventory,
  inputs : Array[@runtime.BuildInput],
  generated_pages : Array[@core.GeneratedPage],
) -> Unit raise BuildCommandError {
  let output_paths = collect_output_path_sources(inputs)
  for generated_page in generated_pages {
    let existing = match output_paths.get(generated_page.output_path) {
      Some(paths) => paths
      None => []
    }
    output_paths[generated_page.output_path] = existing +
      [generated_page.source_path]
  }
  for entry in output_paths {
    let (output_path, sources) = entry
    if sources.length() > 1 {
      raise BuildCommandError::ProjectIO(
        @core.project_io_error(
          "build",
          output_path,
          "final output path conflict: " + sources.iter().join(", "),
        ),
      )
    }
  }
  for asset in inventory.asset_files {
    if output_paths.get(asset.relative_path) is Some(_) {
      raise BuildCommandError::ProjectIO(
        @core.project_io_error(
          "build",
          asset.relative_path,
          "vault asset output path conflict with generated html",
        ),
      )
    }
    if reserved_output_paths().search_by(fn(path) {
        path == asset.relative_path
      })
      is Some(_) {
      raise BuildCommandError::ProjectIO(
        @core.project_io_error(
          "build",
          asset.relative_path,
          "vault asset output path conflict with generated artifact",
        ),
      )
    }
  }
}

///|
fn copy_content_tree_assets(
  config : @core.MooninkConfig,
  inventory : @core.ContentInventory,
) -> Unit raise BuildCommandError {
  for asset in inventory.asset_files {
    let target = @core.join_relative_path(
      output_root(config),
      asset.relative_path,
    ) catch {
      err =>
        raise BuildCommandError::ProjectIO(
          @core.project_io_error(
            "copy_vault_asset",
            asset.relative_path,
            @core.format_path_policy_error(err),
          ),
        )
    }
    @runtime.io_copy_file(asset.path, target) catch {
      err => raise BuildCommandError::ProjectIO(err)
    }
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
pub fn build_wikilinker(
  inputs : Array[@runtime.BuildInput],
) -> @docflow.WikiLinker {
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
pub fn build_wikilinker_with_assets(
  inputs : Array[@runtime.BuildInput],
  asset_files : Array[@core.StaticAssetFile],
) -> @docflow.WikiLinker {
  let note_linker = build_wikilinker(inputs)
  let asset_basenames : Array[String] = []
  for asset in asset_files {
    asset_basenames.push(basename_without_extension(asset.relative_path))
  }
  let duplicate_asset_basenames = collect_duplicate_keys(asset_basenames)
  let resource_targets = note_linker.resource_targets.copy()
  let ambiguous_resource_targets = note_linker.ambiguous_resource_targets.copy()
  for asset in asset_files {
    let url = "/" + asset.relative_path
    register_exact_target(resource_targets, asset.relative_path, url)
    let basename = basename_without_extension(asset.relative_path)
    if duplicate_asset_basenames.get(basename) is Some(_) {
      let urls = match ambiguous_resource_targets.get(basename) {
        Some(urls) => urls
        None => []
      }
      ambiguous_resource_targets[basename] = urls + [url]
    } else {
      register_exact_target(resource_targets, basename, url)
    }
  }
  { ..note_linker, resource_targets, ambiguous_resource_targets }
}

///|
pub fn build_backlink_index(
  inputs : Array[@runtime.BuildInput],
  wikilinker : @docflow.WikiLinker,
) -> Map[String, Array[String]] {
  let backlinks : Map[String, Array[String]] = {}
  for input in inputs {
    if input.meta.format != @core.SourceFormat::Markdown {
      continue
    }
    let parsed : @docflow.ParsedDocument = {
      backend_name: "backlink-scan",
      source_format: input.meta.format,
      source_path: input.meta.source_path,
      source_uuid: input.meta.source_path,
      diagnostics: @docflow.empty_document_diagnostics(),
      backend_payload: Some(input.docflow_content),
    }
    let resolved_targets = @docflow.collect_resolved_wikilink_targets(
      wikilinker, parsed,
    )
    for url in resolved_targets {
      let existing = match backlinks.get(url) {
        Some(urls) => urls
        None => []
      }
      let already_present = existing.search_by(fn(existing_url) {
          existing_url == input.meta.url_path
        })
        is Some(_)
      if !already_present {
        backlinks[url] = existing + [input.meta.url_path]
      }
    }
  }
  backlinks
}

///|
fn collect_output_path_sources(
  inputs : Array[@runtime.BuildInput],
) -> Map[String, Array[String]] {
  let output_paths : Map[String, Array[String]] = {}
  for input in inputs {
    let output_path = input.meta.output_path
    let existing = match output_paths.get(output_path) {
      Some(paths) => paths
      None => []
    }
    output_paths[output_path] = existing + [input.meta.source_path]
  }
  output_paths
}

///|
fn append_route_conflicts(
  inputs : Array[@runtime.BuildInput],
  _route_style : @core.RouteStyle,
  report : CheckReport,
) -> CheckReport {
  let mut next_report = report
  let output_paths = collect_output_path_sources(inputs)
  for entry in output_paths {
    let (output_path, sources) = entry
    if sources.length() > 1 {
      next_report = report_with_entry(next_report, {
        category: CheckCategory::Routes,
        severity: CheckSeverity::Error,
        source_path: None,
        message: "Final output path conflict",
        hint: Some(
          "`" + output_path + "` is produced by " + sources.iter().join(", "),
        ),
        line: None,
      })
    }
  }
  next_report
}

///|
fn render_backlinks_html(entries : Array[@core.BacklinkEntry]) -> String {
  if entries.is_empty() {
    return ""
  }
  let items : Array[String] = []
  for entry in entries {
    let date_html = match entry.date {
      Some(date) =>
        "<p class=\"backlink-meta\"><span class=\"backlink-date\">" +
        escape_html_text(date) +
        "</span></p>"
      None => ""
    }
    let series_html = match entry.series {
      Some(series) =>
        "<p class=\"backlink-series\">" + escape_html_text(series) + "</p>"
      None => ""
    }
    items.push(
      "<li class=\"backlink-card\"><a class=\"backlink-link\" href=\"" +
      escape_html_text(entry.page.url_path) +
      "\"><span class=\"backlink-title\">" +
      escape_html_text(entry.page.title) +
      "</span></a>" +
      series_html +
      date_html +
      "<p class=\"backlink-snippet\">" +
      escape_html_text(entry.snippet) +
      "</p></li>",
    )
  }
  "<aside class=\"page-backlinks\"><section class=\"backlinks\" aria-label=\"Backlinks\"><div class=\"section-heading\"><p class=\"section-kicker\">Knowledge network</p><h2>Backlinks</h2></div><ul class=\"backlink-list\">" +
  items.iter().join("") +
  "</ul></section></aside>"
}

///|
fn template_content_kind(kind : @core.ContentKind) -> String {
  match kind {
    @core.ContentKind::Article => "article"
    @core.ContentKind::Page => "page"
  }
}

///|
fn theme_name(active_theme : @runtime.ActiveThemeLayout) -> String {
  active_theme.theme_name
}

///|
fn theme_asset_root(active_theme : @runtime.ActiveThemeLayout) -> String {
  match active_theme.asset_source_dir {
    Some(_) => "/assets/"
    None => ""
  }
}

///|
fn theme_bundle_asset_root(bundle : @runtime.ActiveThemeBundle) -> String {
  match bundle.assets_root {
    Some(_) => "/assets/"
    None => ""
  }
}

///|
fn configured_site_url(config : @core.MooninkConfig) -> String {
  match config.site_url {
    Some(site_url) => site_url
    None => "/"
  }
}

///|
fn assign_public_surface_site_urls(
  site : Map[String, @core.ThemeConfigValue],
  config : @core.MooninkConfig,
) -> Unit {
  site["search_url"] = theme_string_value(
    generated_surface_route(config, "search"),
  )
  site["tags_url"] = theme_string_value(generated_surface_route(config, "tags"))
  site["series_url"] = theme_string_value(
    generated_surface_route(config, "series"),
  )
  site["archive_url"] = theme_string_value(
    generated_surface_route(config, "archive"),
  )
}

///|
fn slot_text_value(
  slots : Map[String, @core.ThemeConfigValue],
  slot_name : String,
) -> String {
  match slots.get(slot_name) {
    Some(@core.ThemeConfigValue::StringValue(value)) => value
    _ => ""
  }
}

///|
fn assign_slot_html(
  slots : Map[String, @core.ThemeConfigValue],
  slot_name : String,
  html : String,
) -> Unit {
  slots[slot_name] = theme_string_value(html)
}

///|
fn append_slot_html(
  slots : Map[String, @core.ThemeConfigValue],
  slot_name : String,
  html : String,
) -> Unit {
  if html == "" {
    return
  }
  let existing = slot_text_value(slots, slot_name)
  if existing == "" {
    assign_slot_html(slots, slot_name, html)
  } else {
    assign_slot_html(slots, slot_name, existing + html)
  }
}

///|
fn apply_declared_slot_values(
  slots : Map[String, @core.ThemeConfigValue],
  bundle : @runtime.ActiveThemeBundle,
  config : @core.MooninkConfig,
) -> Unit {
  for
    entry in @runtime.declared_slot_values(
      bundle.manifest.slots,
      config.theme_config,
    ) {
    let (slot_name, slot_value) = entry
    if slot_name == "head" || slot_name == "scripts" {
      append_slot_html(slots, slot_name, slot_value)
    } else if slots.get(slot_name) is None {
      slots[slot_name] = theme_string_value(slot_value)
    }
  }
}

///|
fn page_head_description(page : @core.SitePage) -> String {
  if page.summary != "" {
    page.summary
  } else {
    page.description
  }
}

///|
fn content_og_type(kind : @core.ContentKind) -> String {
  if kind == @core.ContentKind::Article {
    "article"
  } else {
    "website"
  }
}

///|
fn theme_token_css_name(token_name : String) -> String {
  let parts : Array[String] = []
  for part_view in token_name.split(".") {
    let part = part_view.to_string()
    if !part.is_empty() {
      parts.push(part)
    }
  }
  if parts.is_empty() {
    "--moonink"
  } else {
    "--moonink-" + parts.iter().join("-")
  }
}

///|
fn write_theme_vars_output(
  config : @core.MooninkConfig,
  bundle : @runtime.ActiveThemeBundle,
) -> Unit raise BuildCommandError {
  let merged = @runtime.merge_theme_tokens(
    bundle.manifest.tokens,
    config.theme_config,
  )
  let token_names : Array[String] = []
  for entry in merged {
    let (name, _) = entry
    token_names.push(name)
  }
  token_names.sort_by(fn(a, b) { a.compare(b) })
  let lines : Array[String] = [":root {"]
  for name in token_names {
    match merged.get(name) {
      Some(value) =>
        lines.push("  " + theme_token_css_name(name) + ": " + value + ";")
      None => ()
    }
  }
  lines.push("}")
  write_build_output(config, "assets/theme-vars.css", lines.iter().join("\n")) catch {
    err => raise err
  }
}

///|
fn ensure_surface_search_asset(
  config : @core.MooninkConfig,
) -> Unit raise BuildCommandError {
  let assets_dir = @core.join_relative_path(output_root(config), "assets") catch {
    err =>
      raise BuildCommandError::ProjectIO(
        @core.project_io_error(
          "copy_theme_assets",
          output_root(config),
          @core.format_path_policy_error(err),
        ),
      )
  }
  @runtime.io_ensure_dir(assets_dir) catch {
    err => raise BuildCommandError::ProjectIO(err)
  }
  let target_path = @core.join_relative_path(assets_dir, "moonink-search.js") catch {
    err =>
      raise BuildCommandError::ProjectIO(
        @core.project_io_error(
          "copy_theme_assets",
          assets_dir,
          @core.format_path_policy_error(err),
        ),
      )
  }
  if @runtime.io_path_exists(target_path) {
    return
  }
  let source_path = @runtime.built_in_default_theme_root() +
    "/assets/moonink-search.js"
  @runtime.io_copy_file(source_path, target_path) catch {
    err => raise BuildCommandError::ProjectIO(err)
  }
}

///|
fn write_rss_output(
  config : @core.MooninkConfig,
  pages : Array[@core.SitePage],
) -> Unit raise BuildCommandError {
  write_build_output(config, "rss.xml", render_rss_xml(config, pages)) catch {
    err => raise err
  }
}

///|
fn theme_string_value(value : String) -> @core.ThemeConfigValue {
  @core.ThemeConfigValue::StringValue(value)
}

///|
fn theme_bool_value(value : Bool) -> @core.ThemeConfigValue {
  @core.ThemeConfigValue::BoolValue(value)
}

///|
fn theme_number_value(value : Int) -> @core.ThemeConfigValue {
  @core.ThemeConfigValue::NumberValue(value.to_string())
}

///|
fn theme_optional_string_value(value : String?) -> @core.ThemeConfigValue {
  match value {
    Some(text) => theme_string_value(text)
    None => @core.ThemeConfigValue::NullValue
  }
}

///|
fn theme_string_array_value(values : Array[String]) -> @core.ThemeConfigValue {
  let items : Array[@core.ThemeConfigValue] = []
  for value in values {
    items.push(theme_string_value(value))
  }
  theme_array_value(items)
}

///|
fn theme_array_value(
  values : Array[@core.ThemeConfigValue],
) -> @core.ThemeConfigValue {
  @core.ThemeConfigValue::ArrayValue(values)
}

///|
fn theme_object_value(
  values : Map[String, @core.ThemeConfigValue],
) -> @core.ThemeConfigValue {
  @core.ThemeConfigValue::ObjectValue(values)
}

///|
fn site_page_kind(page : @core.SitePage) -> String {
  if page.is_index {
    return "index"
  }
  match page.content_kind {
    @core.ContentKind::Article => "article"
    @core.ContentKind::Page => "page"
  }
}

///|
fn theme_navigation_kind(item : @core.NavigationItem) -> String {
  if item.is_index {
    return "index"
  }
  match item.content_kind {
    @core.ContentKind::Article => "article"
    @core.ContentKind::Page => "page"
  }
}

///|
fn theme_site_page_value(page : @core.SitePage) -> @core.ThemeConfigValue {
  let value : Map[String, @core.ThemeConfigValue] = {}
  value["kind"] = theme_string_value(site_page_kind(page))
  value["title"] = theme_string_value(page.title)
  value["nav_title"] = theme_string_value(page.nav_title)
  value["description"] = theme_string_value(page.description)
  value["summary"] = theme_string_value(page.summary)
  value["date"] = theme_optional_string_value(page.date)
  value["updated"] = theme_optional_string_value(page.updated)
  value["tags"] = theme_string_array_value(page.tags)
  value["series"] = theme_optional_string_value(page.series)
  value["cover"] = theme_optional_string_value(page.cover)
  value["author"] = theme_optional_string_value(page.author)
  value["column"] = theme_optional_string_value(page.column)
  value["reading_time"] = theme_number_value(page.reading_time_minutes)
  value["url"] = theme_string_value(page.url_path)
  value["url_path"] = theme_string_value(page.url_path)
  value["source_path"] = theme_string_value(page.source_path)
  value["nav_hidden"] = theme_bool_value(page.nav_hidden)
  value["is_index"] = theme_bool_value(page.is_index)
  theme_object_value(value)
}

///|
fn theme_page_link_value(link : @core.PageLink?) -> @core.ThemeConfigValue {
  match link {
    Some(page_link) => {
      let value : Map[String, @core.ThemeConfigValue] = {}
      value["title"] = theme_string_value(page_link.title)
      value["url"] = theme_string_value(page_link.url_path)
      value["url_path"] = theme_string_value(page_link.url_path)
      value["source_path"] = theme_string_value(page_link.source_path)
      theme_object_value(value)
    }
    None => theme_object_value({})
  }
}

///|
fn theme_heading_value(heading : @core.HeadingEntry) -> @core.ThemeConfigValue {
  let value : Map[String, @core.ThemeConfigValue] = {}
  value["level"] = theme_number_value(heading.level)
  value["id"] = theme_string_value(heading.id)
  value["title"] = theme_string_value(heading.title)
  theme_object_value(value)
}

///|
fn theme_backlink_entry_value(
  entry : @core.BacklinkEntry,
) -> @core.ThemeConfigValue {
  let value : Map[String, @core.ThemeConfigValue] = {}
  value["title"] = theme_string_value(entry.page.title)
  value["url"] = theme_string_value(entry.page.url_path)
  value["url_path"] = theme_string_value(entry.page.url_path)
  value["source_path"] = theme_string_value(entry.page.source_path)
  value["snippet"] = theme_string_value(entry.snippet)
  value["date"] = theme_optional_string_value(entry.date)
  value["series"] = theme_optional_string_value(entry.series)
  theme_object_value(value)
}

///|
fn theme_related_entry_value(
  entry : @core.RelatedEntry,
) -> @core.ThemeConfigValue {
  let value : Map[String, @core.ThemeConfigValue] = {}
  value["title"] = theme_string_value(entry.page.title)
  value["url"] = theme_string_value(entry.page.url_path)
  value["url_path"] = theme_string_value(entry.page.url_path)
  value["source_path"] = theme_string_value(entry.page.source_path)
  value["reason"] = theme_string_value(entry.reason)
  value["score"] = theme_number_value(entry.score)
  value["shared_tags"] = theme_string_array_value(entry.shared_tags)
  value["series"] = theme_optional_string_value(entry.series)
  value["date"] = theme_optional_string_value(entry.date)
  theme_object_value(value)
}

///|
fn theme_series_nav_value(series : @core.SeriesNav?) -> @core.ThemeConfigValue {
  match series {
    Some(series_nav) => {
      let items : Array[@core.ThemeConfigValue] = []
      for item in series_nav.items {
        items.push(theme_page_link_value(Some(item)))
      }
      let value : Map[String, @core.ThemeConfigValue] = {}
      value["name"] = theme_string_value(series_nav.name)
      value["previous"] = theme_page_link_value(series_nav.previous)
      value["next"] = theme_page_link_value(series_nav.next)
      value["items"] = theme_array_value(items)
      value["count"] = theme_number_value(series_nav.items.length())
      theme_object_value(value)
    }
    None => theme_object_value({})
  }
}

///|
fn theme_navigation_item_value(
  item : @core.NavigationItem,
  current_url : String,
) -> @core.ThemeConfigValue {
  let children : Array[@core.ThemeConfigValue] = []
  for child in item.children {
    children.push(theme_navigation_item_value(child, current_url))
  }
  let is_active = item.url_path == current_url
  let is_ancestor = !is_active && navigation_contains_url(item, current_url)
  let value : Map[String, @core.ThemeConfigValue] = {}
  value["kind"] = theme_string_value(theme_navigation_kind(item))
  value["title"] = theme_string_value(item.title)
  value["url"] = theme_string_value(item.url_path)
  value["url_path"] = theme_string_value(item.url_path)
  value["source_path"] = theme_string_value(item.source_path)
  value["is_index"] = theme_bool_value(item.is_index)
  value["active"] = theme_bool_value(is_active)
  value["ancestor"] = theme_bool_value(is_ancestor)
  value["expanded"] = theme_bool_value(is_active || is_ancestor)
  value["children"] = theme_array_value(children)
  theme_object_value(value)
}

///|
fn theme_collection_items_value(
  items : Array[@core.ThemeConfigValue],
) -> @core.ThemeConfigValue {
  let collection : Map[String, @core.ThemeConfigValue] = {}
  collection["count"] = theme_number_value(items.length())
  collection["items"] = theme_array_value(items)
  theme_object_value(collection)
}

///|
fn theme_section_item_value(section : @core.SitePage) -> @core.ThemeConfigValue {
  let value : Map[String, @core.ThemeConfigValue] = {}
  value["kind"] = theme_string_value("section")
  value["title"] = theme_string_value(section.nav_title)
  value["page_title"] = theme_string_value(section.title)
  value["url"] = theme_string_value(section.url_path)
  value["url_path"] = theme_string_value(section.url_path)
  value["source_path"] = theme_string_value(section.source_path)
  value["description"] = theme_string_value(section.description)
  theme_object_value(value)
}

///|
fn collect_theme_section_items(
  current_section : @core.SitePage?,
) -> Array[@core.ThemeConfigValue] {
  let sections : Array[@core.ThemeConfigValue] = []
  match current_section {
    Some(section) => sections.push(theme_section_item_value(section))
    None => ()
  }
  sections
}

///|
fn theme_override_keys(meta : @core.PageMeta) -> Array[String] {
  let keys : Array[String] = []
  match meta.layout_override {
    Some(_) => keys.push("layout")
    None => ()
  }
  for entry in meta.frontmatter.theme_meta {
    let (key, _) = entry
    keys.push(key)
  }
  keys.sort_by(fn(a, b) { a.compare(b) })
  keys
}

///|
fn invalid_theme_override_keys(
  meta : @core.PageMeta,
  allowed : Array[String],
) -> Array[String] {
  let invalid : Array[String] = []
  for key in theme_override_keys(meta) {
    if allowed.search_by(fn(allowed_key) { allowed_key == key }) is None {
      invalid.push(key)
    }
  }
  invalid
}

///|
fn format_theme_override_allowlist(allowed : Array[String]) -> String {
  if allowed.is_empty() {
    "(none)"
  } else {
    allowed.iter().join(", ")
  }
}

///|
fn missing_theme_layout_message(layout_key : String) -> String {
  "missing theme layout `" + layout_key + "`"
}

///|
fn resolve_theme_layout_source_for_key(
  bundle : @runtime.ActiveThemeBundle,
  layout_key : String,
) -> Result[String, String] {
  match bundle.layouts.get(layout_key) {
    Some(layout) => Ok(layout)
    None =>
      match bundle.layouts.get("page") {
        Some(layout) => Ok(layout)
        None => Err(layout_key)
      }
  }
}

///|
fn resolve_theme_layout_source(
  bundle : @runtime.ActiveThemeBundle,
  input : @runtime.BuildInput,
) -> Result[String, String] {
  let layout_key = @core.theme_page_layout_key(input.meta)
  match bundle.layouts.get(layout_key) {
    Some(layout) => Ok(layout)
    None => Err(layout_key)
  }
}

///|
fn generated_page_body_class(page : @core.GeneratedPage) -> String {
  "moonink-page moonink-generated moonink-" + page.kind
}

///|
fn render_generated_page_header_html(title : String) -> String {
  "<nav data-moonink-breadcrumb=\"auto\" aria-label=\"Breadcrumb\"><span aria-current=\"page\">" +
  escape_html_text(title) +
  "</span></nav>"
}

///|
fn build_generated_theme_render_context(
  config : @core.MooninkConfig,
  bundle : @runtime.ActiveThemeBundle,
  assembly : @core.SiteAssemblyModel,
  page_model : @core.GeneratedPage,
) -> @docflow.ThemeRenderContext {
  let nav_items : Array[@core.ThemeConfigValue] = []
  for item in assembly.navigation.items {
    nav_items.push(theme_navigation_item_value(item, page_model.url_path))
  }
  let page_items : Array[@core.ThemeConfigValue] = []
  for page in assembly.pages {
    page_items.push(theme_site_page_value(page))
  }

  let site : Map[String, @core.ThemeConfigValue] = {}
  site["name"] = theme_string_value(config.site_name)
  site["url"] = theme_string_value(configured_site_url(config))
  site["theme_name"] = theme_string_value(bundle.manifest.name)
  site["theme_asset_root"] = theme_string_value(theme_bundle_asset_root(bundle))
  site["theme_config"] = theme_object_value(config.theme_config)
  assign_public_surface_site_urls(site, config)

  let page : Map[String, @core.ThemeConfigValue] = {}
  page["kind"] = theme_string_value(page_model.kind)
  page["layout"] = theme_string_value(page_model.layout_key)
  page["title"] = theme_string_value(page_model.title)
  page["summary"] = theme_string_value(page_model.summary)
  page["description"] = theme_string_value(page_model.description)
  page["url"] = theme_string_value(page_model.url_path)
  page["url_path"] = theme_string_value(page_model.url_path)
  page["source_path"] = theme_string_value(page_model.source_path)
  page["body_class"] = theme_string_value(generated_page_body_class(page_model))
  page["body_html"] = theme_string_value(page_model.body_html)
  page["navigation_html"] = theme_string_value(
    render_navigation_html(assembly.navigation, page_model.url_path),
  )
  page["current_section_title"] = theme_string_value("")
  page["current_section_url"] = theme_string_value("")
  page["page_header_html"] = theme_string_value(
    render_generated_page_header_html(page_model.title),
  )
  page["homepage_hero_title"] = theme_string_value(page_model.title)
  page["homepage_hero_summary"] = theme_string_value(page_model.summary)

  let collections : Map[String, @core.ThemeConfigValue] = {}
  collections["nav"] = theme_collection_items_value(nav_items)
  collections["pages"] = theme_collection_items_value(page_items)
  collections["backlinks"] = theme_collection_items_value([])
  collections["related"] = theme_collection_items_value([])
  collections["toc"] = theme_collection_items_value([])
  collections["series"] = theme_collection_items_value([])
  collections["sections"] = theme_collection_items_value([])

  let navigation_html = render_navigation_html(
    assembly.navigation,
    page_model.url_path,
  )
  let slots : Map[String, @core.ThemeConfigValue] = {}
  slots["body_html"] = theme_string_value(page_model.body_html)
  slots["navigation_html"] = theme_string_value(navigation_html)
  slots["page_header_html"] = theme_string_value(
    render_generated_page_header_html(page_model.title),
  )
  slots["backlinks_html"] = theme_string_value("")
  slots["homepage_modules_html"] = theme_string_value("")
  assign_slot_html(
    slots,
    "head",
    render_head_meta_html(
      config,
      page_model.title,
      page_model.description,
      page_model.url_path,
      "website",
    ) +
    page_model.head_html,
  )
  assign_slot_html(slots, "scripts", page_model.scripts_html)
  apply_declared_slot_values(slots, bundle, config)

  { site, page, collections, slots, locals: {} }
}

///|
fn validate_check_theme_layouts(
  inputs : Array[@runtime.BuildInput],
  bundle : @runtime.ActiveThemeBundle,
  report : CheckReport,
) -> CheckReport {
  let allowed = bundle.manifest.page_overrides
  let mut next_report = report
  for input in inputs {
    if !invalid_theme_override_keys(input.meta, allowed).is_empty() {
      continue
    }
    match resolve_theme_layout_source(bundle, input) {
      Ok(_) => ()
      Err(layout_key) =>
        next_report = report_with_entry(next_report, {
          category: CheckCategory::ThemeTemplate,
          severity: CheckSeverity::Error,
          source_path: Some(input.meta.source_path),
          message: missing_theme_layout_message(layout_key),
          hint: Some("Declare `" + layout_key + "` in the theme layout map."),
          line: None,
        })
    }
  }
  next_report
}

///|
fn validate_check_theme_overrides(
  inputs : Array[@runtime.BuildInput],
  bundle : @runtime.ActiveThemeBundle,
  report : CheckReport,
) -> CheckReport {
  let allowed = bundle.manifest.page_overrides
  let mut next_report = report
  for input in inputs {
    for key in invalid_theme_override_keys(input.meta, allowed) {
      next_report = report_with_entry(next_report, {
        category: CheckCategory::ThemeTemplate,
        severity: CheckSeverity::Error,
        source_path: Some(input.meta.source_path),
        message: "unsupported page override `" + key + "`",
        hint: Some(
          "Allowed page overrides: " + format_theme_override_allowlist(allowed),
        ),
        line: None,
      })
    }
  }
  next_report
}

///|
fn validate_build_theme_overrides(
  inputs : Array[@runtime.BuildInput],
  bundle : @runtime.ActiveThemeBundle,
) -> Unit raise BuildCommandError {
  let allowed = bundle.manifest.page_overrides
  for input in inputs {
    for key in invalid_theme_override_keys(input.meta, allowed) {
      raise BuildCommandError::ProjectIO(
        @core.project_io_error(
          "validate_theme_overrides",
          input.meta.source_path,
          "unsupported page override `" +
          key +
          "`; allowed page overrides: " +
          format_theme_override_allowlist(allowed),
        ),
      )
    }
  }
}

///|
fn page_body_class(meta : @core.PageMeta) -> String {
  if @core.theme_page_kind(meta) == "article" {
    "moonink-article"
  } else {
    "moonink-page"
  }
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
  let basename = basename_without_extension(page.source_path)
  if page.is_index || basename == "README" {
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
    title: page.nav_title,
    url_path: page.url_path,
    source_path: page.source_path,
    content_kind: page.content_kind,
    children: find_navigation_children(pages, navigation_node_key(page)),
    is_index: page.is_index,
  }
}

///|
fn has_navigation_node_key(pages : Array[@core.SitePage], key : String) -> Bool {
  for page in pages {
    if navigation_node_key(page) == key {
      return true
    }
  }
  false
}

///|
pub fn build_navigation_model(
  pages : Array[@core.SitePage],
) -> @core.NavigationModel {
  let nav_pages : Array[@core.SitePage] = []
  for page in pages {
    if !page.nav_hidden {
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
      Some(parent) if !has_navigation_node_key(nav_pages, parent) =>
        items.push(build_navigation_item(nav_pages, page))
      _ => ()
    }
  }
  {
    items,
    total_items: nav_pages.length(),
    note: "Navigation model groups page and article content by source path hierarchy.",
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
    let is_expanded = is_active || is_ancestor
    let current_attr = if is_active {
      "page"
    } else if is_ancestor {
      "ancestor"
    } else {
      "false"
    }
    let active_attr = navigation_bool_attr(is_active)
    let ancestor_attr = navigation_bool_attr(is_ancestor)
    let index_attr = navigation_bool_attr(item.is_index)
    let expanded_attr = navigation_bool_attr(is_expanded)
    html = html +
      "<li data-active=\"" +
      active_attr +
      "\" data-ancestor=\"" +
      ancestor_attr +
      "\" data-index=\"" +
      index_attr +
      "\" data-expanded=\"" +
      expanded_attr +
      "\" data-current=\"" +
      current_attr +
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
fn find_section_page_by_key(
  pages : Array[@core.SitePage],
  key : String,
) -> @core.SitePage? {
  for page in pages {
    if page.is_index && navigation_node_key(page) == key {
      return Some(page)
    }
  }
  None
}

///|
fn source_directory_segments(source_path : String) -> Array[String] {
  let stripped = strip_link_target_extension(source_path)
  let segments = stripped.split("/").map(StringView::to_string).collect()
  let directories : Array[String] = []
  if segments.length() <= 1 {
    return directories
  }
  for i in 0..<(segments.length() - 1) {
    directories.push(segments[i])
  }
  directories
}

///|
fn find_current_section_page(
  pages : Array[@core.SitePage],
  meta : @core.PageMeta,
) -> @core.SitePage? {
  let directories = source_directory_segments(meta.source_path)
  if meta.is_index {
    let self_key = if directories.is_empty() {
      ""
    } else {
      directories.iter().join("/")
    }
    match find_section_page_by_key(pages, self_key) {
      Some(page) => return Some(page)
      None => ()
    }
  }
  let mut count = directories.length()
  while count > 0 {
    let prefix : Array[String] = []
    for i in 0..<count {
      prefix.push(directories[i])
    }
    let key = prefix.iter().join("/")
    match find_section_page_by_key(pages, key) {
      Some(page) => return Some(page)
      None => ()
    }
    count = count - 1
  }
  None
}

///|
fn render_page_header_title(title : String) -> String {
  if title == "" {
    return ""
  }
  "<nav data-moonink-breadcrumb=\"auto\" aria-label=\"Breadcrumb\"><span aria-current=\"page\">" +
  escape_html_text(title) +
  "</span></nav>"
}

///|
fn build_page_header_html(
  _navigation : @core.NavigationModel,
  _pages : Array[@core.SitePage],
  input : @runtime.BuildInput,
) -> String {
  render_page_header_title(site_page_title(input.meta))
}

///|
pub fn site_page_title(meta : @core.PageMeta) -> String {
  if meta.resolved_title != "" {
    return meta.resolved_title
  }
  match meta.frontmatter.title {
    Some(title) => title
    None =>
      if meta.is_index {
        "Home"
      } else {
        basename_without_extension(meta.source_path)
      }
  }
}

///|
pub fn site_page_nav_title(meta : @core.PageMeta) -> String {
  match meta.frontmatter.extra.get("nav_title") {
    Some(title) if title != "" => title
    _ => site_page_title(meta)
  }
}

///|
pub fn site_page_nav_hidden(meta : @core.PageMeta) -> Bool {
  match meta.frontmatter.extra.get("nav_hidden") {
    Some("true") => true
    _ => false
  }
}

///|
fn normalized_optional_text(value : String?) -> String? {
  match value {
    Some(text) => {
      let normalized = @core.normalize_inline_text(text)
      if normalized.is_empty() {
        None
      } else {
        Some(normalized)
      }
    }
    None => None
  }
}

///|
fn clip_summary(source : String, max_length : Int) -> String {
  if source.length() <= max_length {
    return source
  }
  let mut end = max_length
  while end > 0 && source[end - 1:end].to_string() != " " {
    end -= 1
  }
  let clipped = if end <= 0 {
    source[:max_length].to_string()
  } else {
    source[:end].to_string().trim().to_string()
  }
  if clipped.is_empty() {
    source[:max_length].to_string()
  } else {
    clipped + "..."
  }
}

///|
fn site_page_summary(input : @runtime.BuildInput) -> String {
  match normalized_optional_text(input.meta.frontmatter.summary) {
    Some(summary) => summary
    None =>
      match normalized_optional_text(input.meta.frontmatter.description) {
        Some(description) => description
        None => {
          let text = @core.source_plain_text(
            input.docflow_content,
            input.meta.format,
          )
          if text.is_empty() {
            ""
          } else {
            clip_summary(text, 220)
          }
        }
      }
  }
}

///|
pub fn site_page_description(meta : @core.PageMeta) -> String {
  match normalized_optional_text(meta.frontmatter.description) {
    Some(description) => description
    None =>
      match normalized_optional_text(meta.frontmatter.summary) {
        Some(summary) => summary
        None => ""
      }
  }
}

///|
fn normalized_cover_url(value : String?) -> String? {
  match value {
    Some(path) => {
      let trimmed = path.trim().to_string()
      if trimmed.is_empty() {
        None
      } else if trimmed.has_prefix("http://") ||
        trimmed.has_prefix("https://") ||
        trimmed.has_prefix("/") {
        Some(trimmed)
      } else if trimmed.has_prefix("./") {
        Some("/" + trimmed[2:trimmed.length()].to_string())
      } else {
        Some("/" + trimmed)
      }
    }
    None => None
  }
}

///|
fn site_page_link(page : @core.SitePage) -> @core.PageLink {
  { title: page.title, url_path: page.url_path, source_path: page.source_path }
}

///|
fn build_site_page(input : @runtime.BuildInput) -> @core.SitePage {
  {
    title: site_page_title(input.meta),
    nav_title: site_page_nav_title(input.meta),
    nav_hidden: site_page_nav_hidden(input.meta),
    description: site_page_description(input.meta),
    summary: site_page_summary(input),
    date: normalized_optional_text(input.meta.frontmatter.date),
    updated: normalized_optional_text(input.meta.frontmatter.updated),
    tags: input.meta.frontmatter.tags,
    series: normalized_optional_text(input.meta.frontmatter.series),
    cover: normalized_cover_url(input.meta.frontmatter.cover),
    author: normalized_optional_text(input.meta.frontmatter.author),
    column: normalized_optional_text(input.meta.frontmatter.column),
    reading_time_minutes: @core.estimate_reading_time_minutes(
      input.docflow_content,
      input.meta.format,
    ),
    source_format: input.meta.format,
    source_path: input.meta.source_path,
    url_path: input.meta.url_path,
    content_kind: input.meta.content_kind,
    is_index: input.meta.is_index,
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
fn backlink_scan_document(
  input : @runtime.BuildInput,
) -> @docflow.ParsedDocument {
  {
    backend_name: "backlink-scan",
    source_format: input.meta.format,
    source_path: input.meta.source_path,
    source_uuid: input.meta.source_path,
    diagnostics: @docflow.empty_document_diagnostics(),
    backend_payload: Some(input.docflow_content),
  }
}

///|
fn pages_by_url(pages : Array[@core.SitePage]) -> Map[String, @core.SitePage] {
  let indexed : Map[String, @core.SitePage] = {}
  for page in pages {
    indexed[page.url_path] = page
  }
  indexed
}

///|
fn compare_optional_dates_desc(left : String?, right : String?) -> Int {
  match left {
    Some(left_date) =>
      match right {
        Some(right_date) => right_date.compare(left_date)
        None => -1
      }
    None =>
      match right {
        Some(_) => 1
        None => 0
      }
  }
}

///|
fn compare_optional_dates_asc(left : String?, right : String?) -> Int {
  match left {
    Some(left_date) =>
      match right {
        Some(right_date) => left_date.compare(right_date)
        None => -1
      }
    None =>
      match right {
        Some(_) => 1
        None => 0
      }
  }
}

///|
fn compare_site_pages_by_recency(
  left : @core.SitePage,
  right : @core.SitePage,
) -> Int {
  let date_compare = compare_optional_dates_desc(left.date, right.date)
  if date_compare != 0 {
    return date_compare
  }
  left.source_path.compare(right.source_path)
}

///|
fn compare_site_pages_by_series_order(
  left : @core.SitePage,
  right : @core.SitePage,
) -> Int {
  let date_compare = compare_optional_dates_asc(left.date, right.date)
  if date_compare != 0 {
    return date_compare
  }
  left.source_path.compare(right.source_path)
}

///|
fn compare_backlink_entries(
  left : @core.BacklinkEntry,
  right : @core.BacklinkEntry,
) -> Int {
  let date_compare = compare_optional_dates_desc(left.date, right.date)
  if date_compare != 0 {
    return date_compare
  }
  left.page.source_path.compare(right.page.source_path)
}

///|
fn compare_related_entries(
  left : @core.RelatedEntry,
  right : @core.RelatedEntry,
) -> Int {
  if left.score != right.score {
    return right.score - left.score
  }
  let date_compare = compare_optional_dates_desc(left.date, right.date)
  if date_compare != 0 {
    return date_compare
  }
  left.page.source_path.compare(right.page.source_path)
}

///|
fn contains_url(urls : Array[String], target : String) -> Bool {
  urls.search_by(fn(url) { url == target }) is Some(_)
}

///|
fn dedupe_urls(urls : Array[String]) -> Array[String] {
  let deduped : Array[String] = []
  for url in urls {
    if !contains_url(deduped, url) {
      deduped.push(url)
    }
  }
  deduped
}

///|
fn shared_tags(left : Array[String], right : Array[String]) -> Array[String] {
  let shared : Array[String] = []
  for tag in left {
    if right.search_by(fn(candidate) { candidate == tag }) is Some(_) &&
      shared.search_by(fn(existing) { existing == tag }) is None {
      shared.push(tag)
    }
  }
  shared
}

///|
fn article_pages_only(pages : Array[@core.SitePage]) -> Array[@core.SitePage] {
  let filtered : Array[@core.SitePage] = []
  for page in pages {
    if page.content_kind == @core.ContentKind::Article && !page.is_index {
      filtered.push(page)
    }
  }
  filtered
}

///|
fn build_toc_by_url(
  inputs : Array[@runtime.BuildInput],
) -> Map[String, Array[@core.HeadingEntry]] {
  let toc : Map[String, Array[@core.HeadingEntry]] = {}
  for input in inputs {
    if input.meta.format != @core.SourceFormat::Markdown {
      continue
    }
    let headings : Array[@core.HeadingEntry] = []
    for heading in @docflow.collect_markdown_headings(input.docflow_content) {
      if heading.level > 1 {
        headings.push(heading)
      }
    }
    if !headings.is_empty() {
      toc[input.meta.url_path] = headings
    }
  }
  toc
}

///|
fn build_outbound_links_by_url(
  inputs : Array[@runtime.BuildInput],
  wikilinker : @docflow.WikiLinker,
) -> Map[String, Array[String]] {
  let outbound : Map[String, Array[String]] = {}
  for input in inputs {
    if input.meta.format != @core.SourceFormat::Markdown {
      outbound[input.meta.url_path] = []
      continue
    }
    let targets = @docflow.collect_resolved_wikilink_targets(
      wikilinker,
      backlink_scan_document(input),
    )
    outbound[input.meta.url_path] = dedupe_urls(targets)
  }
  outbound
}

///|
fn build_backlink_entries_by_url(
  inputs : Array[@runtime.BuildInput],
  pages : Array[@core.SitePage],
  wikilinker : @docflow.WikiLinker,
) -> Map[String, Array[@core.BacklinkEntry]] {
  let page_index = pages_by_url(pages)
  let collected : Map[String, Array[@core.BacklinkEntry]] = {}
  for input in inputs {
    if input.meta.format != @core.SourceFormat::Markdown {
      continue
    }
    let source_page = match page_index.get(input.meta.url_path) {
      Some(page) => page
      None => continue
    }
    for
      mention in @docflow.collect_resolved_wikilink_mentions(
        wikilinker,
        backlink_scan_document(input),
      ) {
      if mention.target_url == source_page.url_path {
        continue
      }
      let existing = match collected.get(mention.target_url) {
        Some(entries) => entries
        None => []
      }
      let already_present = existing.search_by(fn(entry) {
          entry.page.url_path == source_page.url_path
        })
        is Some(_)
      if already_present {
        continue
      }
      collected[mention.target_url] = existing +
        [
          {
            page: site_page_link(source_page),
            snippet: mention.snippet,
            date: source_page.date,
            series: source_page.series,
          },
        ]
    }
  }
  let sorted : Map[String, Array[@core.BacklinkEntry]] = {}
  for entry in collected {
    let (url, backlinks) = entry
    backlinks.sort_by(compare_backlink_entries)
    sorted[url] = backlinks
  }
  sorted
}

///|
fn build_article_prev_next(
  pages : Array[@core.SitePage],
) -> (Map[String, @core.PageLink], Map[String, @core.PageLink]) {
  let articles = article_pages_only(pages)
  articles.sort_by(compare_site_pages_by_recency)
  let previous : Map[String, @core.PageLink] = {}
  let next : Map[String, @core.PageLink] = {}
  for index in 0..<articles.length() {
    let current = articles[index]
    if index > 0 {
      previous[current.url_path] = site_page_link(articles[index - 1])
    }
    if index + 1 < articles.length() {
      next[current.url_path] = site_page_link(articles[index + 1])
    }
  }
  (previous, next)
}

///|
fn build_series_nav_by_url(
  pages : Array[@core.SitePage],
) -> Map[String, @core.SeriesNav] {
  let grouped : Map[String, Array[@core.SitePage]] = {}
  for page in article_pages_only(pages) {
    match page.series {
      Some(series_name) => {
        let existing = match grouped.get(series_name) {
          Some(items) => items
          None => []
        }
        grouped[series_name] = existing + [page]
      }
      None => ()
    }
  }
  let navigation : Map[String, @core.SeriesNav] = {}
  for entry in grouped {
    let (series_name, items) = entry
    items.sort_by(compare_site_pages_by_series_order)
    let page_links : Array[@core.PageLink] = []
    for item in items {
      page_links.push(site_page_link(item))
    }
    for index in 0..<items.length() {
      let previous = if index > 0 {
        Some(site_page_link(items[index - 1]))
      } else {
        None
      }
      let next = if index + 1 < items.length() {
        Some(site_page_link(items[index + 1]))
      } else {
        None
      }
      navigation[items[index].url_path] = {
        name: series_name,
        previous,
        next,
        items: page_links,
      }
    }
  }
  navigation
}

///|
fn relationship_reason(
  direct_link : Bool,
  reverse_link : Bool,
  shared_tags : Array[String],
  same_series : Bool,
) -> String {
  let reasons : Array[String] = []
  if same_series {
    reasons.push("Same series")
  }
  if direct_link && reverse_link {
    reasons.push("Links both ways")
  } else if direct_link || reverse_link {
    reasons.push("Directly linked")
  }
  if !shared_tags.is_empty() {
    reasons.push("Shared tags: " + shared_tags.iter().join(", "))
  }
  reasons.iter().join(" · ")
}

///|
fn relationship_score(
  direct_link : Bool,
  reverse_link : Bool,
  shared_tags : Array[String],
  same_series : Bool,
) -> Int {
  let link_score = if direct_link && reverse_link {
    8
  } else if direct_link || reverse_link {
    5
  } else {
    0
  }
  let tag_score = shared_tags.length() * 3
  let series_score = if same_series { 7 } else { 0 }
  link_score + tag_score + series_score
}

///|
fn build_related_entries_by_url(
  pages : Array[@core.SitePage],
  outbound : Map[String, Array[String]],
) -> Map[String, Array[@core.RelatedEntry]] {
  let related : Map[String, Array[@core.RelatedEntry]] = {}
  let articles = article_pages_only(pages)
  for current in articles {
    let current_outbound = match outbound.get(current.url_path) {
      Some(urls) => urls
      None => []
    }
    let entries : Array[@core.RelatedEntry] = []
    for candidate in articles {
      if candidate.url_path == current.url_path || candidate.is_index {
        continue
      }
      let candidate_outbound = match outbound.get(candidate.url_path) {
        Some(urls) => urls
        None => []
      }
      let tags = shared_tags(current.tags, candidate.tags)
      let same_series = match current.series {
        Some(series_name) =>
          match candidate.series {
            Some(candidate_series) => candidate_series == series_name
            None => false
          }
        None => false
      }
      let direct_link = contains_url(current_outbound, candidate.url_path)
      let reverse_link = contains_url(candidate_outbound, current.url_path)
      let score = relationship_score(
        direct_link, reverse_link, tags, same_series,
      )
      if score <= 0 {
        continue
      }
      entries.push({
        page: site_page_link(candidate),
        reason: relationship_reason(
          direct_link, reverse_link, tags, same_series,
        ),
        score,
        shared_tags: tags,
        series: candidate.series,
        date: candidate.date,
      })
    }
    entries.sort_by(compare_related_entries)
    related[current.url_path] = if entries.length() > 4 {
      entries[:4].to_array()
    } else {
      entries
    }
  }
  related
}

///|
fn build_article_experience_model(
  inputs : Array[@runtime.BuildInput],
  pages : Array[@core.SitePage],
  wikilinker : @docflow.WikiLinker,
) -> ArticleExperienceModel {
  let toc = build_toc_by_url(inputs)
  let backlinks = build_backlink_entries_by_url(inputs, pages, wikilinker)
  let outbound = build_outbound_links_by_url(inputs, wikilinker)
  let related = build_related_entries_by_url(pages, outbound)
  let (previous, next) = build_article_prev_next(pages)
  let series = build_series_nav_by_url(pages)
  { toc, backlinks, related, previous, next, series }
}

///|
fn build_search_index_item(
  input : @runtime.BuildInput,
) -> @core.SearchIndexItem {
  let frontmatter = input.meta.frontmatter
  let excerpt = match frontmatter.extra.get("excerpt") {
    Some(value) => Some(value)
    None => frontmatter.summary
  }
  {
    title: site_page_title(input.meta),
    url: input.meta.url_path,
    kind: if input.meta.is_index {
      "index"
    } else {
      template_content_kind(input.meta.content_kind)
    },
    summary: normalized_optional_text(frontmatter.summary),
    excerpt: @core.search_index_excerpt(
      excerpt,
      input.docflow_content,
      input.meta.format,
    ),
    tags: frontmatter.tags,
    date: normalized_optional_text(frontmatter.date),
  }
}

///|
fn build_search_index_document(
  inputs : Array[@runtime.BuildInput],
) -> @core.SearchIndexDocument {
  let items : Array[@core.SearchIndexItem] = []
  for input in inputs {
    if !input.meta.frontmatter.search_enabled {
      continue
    }
    items.push(build_search_index_item(input))
  }
  { version: 1, generated_at: @runtime.current_utc_iso8601_second(), items }
}

///|
fn write_search_index_output(
  config : @core.MooninkConfig,
  inputs : Array[@runtime.BuildInput],
) -> Unit raise BuildCommandError {
  let document = build_search_index_document(inputs)
  let json = @core.search_index_document_to_json(document)
  write_build_output(config, "search-index.json", json)
}

///|
fn find_page_by_url(
  pages : Array[@core.SitePage],
  url_path : String,
) -> @core.SitePage? {
  for page in pages {
    if page.url_path == url_path {
      return Some(page)
    }
  }
  None
}

///|
fn experience_backlinks_for_url(
  experience : ArticleExperienceModel,
  url_path : String,
) -> Array[@core.BacklinkEntry] {
  match experience.backlinks.get(url_path) {
    Some(entries) => entries
    None => []
  }
}

///|
fn experience_related_for_url(
  experience : ArticleExperienceModel,
  url_path : String,
) -> Array[@core.RelatedEntry] {
  match experience.related.get(url_path) {
    Some(entries) => entries
    None => []
  }
}

///|
fn experience_toc_for_url(
  experience : ArticleExperienceModel,
  url_path : String,
) -> Array[@core.HeadingEntry] {
  match experience.toc.get(url_path) {
    Some(entries) => entries
    None => []
  }
}

///|
fn reading_time_label(minutes : Int) -> String {
  minutes.to_string() + " min read"
}

///|
fn build_template_context(
  config : @core.MooninkConfig,
  active_theme : @runtime.ActiveThemeLayout,
  assembly : @core.SiteAssemblyModel,
  experience : ArticleExperienceModel,
  input : @runtime.BuildInput,
  rendered : @docflow.RenderedDocument,
) -> @docflow.TemplateContext {
  let backlinks = experience_backlinks_for_url(experience, input.meta.url_path)
  let current_section = find_current_section_page(assembly.pages, input.meta)
  let current_section_title = match current_section {
    Some(section) => section.nav_title
    None => ""
  }
  let current_section_url = match current_section {
    Some(section) => section.url_path
    None => ""
  }
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
    theme_name: theme_name(active_theme),
    theme_asset_root: theme_asset_root(active_theme),
    page_body_class: page_body_class(input.meta),
    navigation_html: render_navigation_html(
      assembly.navigation,
      input.meta.url_path,
    ),
    backlink_urls: backlinks.map(fn(entry) { entry.page.url_path }),
    current_section_title,
    current_section_url,
    page_header_title: site_page_title(input.meta),
    page_header_html: build_page_header_html(
      assembly.navigation,
      assembly.pages,
      input,
    ),
    backlinks_html: render_backlinks_html(backlinks),
    body_html: rendered.html,
  }
}

///|
fn apply_build_template(
  config : @core.MooninkConfig,
  active_theme : @runtime.ActiveThemeLayout,
  assembly : @core.SiteAssemblyModel,
  experience : ArticleExperienceModel,
  input : @runtime.BuildInput,
  rendered : @docflow.RenderedDocument,
  template_source : String,
) -> @docflow.TemplatedPage {
  let context = build_template_context(
    config, active_theme, assembly, experience, input, rendered,
  )
  @docflow.apply_template(rendered, context, template_source)
}

///|
fn theme_bundle_manifest_path(
  config : @core.MooninkConfig,
) -> String raise BuildCommandError {
  let theme_dir = match config.theme {
    Some(path) => path
    None => "theme"
  }
  let manifest_path = @core.join_relative_path(theme_dir, "theme.json") catch {
    err =>
      raise BuildCommandError::ProjectIO(
        @core.project_io_error(
          "load_theme_bundle",
          config.config_path,
          @core.format_path_policy_error(err),
        ),
      )
  }
  @core.join_relative_path(config.project_root, manifest_path) catch {
    err =>
      raise BuildCommandError::ProjectIO(
        @core.project_io_error(
          "load_theme_bundle",
          config.config_path,
          @core.format_path_policy_error(err),
        ),
      )
  }
}

///|
fn has_project_theme_bundle(
  config : @core.MooninkConfig,
) -> Bool raise BuildCommandError {
  let manifest_path = theme_bundle_manifest_path(config) catch {
    err => raise err
  }
  @runtime.io_path_exists(manifest_path)
}

///|
fn project_legacy_theme_layout_path(
  config : @core.MooninkConfig,
) -> String raise BuildCommandError {
  let theme_dir = match config.theme {
    Some(path) => path
    None => "theme"
  }
  let layout_path = @core.join_relative_path(theme_dir, "layout.html") catch {
    err =>
      raise BuildCommandError::ProjectIO(
        @core.project_io_error(
          "load_template",
          config.config_path,
          @core.format_path_policy_error(err),
        ),
      )
  }
  @core.join_relative_path(config.project_root, layout_path) catch {
    err =>
      raise BuildCommandError::ProjectIO(
        @core.project_io_error(
          "load_template",
          config.config_path,
          @core.format_path_policy_error(err),
        ),
      )
  }
}

///|
fn should_use_legacy_active_theme(
  config : @core.MooninkConfig,
) -> Bool raise BuildCommandError {
  let legacy_layout_path = project_legacy_theme_layout_path(config) catch {
    err => raise err
  }
  if @runtime.io_path_exists(legacy_layout_path) {
    return true
  }
  match config.template_file {
    Some(_) => true
    None => false
  }
}

///|
fn resolve_active_theme_bundle(
  config : @core.MooninkConfig,
) -> Result[@runtime.ActiveThemeBundle?, BuildCommandError] {
  let has_bundle = has_project_theme_bundle(config) catch {
    err => return Err(err)
  }
  if !has_bundle {
    let use_legacy = should_use_legacy_active_theme(config) catch {
      err => return Err(err)
    }
    if use_legacy {
      return Ok(None)
    }
  }
  match @runtime.load_active_theme_bundle_result(config) {
    Ok(bundle) => Ok(Some(bundle))
    Err(err) =>
      Err(
        BuildCommandError::ProjectIO(
          @core.project_io_error(
            "load_theme_bundle",
            config.config_path,
            err.to_string(),
          ),
        ),
      )
  }
}

///|
fn copy_theme_bundle_assets(
  config : @core.MooninkConfig,
  bundle : @runtime.ActiveThemeBundle,
) -> Unit raise BuildCommandError {
  match bundle.assets_root {
    Some(path) => copy_assets_dir(config, path)
    None => ()
  }
}

///|
fn select_theme_layout(
  bundle : @runtime.ActiveThemeBundle,
  input : @runtime.BuildInput,
) -> String raise BuildCommandError {
  match resolve_theme_layout_source(bundle, input) {
    Ok(layout) => layout
    Err(layout_key) =>
      raise BuildCommandError::ProjectIO(
        @core.project_io_error(
          "load_layout",
          layout_key,
          missing_theme_layout_message(layout_key),
        ),
      )
  }
}

///|
fn build_theme_render_context(
  config : @core.MooninkConfig,
  bundle : @runtime.ActiveThemeBundle,
  assembly : @core.SiteAssemblyModel,
  experience : ArticleExperienceModel,
  input : @runtime.BuildInput,
  rendered : @docflow.RenderedDocument,
) -> @docflow.ThemeRenderContext raise BuildCommandError {
  let page_model = @core.page_view_model_from_meta(input.meta)
  let current_page = match
    find_page_by_url(assembly.pages, input.meta.url_path) {
    Some(page) => page
    None => build_site_page(input)
  }
  let current_section = find_current_section_page(assembly.pages, input.meta)
  let current_section_title = match current_section {
    Some(section) => section.nav_title
    None => ""
  }
  let current_section_url = match current_section {
    Some(section) => section.url_path
    None => ""
  }
  let section_items = collect_theme_section_items(current_section)
  let navigation_html = render_navigation_html(
    assembly.navigation,
    input.meta.url_path,
  )
  let page_header_html = build_page_header_html(
    assembly.navigation,
    assembly.pages,
    input,
  )
  let backlink_entries = experience_backlinks_for_url(
    experience,
    input.meta.url_path,
  )
  let related_entries = experience_related_for_url(
    experience,
    input.meta.url_path,
  )
  let toc_entries = experience_toc_for_url(experience, input.meta.url_path)
  let backlinks_html = render_backlinks_html(backlink_entries)

  let nav_items : Array[@core.ThemeConfigValue] = []
  for item in assembly.navigation.items {
    nav_items.push(theme_navigation_item_value(item, input.meta.url_path))
  }
  let page_items : Array[@core.ThemeConfigValue] = []
  for page in assembly.pages {
    page_items.push(theme_site_page_value(page))
  }
  let backlink_items : Array[@core.ThemeConfigValue] = []
  for backlink in backlink_entries {
    backlink_items.push(theme_backlink_entry_value(backlink))
  }
  let related_items : Array[@core.ThemeConfigValue] = []
  for related in related_entries {
    related_items.push(theme_related_entry_value(related))
  }
  let toc_items : Array[@core.ThemeConfigValue] = []
  for heading in toc_entries {
    toc_items.push(theme_heading_value(heading))
  }
  let previous_link = experience.previous.get(input.meta.url_path)
  let next_link = experience.next.get(input.meta.url_path)
  let series_nav = experience.series.get(input.meta.url_path)
  let homepage_modules_html = if input.meta.url_path == "/" {
    render_homepage_modules_html(config, assembly.pages) catch {
      err => raise err
    }
  } else {
    ""
  }
  let homepage_title = if input.meta.url_path == "/" {
    homepage_hero_title(config, current_page)
  } else {
    current_page.title
  }
  let homepage_summary = if input.meta.url_path == "/" {
    homepage_hero_summary(config, current_page)
  } else {
    current_page.summary
  }
  let series_items : Array[@core.ThemeConfigValue] = []
  match series_nav {
    Some(nav) =>
      for item in nav.items {
        series_items.push(theme_page_link_value(Some(item)))
      }
    None => ()
  }

  let site : Map[String, @core.ThemeConfigValue] = {}
  site["name"] = theme_string_value(config.site_name)
  site["url"] = theme_string_value(configured_site_url(config))
  site["theme_name"] = theme_string_value(bundle.manifest.name)
  site["theme_asset_root"] = theme_string_value(theme_bundle_asset_root(bundle))
  site["theme_config"] = theme_object_value(config.theme_config)
  assign_public_surface_site_urls(site, config)

  let page : Map[String, @core.ThemeConfigValue] = {}
  page["kind"] = theme_string_value(page_model.kind)
  page["layout"] = theme_string_value(page_model.layout)
  page["title"] = theme_string_value(current_page.title)
  page["nav_title"] = theme_string_value(current_page.nav_title)
  page["description"] = theme_string_value(current_page.description)
  page["summary"] = theme_string_value(current_page.summary)
  page["date"] = theme_optional_string_value(current_page.date)
  page["updated"] = theme_optional_string_value(current_page.updated)
  page["tags"] = theme_string_array_value(current_page.tags)
  page["series"] = theme_optional_string_value(current_page.series)
  page["cover"] = theme_optional_string_value(current_page.cover)
  page["cover_url"] = theme_optional_string_value(current_page.cover)
  page["author"] = theme_optional_string_value(current_page.author)
  page["author_display"] = theme_string_value(
    match current_page.author {
      Some(author) => author
      None => config.site_name
    },
  )
  page["column"] = theme_optional_string_value(current_page.column)
  page["reading_time"] = theme_number_value(current_page.reading_time_minutes)
  page["reading_time_label"] = theme_string_value(
    reading_time_label(current_page.reading_time_minutes),
  )
  page["url"] = theme_string_value(input.meta.url_path)
  page["url_path"] = theme_string_value(input.meta.url_path)
  page["source_path"] = theme_string_value(input.meta.source_path)
  page["body_class"] = theme_string_value(page_body_class(input.meta))
  page["body_html"] = theme_string_value(rendered.html)
  page["source_format"] = theme_string_value(
    current_page.source_format.to_string(),
  )
  page["theme_meta"] = theme_object_value(page_model.theme_meta)
  page["navigation_html"] = theme_string_value(navigation_html)
  page["current_section_title"] = theme_string_value(current_section_title)
  page["current_section_url"] = theme_string_value(current_section_url)
  page["page_header_html"] = theme_string_value(page_header_html)
  page["backlinks_html"] = theme_string_value(backlinks_html)
  page["has_backlinks"] = theme_bool_value(!backlink_entries.is_empty())
  page["has_related"] = theme_bool_value(!related_entries.is_empty())
  page["has_toc"] = theme_bool_value(!toc_entries.is_empty())
  page["previous"] = theme_page_link_value(previous_link)
  page["next"] = theme_page_link_value(next_link)
  page["has_neighbors"] = theme_bool_value(
    previous_link is Some(_) || next_link is Some(_),
  )
  page["series_nav"] = theme_series_nav_value(series_nav)
  page["homepage_hero_title"] = theme_string_value(homepage_title)
  page["homepage_hero_summary"] = theme_string_value(homepage_summary)

  let collections : Map[String, @core.ThemeConfigValue] = {}
  collections["nav"] = theme_collection_items_value(nav_items)
  collections["pages"] = theme_collection_items_value(page_items)
  collections["backlinks"] = theme_collection_items_value(backlink_items)
  collections["related"] = theme_collection_items_value(related_items)
  collections["toc"] = theme_collection_items_value(toc_items)
  collections["series"] = theme_collection_items_value(series_items)
  collections["sections"] = theme_collection_items_value(section_items)

  let slots : Map[String, @core.ThemeConfigValue] = {}
  slots["body_html"] = theme_string_value(rendered.html)
  slots["navigation_html"] = theme_string_value(navigation_html)
  slots["page_header_html"] = theme_string_value(page_header_html)
  slots["backlinks_html"] = theme_string_value(backlinks_html)
  slots["homepage_modules_html"] = theme_string_value(homepage_modules_html)
  assign_slot_html(
    slots,
    "head",
    render_head_meta_html(
      config,
      current_page.title,
      page_head_description(current_page),
      input.meta.url_path,
      content_og_type(input.meta.content_kind),
    ),
  )
  apply_declared_slot_values(slots, bundle, config)

  { site, page, collections, slots, locals: {} }
}

///|
fn apply_build_theme_template(
  config : @core.MooninkConfig,
  bundle : @runtime.ActiveThemeBundle,
  assembly : @core.SiteAssemblyModel,
  experience : ArticleExperienceModel,
  input : @runtime.BuildInput,
  rendered : @docflow.RenderedDocument,
) -> @docflow.TemplatedPage raise BuildCommandError {
  let layout_source = select_theme_layout(bundle, input) catch {
    err => raise err
  }
  let context = build_theme_render_context(
    config, bundle, assembly, experience, input, rendered,
  ) catch {
    err => raise err
  }
  {
    route: input.meta.url_path,
    source_path: rendered.source_path,
    source_uuid: rendered.source_uuid,
    html: @docflow.render_theme_template(
      layout_source,
      context,
      bundle.partials,
    ),
    note: "theme v2 templater renders the selected layout with structured site and page context",
  }
}

///|
fn resolve_active_theme_layout(
  config : @core.MooninkConfig,
) -> Result[@runtime.ActiveThemeLayout, BuildCommandError] {
  match @runtime.load_active_theme_layout_result(config) {
    Ok(layout) => Ok(layout)
    Err(err) =>
      Err(
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
}

///|
fn validate_check_active_theme_bundle(
  config : @core.MooninkConfig,
  inputs : Array[@runtime.BuildInput],
  report : CheckReport,
) -> CheckReport {
  match @runtime.load_active_theme_bundle_result(config) {
    Ok(bundle) => {
      let report = validate_check_theme_layouts(inputs, bundle, report)
      validate_check_theme_overrides(inputs, bundle, report)
    }
    Err(err) => {
      let source_path = theme_bundle_manifest_path(config) catch {
        _ => config.config_path
      }
      report_with_entry(report, {
        category: CheckCategory::ThemeTemplate,
        severity: CheckSeverity::Error,
        source_path: Some(source_path),
        message: "Failed to load active theme bundle",
        hint: Some(err.to_string()),
        line: None,
      })
    }
  }
}

///|
fn validate_check_active_theme_path(
  config : @core.MooninkConfig,
  report : CheckReport,
) -> Result[(Bool, Bool, CheckReport), BuildCommandError] {
  let has_bundle = has_project_theme_bundle(config) catch {
    err => return Err(err)
  }
  let use_legacy = if has_bundle {
    false
  } else {
    should_use_legacy_active_theme(config) catch {
      err => return Err(err)
    }
  }
  Ok((has_bundle, use_legacy, report))
}

///|
fn validate_check_active_theme_layout(
  config : @core.MooninkConfig,
  inputs : Array[@runtime.BuildInput],
  report : CheckReport,
) -> CheckReport {
  let (has_bundle, use_legacy, report) = match
    validate_check_active_theme_path(config, report) {
    Ok(state) => state
    Err(BuildCommandError::ProjectIO(err)) =>
      return report_with_entry(report, {
        category: CheckCategory::ThemeTemplate,
        severity: CheckSeverity::Error,
        source_path: Some(config.config_path),
        message: "Failed to resolve active theme path",
        hint: Some(@core.format_project_io_error(err)),
        line: None,
      })
    Err(_) => return report
  }
  if has_bundle {
    return validate_check_active_theme_bundle(config, inputs, report)
  }
  if !use_legacy {
    return validate_check_active_theme_bundle(config, inputs, report)
  }
  match @runtime.load_active_theme_layout_result(config) {
    Ok(_) => report
    Err(err) =>
      report_with_entry(report, {
        category: CheckCategory::ThemeTemplate,
        severity: CheckSeverity::Error,
        source_path: Some(
          match config.template_file {
            Some(path) => path
            None => config.config_path
          },
        ),
        message: "Failed to load active theme layout",
        hint: Some(@core.format_config_error(err)),
        line: None,
      })
  }
}

///|
fn build_site_result(
  config : @core.MooninkConfig,
  inventory : @core.ContentInventory,
) -> Result[BuildWithDiagnostics, BuildCommandError] {
  let inputs = match @runtime.load_build_inputs_result(config, inventory) {
    Ok(inputs) => inputs
    Err(err) => return Err(BuildCommandError::ContentDiscovery(err))
  }
  let theme_bundle = match resolve_active_theme_bundle(config) {
    Ok(theme_bundle) => theme_bundle
    Err(err) => return Err(err)
  }
  let active_theme = match theme_bundle {
    Some(_) => None
    None =>
      match resolve_active_theme_layout(config) {
        Ok(active_theme) => Some(active_theme)
        Err(err) => return Err(err)
      }
  }
  match theme_bundle {
    Some(bundle) => {
      validate_build_theme_overrides(inputs, bundle) catch {
        err => return Err(err)
      }
      for input in inputs {
        let _ = select_theme_layout(bundle, input) catch {
          err => return Err(err)
        }
      }
    }
    None => ()
  }
  validate_reserved_generated_roots(inputs) catch {
    err => return Err(err)
  }
  let assembly = build_site_assembly_model(config, inputs, inventory)
  let generated_pages = build_generated_pages(config, assembly.pages)
  validate_static_asset_output_conflicts(inventory, inputs, generated_pages) catch {
    err => return Err(err)
  }
  prepare_output_dir(config) catch {
    err => return Err(err)
  }
  copy_public_assets(config) catch {
    err => return Err(err)
  }
  copy_content_tree_assets(config, inventory) catch {
    err => return Err(err)
  }
  match theme_bundle {
    Some(bundle) => {
      copy_theme_bundle_assets(config, bundle) catch {
        err => return Err(err)
      }
      write_theme_vars_output(config, bundle) catch {
        err => return Err(err)
      }
    }
    None =>
      match active_theme {
        Some(active_theme) =>
          copy_selected_theme_assets(config, active_theme) catch {
            err => return Err(err)
          }
        None => ()
      }
  }
  ensure_surface_search_asset(config) catch {
    err => return Err(err)
  }
  let mut emitted_html_files = 0
  let mut article_count = 0
  let mut page_count = 0
  let diagnostics : Array[BuildDiagnostic] = []
  let wikilinker = build_wikilinker_with_assets(inputs, inventory.asset_files)
  let experience = build_article_experience_model(
    inputs,
    assembly.pages,
    wikilinker,
  )
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
    for entry in linked.diagnostics.entries {
      diagnostics.push(build_runtime_diagnostic(input, entry))
    }
    let rendered = @docflow.render_with_adapter(renderer, linked)
    let templated = match theme_bundle {
      Some(bundle) =>
        apply_build_theme_template(
          config, bundle, assembly, experience, input, rendered,
        ) catch {
          err => return Err(err)
        }
      None => {
        let active_theme = match active_theme {
          Some(active_theme) => active_theme
          None => panic()
        }
        apply_build_template(
          config,
          active_theme,
          assembly,
          experience,
          input,
          rendered,
          active_theme.source,
        )
      }
    }
    let output_path = input.meta.output_path
    write_build_output(config, output_path, templated.html) catch {
      err => return Err(err)
    }
    emitted_html_files = emitted_html_files + 1
    match input.meta.content_kind {
      @core.ContentKind::Article => article_count = article_count + 1
      @core.ContentKind::Page => page_count = page_count + 1
    }
  }
  write_search_index_output(config, inputs) catch {
    err => return Err(err)
  }
  write_rss_output(config, assembly.pages) catch {
    err => return Err(err)
  }
  for generated_page in generated_pages {
    let html = match theme_bundle {
      Some(bundle) => {
        let layout_source = match
          resolve_theme_layout_source_for_key(bundle, generated_page.layout_key) {
          Ok(layout_source) => layout_source
          Err(layout_key) =>
            return Err(
              BuildCommandError::ProjectIO(
                @core.project_io_error(
                  "load_theme_layout",
                  generated_page.layout_key,
                  missing_theme_layout_message(layout_key),
                ),
              ),
            )
        }
        let context = build_generated_theme_render_context(
          config, bundle, assembly, generated_page,
        )
        @docflow.render_theme_template(layout_source, context, bundle.partials)
      }
      None => {
        let active_theme = match active_theme {
          Some(active_theme) => active_theme
          None => panic()
        }
        let generated_input : @runtime.BuildInput = {
          absolute_source_path: generated_page.source_path,
          relative_source_path: generated_page.source_path,
          source_content: generated_page.body_html,
          docflow_content: generated_page.body_html,
          meta: {
            source_path: generated_page.source_path,
            url_path: generated_page.url_path,
            output_path: generated_page.output_path,
            content_kind: @core.ContentKind::Page,
            format: @core.SourceFormat::Html,
            frontmatter: {
              ..@core.Frontmatter::default(),
              layout: Some(generated_page.layout_key),
            },
            layout_override: Some(generated_page.layout_key),
            resolved_title: generated_page.title,
            sort_key: generated_page.source_path,
            is_index: false,
          },
        }
        let generated_rendered : @docflow.RenderedDocument = {
          backend_name: "generated-page",
          source_path: generated_page.source_path,
          source_uuid: generated_page.source_path,
          html: generated_page.body_html,
          note: "generated page html",
        }
        apply_build_template(
          config,
          active_theme,
          assembly,
          experience,
          generated_input,
          generated_rendered,
          active_theme.source,
        ).html
      }
    }
    write_build_output(config, generated_page.output_path, html) catch {
      err => return Err(err)
    }
    emitted_html_files = emitted_html_files + 1
  }
  Ok({
    summary: {
      output_dir: config.output_dir,
      processed_sources: inputs.length(),
      emitted_html_files,
      article_count,
      page_count,
    },
    diagnostics,
  })
}

///|
fn summarize_build_success(
  config : @core.MooninkConfig,
  inventory : @core.ContentInventory,
  summary : BuildSummary,
  diagnostics : Array[BuildDiagnostic],
) -> CliOutcome {
  let header = if diagnostics.is_empty() {
    "[build] completed"
  } else {
    "[build] completed with diagnostics"
  }
  let details = if diagnostics.is_empty() {
    ""
  } else {
    let lines : Array[String] = []
    for diagnostic in diagnostics {
      lines.push("[\{diagnostic.source_path}]")
      lines.push(@docflow.format_document_diagnostic(diagnostic.entry))
    }
    "\n---\n" + lines.iter().join("\n")
  }
  {
    exit_code: 0,
    message: header +
    "\nsite: \{config.site_name}\nconfig: \{config.config_path}\ncontent root: \{inventory.root}\nprocessed: \{summary.processed_sources}\narticles: \{summary.article_count}\npages: \{summary.page_count}\noutput: \{summary.output_dir}\nemitted html: \{summary.emitted_html_files}" +
    details,
  }
}

///|
fn empty_check_report() -> CheckReport {
  { entries: [], error_count: 0, warning_count: 0 }
}

///|
fn report_with_entry(report : CheckReport, entry : CheckEntry) -> CheckReport {
  let entries = report.entries + [entry]
  match entry.severity {
    CheckSeverity::Error =>
      { ..report, entries, error_count: report.error_count + 1 }
    CheckSeverity::Warning =>
      { ..report, entries, warning_count: report.warning_count + 1 }
  }
}

///|
fn check_entry_from_docflow_diagnostic(
  source_path : String,
  entry : @docflow.DocumentDiagnostic,
) -> CheckEntry {
  {
    category: CheckCategory::Wikilinks,
    severity: match entry.severity {
      @docflow.DiagnosticSeverity::Error => CheckSeverity::Error
      _ => CheckSeverity::Warning
    },
    source_path: Some(source_path),
    message: entry.message,
    hint: entry.hint,
    line: entry.line,
  }
}

///|
fn validate_frontmatter_for_check(
  source_path : String,
  frontmatter : @core.Frontmatter,
  report : CheckReport,
) -> CheckReport {
  let mut next_report = report
  match frontmatter.field_shapes.get("title") {
    Some(@core.FrontmatterFieldShape::List) =>
      next_report = report_with_entry(next_report, {
        category: CheckCategory::Frontmatter,
        severity: CheckSeverity::Error,
        source_path: Some(source_path),
        message: "Frontmatter field `title` must be a string",
        hint: None,
        line: None,
      })
    _ => ()
  }
  match frontmatter.field_shapes.get("description") {
    Some(@core.FrontmatterFieldShape::List) =>
      next_report = report_with_entry(next_report, {
        category: CheckCategory::Frontmatter,
        severity: CheckSeverity::Error,
        source_path: Some(source_path),
        message: "Frontmatter field `description` must be a string",
        hint: None,
        line: None,
      })
    _ => ()
  }
  match frontmatter.field_shapes.get("type") {
    Some(@core.FrontmatterFieldShape::List) =>
      next_report = report_with_entry(next_report, {
        category: CheckCategory::Frontmatter,
        severity: CheckSeverity::Error,
        source_path: Some(source_path),
        message: "Frontmatter field `type` must be a string",
        hint: None,
        line: None,
      })
    _ => ()
  }
  match frontmatter.field_shapes.get("date") {
    Some(@core.FrontmatterFieldShape::List) =>
      next_report = report_with_entry(next_report, {
        category: CheckCategory::Frontmatter,
        severity: CheckSeverity::Error,
        source_path: Some(source_path),
        message: "Frontmatter field `date` must be a string",
        hint: None,
        line: None,
      })
    _ => ()
  }
  match frontmatter.field_shapes.get("layout") {
    Some(@core.FrontmatterFieldShape::List) =>
      next_report = report_with_entry(next_report, {
        category: CheckCategory::Frontmatter,
        severity: CheckSeverity::Error,
        source_path: Some(source_path),
        message: "Frontmatter field `layout` must be a string",
        hint: None,
        line: None,
      })
    _ => ()
  }
  match frontmatter.field_shapes.get("search") {
    Some(@core.FrontmatterFieldShape::List) =>
      next_report = report_with_entry(next_report, {
        category: CheckCategory::Frontmatter,
        severity: CheckSeverity::Error,
        source_path: Some(source_path),
        message: "Frontmatter field `search` must be a boolean",
        hint: None,
        line: None,
      })
    _ => ()
  }
  match frontmatter.field_shapes.get("tags") {
    Some(@core.FrontmatterFieldShape::Scalar) =>
      next_report = report_with_entry(next_report, {
        category: CheckCategory::Frontmatter,
        severity: CheckSeverity::Error,
        source_path: Some(source_path),
        message: "Frontmatter field `tags` must be an array",
        hint: None,
        line: None,
      })
    _ => ()
  }
  match frontmatter.invalid_scalar_fields.get("draft") {
    Some(true) =>
      next_report = report_with_entry(next_report, {
        category: CheckCategory::Frontmatter,
        severity: CheckSeverity::Error,
        source_path: Some(source_path),
        message: "Frontmatter field `draft` must be a boolean",
        hint: None,
        line: None,
      })
    _ => ()
  }
  match frontmatter.invalid_scalar_fields.get("search") {
    Some(true) =>
      next_report = report_with_entry(next_report, {
        category: CheckCategory::Frontmatter,
        severity: CheckSeverity::Error,
        source_path: Some(source_path),
        message: "Frontmatter field `search` must be a boolean",
        hint: None,
        line: None,
      })
    _ => ()
  }
  next_report
}

///|
fn append_homepage_warning(
  inputs : Array[@runtime.BuildInput],
  report : CheckReport,
) -> CheckReport {
  if inputs.search_by(fn(input) { input.meta.is_index }) is Some(_) {
    return report
  }
  report_with_entry(report, {
    category: CheckCategory::Site,
    severity: CheckSeverity::Warning,
    source_path: None,
    message: "No homepage note detected",
    hint: Some(
      "Add root index.md or README.md to make the vault landing page explicit.",
    ),
    line: None,
  })
}

///|
fn check_category_label(category : CheckCategory) -> String {
  match category {
    CheckCategory::ThemeTemplate => "theme/template"
    CheckCategory::Frontmatter => "frontmatter"
    CheckCategory::Wikilinks => "wikilinks"
    CheckCategory::Routes => "routes"
    CheckCategory::Site => "site"
  }
}

///|
fn check_severity_label(severity : CheckSeverity) -> String {
  match severity {
    CheckSeverity::Error => "error"
    CheckSeverity::Warning => "warning"
  }
}

///|
fn format_check_entry_body(entry : CheckEntry) -> String {
  let lines : Array[String] = []
  let source_line = match entry.source_path {
    Some(path) => "[" + path + "]"
    None => ""
  }
  if source_line != "" {
    lines.push(source_line)
  }
  lines.push(check_severity_label(entry.severity) + ": " + entry.message)
  match entry.line {
    Some(line) => lines.push("line: " + line.to_string())
    None => ()
  }
  match entry.hint {
    Some(hint) if hint != "" => lines.push(hint)
    _ => ()
  }
  lines.iter().join("\n")
}

///|
fn check_output_categories() -> Array[CheckCategory] {
  [
    CheckCategory::ThemeTemplate,
    CheckCategory::Frontmatter,
    CheckCategory::Routes,
    CheckCategory::Site,
    CheckCategory::Wikilinks,
    CheckCategory::Site,
  ]
}

///|
fn check_entries_for_category(
  report : CheckReport,
  category : CheckCategory,
) -> Array[CheckEntry] {
  let entries : Array[CheckEntry] = []
  for entry in report.entries {
    if entry.category == category {
      entries.push(entry)
    }
  }
  entries
}

///|
fn format_check_group(
  category : CheckCategory,
  entries : Array[CheckEntry],
) -> String {
  let rendered_entries : Array[String] = []
  for entry in entries {
    rendered_entries.push(format_check_entry_body(entry))
  }
  "[check] " +
  check_category_label(category) +
  "\n" +
  rendered_entries.iter().join("\n---\n")
}

///|
fn check_report_passed(report : CheckReport) -> Bool {
  report.error_count == 0
}

///|
fn format_check_report(report : CheckReport) -> String {
  let sections : Array[String] = []
  for category in check_output_categories() {
    let entries = check_entries_for_category(report, category)
    if !entries.is_empty() {
      sections.push(format_check_group(category, entries))
    }
  }
  sections.push(
    "[check] summary: " +
    report.error_count.to_string() +
    " errors, " +
    report.warning_count.to_string() +
    " warnings",
  )
  sections.push(
    if check_report_passed(report) {
      "[check] passed"
    } else {
      "[check] failed"
    },
  )
  sections.iter().join("\n---\n")
}

///|
fn build_runtime_diagnostic(
  input : @runtime.BuildInput,
  entry : @docflow.DocumentDiagnostic,
) -> BuildDiagnostic {
  { source_path: input.meta.source_path, entry }
}

///|
fn summarize_check_success(
  config : @core.MooninkConfig,
  inventory : @core.ContentInventory,
  summary : CheckSummary,
) -> CliOutcome {
  let passed = check_report_passed(summary.report)
  let header = if summary.report.entries.is_empty() {
    if passed {
      "[check] passed"
    } else {
      "[check] failed"
    }
  } else if passed {
    "[check] passed with diagnostics"
  } else {
    "[check] failed with diagnostics"
  }
  let report_details = if summary.report.entries.is_empty() {
    ""
  } else {
    "\n---\n" + format_check_report(summary.report)
  }
  {
    exit_code: if passed {
      0
    } else {
      1
    },
    message: header +
    "\nsite: \{config.site_name}\nconfig: \{config.config_path}\ncontent root: \{inventory.root}\nprocessed: \{summary.processed_sources}\narticles: \{summary.article_count}\npages: \{summary.page_count}\ndiagnostics: \{summary.report.entries.length()}" +
    report_details,
  }
}

///|
fn check_site_result(
  config : @core.MooninkConfig,
  inventory : @core.ContentInventory,
) -> Result[CheckSummary, CheckCommandError] {
  let inputs = match @runtime.load_build_inputs_result(config, inventory) {
    Ok(inputs) => inputs
    Err(err) => return Err(CheckCommandError::ContentDiscovery(err))
  }
  let mut report = empty_check_report()
  report = append_homepage_warning(inputs, report)
  report = validate_check_active_theme_layout(config, inputs, report)
  report = append_route_conflicts(inputs, config.route_style, report)
  let wikilinker = build_wikilinker_with_assets(inputs, inventory.asset_files)
  let mut article_count = 0
  let mut page_count = 0
  for input in inputs {
    report = validate_frontmatter_for_check(
      input.meta.source_path,
      input.meta.frontmatter,
      report,
    )
    let parser = match check_parser_for_format(input.meta.format) {
      Ok(parser) => parser
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
      Err(err) => return Err(CheckCommandError::FatalParse(err))
    }
    let linked = @docflow.apply_wikilinker(wikilinker, parsed)
    for entry in linked.diagnostics.entries {
      report = report_with_entry(
        report,
        check_entry_from_docflow_diagnostic(input.meta.source_path, entry),
      )
    }
    match input.meta.content_kind {
      @core.ContentKind::Article => article_count = article_count + 1
      @core.ContentKind::Page => page_count = page_count + 1
    }
  }
  Ok({ processed_sources: inputs.length(), article_count, page_count, report })
}

///|
fn apply_output_override_result(
  config : @core.MooninkConfig,
  output_dir : String?,
) -> Result[@core.MooninkConfig, @core.ConfigError] {
  match output_dir {
    Some(path) =>
      try @core.config_with_output_dir(config, path) catch {
        err => Err(err)
      } noraise {
        config => Ok(config)
      }
    None => Ok(config)
  }
}

///|
pub fn run_build_command_runtime_from_config_with_output(
  config_path : String,
  output_dir : String?,
) -> CliOutcome {
  let config_result = @runtime.load_config_result(config_path)
  let config = match config_result {
    Ok(config) => config
    Err(err) =>
      return { exit_code: 1, message: format_runtime_config_error(err) }
  }
  let config = match apply_output_override_result(config, output_dir) {
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
  let result = match build_site_result(config, inventory) {
    Ok(result) => result
    Err(err) =>
      return { exit_code: 1, message: format_build_command_error(err) }
  }
  let summary = result.summary
  summarize_build_success(config, inventory, summary, result.diagnostics)
}

///|
pub fn run_build_command_runtime_from_config(
  config_path : String,
) -> CliOutcome {
  run_build_command_runtime_from_config_with_output(config_path, None)
}

///|
pub fn run_check_command_runtime_from_config_with_output(
  config_path : String,
  output_dir : String?,
) -> CliOutcome {
  let config_result = @runtime.load_config_result(config_path)
  let config = match config_result {
    Ok(config) => config
    Err(err) =>
      return { exit_code: 1, message: format_check_runtime_config_error(err) }
  }
  let config = match apply_output_override_result(config, output_dir) {
    Ok(config) => config
    Err(err) =>
      return { exit_code: 1, message: format_check_runtime_config_error(err) }
  }
  let inventory = match
    @runtime.run_runtime_io_task(@runtime.discover_content_task(config)) {
    Ok(inventory) => inventory
    Err(err) =>
      return { exit_code: 1, message: format_check_runtime_content_error(err) }
  }
  let check_result = match check_site_result(config, inventory) {
    Ok(result) => result
    Err(err) =>
      return { exit_code: 1, message: format_check_command_error(err) }
  }
  summarize_check_success(config, inventory, check_result)
}

///|
pub fn run_check_command_runtime_from_config(
  config_path : String,
) -> CliOutcome {
  run_check_command_runtime_from_config_with_output(config_path, None)
}

///|
pub fn run_check_command_runtime() -> CliOutcome {
  run_check_command_runtime_from_config("moonink.json")
}

///|
pub fn run_build_command_runtime() -> CliOutcome {
  run_build_command_runtime_from_config("moonink.json")
}

///|
fn run_check_command(options : CheckCliOptions) -> CliOutcome {
  let output_status = match options.output_dir {
    Some(path) => "\noutput override: \{path}"
    None => ""
  }
  {
    exit_code: 0,
    message: "[check] runtime execution required\nconfig: \{options.config_path}\nstatus: use cli_exec or the runtime IO boundary to load config, discover content, and collect diagnostics" +
    output_status,
  }
}

///|
fn run_native_check_command(options : CheckCliOptions) -> CliOutcome {
  @runtime.run_native_runtime_io_task_with_policy(
    @runtime.RuntimeIOTask::Ready(
      run_check_command_runtime_from_config_with_output(
        options.config_path,
        options.output_dir,
      ),
    ),
    @runtime.native_runtime_adapter().policy,
  )
}

///|
fn run_build_command(options : BuildCliOptions) -> CliOutcome {
  let output_status = match options.output_dir {
    Some(path) => "\noutput override: \{path}"
    None => ""
  }
  {
    exit_code: 0,
    message: "[build] runtime execution required\nconfig: \{options.config_path}\nstatus: use cli_exec or the runtime IO boundary to load config and discover content" +
    output_status,
  }
}

///|
fn run_native_build_command(options : BuildCliOptions) -> CliOutcome {
  @runtime.run_native_runtime_io_task_with_policy(
    @runtime.RuntimeIOTask::Ready(
      run_build_command_runtime_from_config_with_output(
        options.config_path,
        options.output_dir,
      ),
    ),
    @runtime.native_runtime_adapter().policy,
  )
}
