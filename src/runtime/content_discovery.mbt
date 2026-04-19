///|
fn content_path_policy_error(
  path : String,
  err : @core.PathPolicyError,
) -> @core.ContentDiscoveryError {
  @core.ContentDiscoveryError::InvalidPath(
    path~,
    reason=@core.format_path_policy_error(err),
  )
}

///|
pub(all) struct BuildInput {
  absolute_source_path : String
  relative_source_path : String
  source_content : String
  docflow_content : String
  meta : @core.PageMeta
} derive(Debug, Eq)

///|
fn join_content_path(
  base : String,
  child : String,
) -> String raise @core.ContentDiscoveryError {
  join_host_path(base, child) catch {
    err => raise content_path_policy_error(child, err)
  }
}

///|
fn io_discovery_error(
  err : @core.ProjectIOError,
) -> @core.ContentDiscoveryError {
  @core.ContentDiscoveryError::IOError(err)
}

///|
fn relative_source_path(
  content_root : String,
  absolute_path : String,
) -> String raise @core.ContentDiscoveryError {
  if content_root == "." {
    @core.normalize_relative_path(absolute_path) catch {
      err => raise content_path_policy_error(absolute_path, err)
    }
  } else if absolute_path == content_root {
    "."
  } else {
    let prefix = content_root + "/"
    if absolute_path.has_prefix(prefix) {
      @core.normalize_relative_path(absolute_path[prefix.length():].to_string()) catch {
        err => raise content_path_policy_error(absolute_path, err)
      }
    } else {
      raise @core.ContentDiscoveryError::InvalidPath(
        path=absolute_path,
        reason="path is outside configured content root",
      )
    }
  }
}

///|
fn content_root_relative_helper_path(
  config : @core.MooninkConfig,
  helper_path : String,
) -> String? {
  let normalized = @core.normalize_relative_path(helper_path) catch {
    _ => return None
  }
  if config.content_dir == "." {
    return Some(normalized)
  }
  let content_dir = @core.normalize_relative_path(config.content_dir) catch {
    _ => return None
  }
  if normalized == content_dir {
    return Some(".")
  }
  let prefix = content_dir + "/"
  if normalized.has_prefix(prefix) {
    return Some(normalized[prefix.length():].to_string())
  }
  None
}

///|
fn configured_theme_helper_path(config : @core.MooninkConfig) -> String? {
  match config.theme {
    Some(theme_dir) => content_root_relative_helper_path(config, theme_dir)
    None => content_root_relative_helper_path(config, "theme")
  }
}

///|
fn configured_template_helper_path(config : @core.MooninkConfig) -> String? {
  match config.template_file {
    Some(template_file) =>
      content_root_relative_helper_path(config, template_file)
    None => None
  }
}

///|
fn configured_config_helper_path(config : @core.MooninkConfig) -> String? {
  if config.content_dir != "." {
    return None
  }
  Some(
    relative_source_path(config.project_root, config.config_path) catch {
      _ => return None
    },
  )
}

///|
fn is_helper_path(path : String, helper_root : String) -> Bool {
  path == helper_root || path.has_prefix(helper_root + "/")
}

///|
fn should_skip_root_helper_dir(
  config : @core.MooninkConfig,
  entry : String,
) -> Bool {
  if config.content_dir == "." && entry == "public" {
    return true
  }
  match configured_theme_helper_path(config) {
    Some(theme_root) if theme_root != "." && !theme_root.contains("/") =>
      entry == theme_root
    _ => false
  }
}

///|
fn should_skip_helper_source(
  config : @core.MooninkConfig,
  relative_path : String,
) -> Bool {
  let normalized = @core.normalize_relative_path(relative_path) catch {
    _ => return false
  }
  if config.content_dir == "." && is_helper_path(normalized, "public") {
    return true
  }
  match configured_config_helper_path(config) {
    Some(config_path) if normalized == config_path => return true
    _ => ()
  }
  match configured_theme_helper_path(config) {
    Some(theme_root) if theme_root != "." &&
      is_helper_path(normalized, theme_root) => return true
    _ => ()
  }
  match configured_template_helper_path(config) {
    Some(template_path) if normalized == template_path => true
    _ => false
  }
}

///|
fn strip_source_extension(path : String) -> String {
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
  let stripped = strip_source_extension(path)
  let mut result = stripped
  for part_view in stripped.split("/") {
    result = part_view.to_string()
  }
  result
}

///|
fn first_markdown_h1(body : String) -> String? {
  for line_view in body.split("\n") {
    let line = line_view.to_string().trim().to_string()
    if line.has_prefix("# ") {
      let heading = line[2:line.length()].trim().to_string()
      if heading != "" {
        return Some(heading)
      }
    }
  }
  None
}

///|
fn resolved_input_title(
  source_path : String,
  frontmatter : @core.Frontmatter,
  format : @core.SourceFormat,
  body : String,
  is_index : Bool,
) -> String {
  match frontmatter.title {
    Some(title) => title
    None =>
      match format {
        @core.SourceFormat::Markdown =>
          match first_markdown_h1(body) {
            Some(title) => title
            None =>
              if is_index {
                "Home"
              } else {
                basename_without_extension(source_path)
              }
          }
        _ =>
          if is_index {
            "Home"
          } else {
            basename_without_extension(source_path)
          }
      }
  }
}

///|
pub fn load_build_inputs_result(
  config : @core.MooninkConfig,
  inventory : @core.ContentInventory,
) -> Result[Array[BuildInput], @core.ContentDiscoveryError] {
  let inputs : Array[BuildInput] = []
  for file in inventory.files {
    let source = io_read_file_to_string(file.path) catch {
      err => return Err(io_discovery_error(err))
    }
    let relative_path = relative_source_path(inventory.root, file.path) catch {
      err => return Err(err)
    }
    if should_skip_helper_source(config, relative_path) {
      continue
    }
    let (frontmatter, body) = match file.format {
      @core.SourceFormat::Markdown =>
        @core.parse_frontmatter_from_source(source)
      _ => (@core.Frontmatter::default(), source)
    }
    let content_kind = @core.classify_content_kind(
      file.format,
      frontmatter.content_type,
    )
    let initial_meta = @core.PageMeta::new(
      relative_path,
      content_kind,
      file.format,
      frontmatter,
      config.route_style,
    )
    let normalized_meta = if initial_meta.is_index {
      { ..initial_meta, content_kind: @core.ContentKind::Page }
    } else {
      initial_meta
    }
    let meta = @core.page_meta_with_title(
      normalized_meta,
      resolved_input_title(
        relative_path,
        frontmatter,
        file.format,
        body,
        normalized_meta.is_index,
      ),
    )
    inputs.push({
      absolute_source_path: file.path,
      relative_source_path: relative_path,
      source_content: source,
      docflow_content: body,
      meta,
    })
  }
  Ok(apply_homepage_override(inputs))
}

///|
pub fn load_build_inputs_task(
  config : @core.MooninkConfig,
  inventory : @core.ContentInventory,
) -> RuntimeIOTask[Result[Array[BuildInput], @core.ContentDiscoveryError]] {
  Ready(load_build_inputs_result(config, inventory))
}

///|
/// Recursively collect content files and passthrough assets from a directory.
fn collect_content_tree(
  content_root : String,
  root : String,
  exclude : Array[String],
  skip_dir : (String) -> Bool,
) -> (Array[@core.ContentFile], Array[@core.StaticAssetFile]) raise @core.ContentDiscoveryError {
  if !io_path_exists(root) {
    raise @core.ContentDiscoveryError::MissingDirectory(root)
  }
  let is_dir = io_is_dir(root) catch { err => raise io_discovery_error(err) }
  if !is_dir {
    raise @core.ContentDiscoveryError::NotDirectory(root)
  }
  let content : Array[@core.ContentFile] = []
  let assets : Array[@core.StaticAssetFile] = []
  let entries = io_read_dir(root) catch { err => raise io_discovery_error(err) }
  for entry in entries {
    if @core.should_exclude(entry, exclude) || skip_dir(entry) {
      continue
    }
    let full_path = join_content_path(root, entry)
    let is_dir = io_is_dir(full_path) catch {
      err => raise io_discovery_error(err)
    }
    if is_dir {
      let (nested_content, nested_assets) = collect_content_tree(
        content_root, full_path, exclude, skip_dir,
      )
      for file in nested_content {
        content.push(file)
      }
      for asset in nested_assets {
        assets.push(asset)
      }
      continue
    }
    let is_file = io_is_file(full_path) catch {
      err => raise io_discovery_error(err)
    }
    if !is_file {
      continue
    }
    let format = @core.classify_source_format(full_path)
    let relative_path = relative_source_path(content_root, full_path) catch {
      err => raise err
    }
    match format {
      @core.SourceFormat::Markdown =>
        content.push({
          path: full_path,
          content_kind: @core.ContentKind::Article,
          format,
        })
      @core.SourceFormat::Html =>
        content.push({
          path: full_path,
          content_kind: @core.ContentKind::Page,
          format,
        })
      _ => assets.push({ path: full_path, relative_path })
    }
  }
  content.sort_by(fn(a, b) { a.path.compare(b.path) })
  assets.sort_by(fn(a, b) { a.relative_path.compare(b.relative_path) })
  (content, assets)
}

///|
fn pick_home_source_path(inputs : Array[BuildInput]) -> String? {
  for input in inputs {
    if input.meta.source_path == "index.md" ||
      input.meta.source_path == "index.html" ||
      input.meta.source_path == "index.htm" {
      return Some(input.meta.source_path)
    }
  }
  for input in inputs {
    if input.meta.source_path == "README.md" {
      return Some(input.meta.source_path)
    }
  }
  None
}

///|
fn apply_homepage_override(inputs : Array[BuildInput]) -> Array[BuildInput] {
  let home_source = pick_home_source_path(inputs)
  let normalized : Array[BuildInput] = []
  for input in inputs {
    let meta = match home_source {
      Some(source_path) if input.meta.source_path == source_path =>
        @core.page_meta_as_home(input.meta)
      _ => input.meta
    }
    normalized.push({ ..input, meta, })
  }
  normalized
}

///|
/// Discover content files in the configured content directory.
pub fn discover_content_result(
  config : @core.MooninkConfig,
) -> Result[@core.ContentInventory, @core.ContentDiscoveryError] {
  let content_root = if config.content_dir == "." {
    config.project_root
  } else {
    join_host_path(config.project_root, config.content_dir) catch {
      err => return Err(content_path_policy_error(config.content_dir, err))
    }
  }
  let exclude = config.exclude.copy()
  // Always exclude the output directory
  if exclude.search_by(e => e == config.output_dir) is None {
    exclude.push(config.output_dir)
  }
  let (discovered_files, discovered_assets) = collect_content_tree(
    content_root,
    content_root,
    exclude,
    fn(entry) { should_skip_root_helper_dir(config, entry) },
  ) catch {
    err => return Err(err)
  }
  let files : Array[@core.ContentFile] = []
  let asset_files : Array[@core.StaticAssetFile] = []
  for file in discovered_files {
    let relative_path = relative_source_path(content_root, file.path) catch {
      err => return Err(err)
    }
    if should_skip_helper_source(config, relative_path) {
      continue
    }
    files.push(file)
  }
  for asset in discovered_assets {
    if should_skip_helper_source(config, asset.relative_path) {
      continue
    }
    asset_files.push(asset)
  }
  let mut total_articles = 0
  let mut total_pages = 0
  for file in files {
    match file.content_kind {
      @core.ContentKind::Article => total_articles = total_articles + 1
      @core.ContentKind::Page => total_pages = total_pages + 1
    }
  }
  Ok({
    root: content_root,
    files,
    asset_files,
    total_articles,
    total_pages,
    total_assets: asset_files.length(),
    note: "Content discovery scans the content directory recursively, excluding configured patterns and collecting passthrough assets.",
  })
}

///|
pub fn discover_content_task(
  config : @core.MooninkConfig,
) -> RuntimeIOTask[Result[@core.ContentInventory, @core.ContentDiscoveryError]] {
  Ready(discover_content_result(config))
}
