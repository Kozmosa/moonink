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
pub(all) suberror CheckCommandError {
  ContentDiscovery(@core.ContentDiscoveryError)
  AdapterRegistry(@docflow.AdapterRegistryError)
  FatalParse(@docflow.FatalParseError)
} derive(Debug, Eq)

///|
pub(all) struct CheckSummary {
  processed_sources : Int
  article_count : Int
  page_count : Int
  diagnostic_count : Int
} derive(Debug, Eq)

///|
pub(all) struct CheckDiagnostic {
  source_path : String
  entry : @docflow.DocumentDiagnostic
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
fn copy_selected_theme_assets(
  config : @core.MooninkConfig,
  active_theme : @runtime.ActiveThemeLayout,
) -> Unit raise BuildCommandError {
  let assets_root = match active_theme.asset_source_dir {
    Some(path) => path
    None => return
  }
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
fn find_wikilink_close(payload : String, start : Int) -> Int? {
  let mut cursor = start
  while cursor + 1 < payload.length() {
    if payload[cursor:cursor + 2].to_string() == "]]" {
      return Some(cursor)
    }
    cursor = cursor + 1
  }
  None
}

///|
fn normalize_wikilink_target(target : String) -> String {
  let trimmed = target.trim().to_string()
  if trimmed.has_prefix("./") {
    trimmed[2:].to_string()
  } else {
    trimmed
  }
}

///|
fn scan_markdown_wikilink_targets(payload : String) -> Array[String] {
  let targets : Array[String] = []
  let mut cursor = 0
  while cursor < payload.length() {
    if cursor + 1 < payload.length() &&
      payload[cursor:cursor + 2].to_string() == "[[" {
      match find_wikilink_close(payload, cursor + 2) {
        Some(close_cursor) => {
          let inner = payload[cursor + 2:close_cursor].to_string()
          let target = match inner.split_once("|") {
            Some((target_view, _)) =>
              normalize_wikilink_target(target_view.to_string())
            None => normalize_wikilink_target(inner)
          }
          if target != "" {
            targets.push(target)
          }
          cursor = close_cursor + 2
        }
        None => cursor = payload.length()
      }
    } else {
      cursor = cursor + 1
    }
  }
  targets
}

///|
fn build_backlink_index(
  inputs : Array[@runtime.BuildInput],
  wikilinker : @docflow.WikiLinker,
) -> Map[String, Array[String]] {
  let backlinks : Map[String, Array[String]] = {}
  for input in inputs {
    if input.meta.format != @core.SourceFormat::Markdown {
      continue
    }
    let targets = scan_markdown_wikilink_targets(input.docflow_content)
    for target in targets {
      match wikilinker.exact_targets.get(target) {
        Some(url) => {
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
        None => ()
      }
    }
  }
  backlinks
}

///|
fn render_backlinks_html(
  current_url : String,
  pages : Array[@core.SitePage],
  backlinks : Map[String, Array[String]],
) -> String {
  let backlink_urls = match backlinks.get(current_url) {
    Some(urls) => urls
    None => []
  }
  if backlink_urls.is_empty() {
    return ""
  }
  let items : Array[String] = []
  for url in backlink_urls {
    let mut title = url
    for page in pages {
      if page.url_path == url {
        title = page.title
        break
      }
    }
    items.push(
      "<li><a href=\"" +
      escape_html_text(url) +
      "\">" +
      escape_html_text(title) +
      "</a></li>",
    )
  }
  "<aside class=\"page-backlinks\"><section class=\"backlinks\" aria-label=\"Backlinks\"><h2>Backlinks</h2><ul>" +
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
fn page_body_class(kind : @core.ContentKind) -> String {
  match kind {
    @core.ContentKind::Article => "moonink-article"
    @core.ContentKind::Page => "moonink-page"
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
    title: page.nav_title,
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
    if page.content_kind == @core.ContentKind::Page && !page.nav_hidden {
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
    if page.content_kind == @core.ContentKind::Page &&
      page.is_index &&
      navigation_node_key(page) == key {
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
  source_path : String,
) -> @core.SitePage? {
  let directories = source_directory_segments(source_path)
  if is_index_source_path(source_path) {
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
    nav_title: site_page_nav_title(input.meta),
    nav_hidden: site_page_nav_hidden(input.meta),
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
  active_theme : @runtime.ActiveThemeLayout,
  assembly : @core.SiteAssemblyModel,
  backlinks : Map[String, Array[String]],
  input : @runtime.BuildInput,
  rendered : @docflow.RenderedDocument,
) -> @docflow.TemplateContext {
  let current_section = find_current_section_page(
    assembly.pages,
    input.meta.source_path,
  )
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
    page_body_class: page_body_class(input.meta.content_kind),
    navigation_html: render_navigation_html(
      assembly.navigation,
      input.meta.url_path,
    ),
    current_section_title,
    current_section_url,
    page_header_title: site_page_title(input.meta),
    page_header_html: build_page_header_html(
      assembly.navigation,
      assembly.pages,
      input,
    ),
    backlinks_html: render_backlinks_html(
      input.meta.url_path,
      assembly.pages,
      backlinks,
    ),
    body_html: rendered.html,
  }
}

///|
fn apply_build_template(
  config : @core.MooninkConfig,
  active_theme : @runtime.ActiveThemeLayout,
  assembly : @core.SiteAssemblyModel,
  backlinks : Map[String, Array[String]],
  input : @runtime.BuildInput,
  rendered : @docflow.RenderedDocument,
  template_source : String,
) -> @docflow.TemplatedPage {
  let context = build_template_context(
    config, active_theme, assembly, backlinks, input, rendered,
  )
  @docflow.apply_template(rendered, context, template_source)
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
  copy_public_assets(config) catch {
    err => return Err(err)
  }
  let active_theme = match resolve_active_theme_layout(config) {
    Ok(active_theme) => active_theme
    Err(err) => return Err(err)
  }
  copy_selected_theme_assets(config, active_theme) catch {
    err => return Err(err)
  }
  let assembly = build_site_assembly_model(config, inputs, inventory)
  let template_source = active_theme.source
  let mut emitted_html_files = 0
  let mut article_count = 0
  let mut page_count = 0
  let wikilinker = build_wikilinker(inputs)
  let backlinks = build_backlink_index(inputs, wikilinker)
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
      config, active_theme, assembly, backlinks, input, rendered, template_source,
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
fn format_check_diagnostic_lines(
  diagnostics : Array[CheckDiagnostic],
) -> String {
  let lines : Array[String] = []
  for diagnostic in diagnostics {
    lines.push("[\{diagnostic.source_path}]")
    lines.push(@docflow.format_document_diagnostic(diagnostic.entry))
  }
  lines.iter().join("\n")
}

///|
fn summarize_check_success(
  config : @core.MooninkConfig,
  inventory : @core.ContentInventory,
  summary : CheckSummary,
  diagnostics : Array[CheckDiagnostic],
) -> CliOutcome {
  let header = if summary.diagnostic_count == 0 {
    "[check] completed"
  } else {
    "[check] completed with diagnostics"
  }
  let details = if diagnostics.is_empty() {
    ""
  } else {
    "\n---\n" + format_check_diagnostic_lines(diagnostics)
  }
  {
    exit_code: if summary.diagnostic_count == 0 {
      0
    } else {
      1
    },
    message: header +
    "\nsite: \{config.site_name}\nconfig: \{config.config_path}\ncontent root: \{inventory.root}\nprocessed: \{summary.processed_sources}\narticles: \{summary.article_count}\npages: \{summary.page_count}\ndiagnostics: \{summary.diagnostic_count}" +
    details,
  }
}

///|
fn check_site_result(
  config : @core.MooninkConfig,
  inventory : @core.ContentInventory,
) -> Result[(CheckSummary, Array[CheckDiagnostic]), CheckCommandError] {
  let inputs = match @runtime.load_build_inputs_result(config, inventory) {
    Ok(inputs) => inputs
    Err(err) => return Err(CheckCommandError::ContentDiscovery(err))
  }
  let wikilinker = build_wikilinker(inputs)
  let diagnostics : Array[CheckDiagnostic] = []
  let mut article_count = 0
  let mut page_count = 0
  for input in inputs {
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
      diagnostics.push({ source_path: input.meta.source_path, entry })
    }
    match input.meta.content_kind {
      @core.ContentKind::Article => article_count = article_count + 1
      @core.ContentKind::Page => page_count = page_count + 1
    }
  }
  Ok(
    (
      {
        processed_sources: inputs.length(),
        article_count,
        page_count,
        diagnostic_count: diagnostics.length(),
      },
      diagnostics,
    ),
  )
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
pub fn run_check_command_runtime_from_config(
  config_path : String,
) -> CliOutcome {
  let config_result = @runtime.load_config_result(config_path)
  let config = match config_result {
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
  let (summary, diagnostics) = check_result
  summarize_check_success(config, inventory, summary, diagnostics)
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
fn run_check_command() -> CliOutcome {
  {
    exit_code: 0,
    message: "[check] runtime execution required\nstatus: use cli_exec or the runtime IO boundary to load config, discover content, and collect diagnostics",
  }
}

///|
fn run_native_check_command() -> CliOutcome {
  @runtime.run_native_runtime_io_task_with_policy(
    @runtime.RuntimeIOTask::Ready(run_check_command_runtime()),
    @runtime.native_runtime_adapter().policy,
  )
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
