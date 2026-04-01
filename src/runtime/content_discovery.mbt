///|
fn content_path_policy_error(
  path : String,
  err : @core.PathPolicyError,
) -> @core.ContentDiscoveryError {
  @core.ContentDiscoveryError::InvalidPath(path~, reason=err.to_string())
}

///|
fn join_content_path(
  base : String,
  child : String,
) -> String raise @core.ContentDiscoveryError {
  @core.join_relative_path(base, child) catch {
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
/// Recursively collect content files (.md and .html) from a directory,
/// respecting exclude patterns.
fn collect_content_files(
  root : String,
  exclude : Array[String],
) -> Array[@core.ContentFile] raise @core.ContentDiscoveryError {
  if !io_path_exists(root) {
    raise @core.ContentDiscoveryError::MissingDirectory(root)
  }
  let is_dir = io_is_dir(root) catch { err => raise io_discovery_error(err) }
  if !is_dir {
    raise @core.ContentDiscoveryError::NotDirectory(root)
  }
  let discovered : Array[@core.ContentFile] = []
  let entries = io_read_dir(root) catch { err => raise io_discovery_error(err) }
  for entry in entries {
    // Skip excluded directories
    if @core.should_exclude(entry, exclude) {
      continue
    }
    let full_path = join_content_path(root, entry)
    let is_dir = io_is_dir(full_path) catch {
      err => raise io_discovery_error(err)
    }
    if is_dir {
      let nested = collect_content_files(full_path, exclude)
      for file in nested {
        discovered.push(file)
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
    match format {
      @core.SourceFormat::Markdown => {
        // Need to read file to check frontmatter for type classification
        // For initial discovery, default to Article; will be refined after frontmatter parsing
        discovered.push({
          path: full_path,
          content_kind: @core.ContentKind::Article,
          format,
        })
      }
      @core.SourceFormat::Html => {
        discovered.push({
          path: full_path,
          content_kind: @core.ContentKind::Page,
          format,
        })
      }
      _ => ()
    }
  }
  discovered.sort_by(fn(a, b) { a.path.compare(b.path) })
  discovered
}

///|
/// Discover content files in the configured content directory.
pub fn discover_content_result(
  config : @core.MooninkConfig,
) -> Result[@core.ContentInventory, @core.ContentDiscoveryError] {
  let content_root = if config.content_dir == "." {
    config.project_root
  } else {
    @core.join_relative_path(config.project_root, config.content_dir) catch {
      err => return Err(content_path_policy_error(config.content_dir, err))
    }
  }
  let exclude = config.exclude.copy()
  // Always exclude the output directory
  if exclude.search_by(e => e == config.output_dir) is None {
    exclude.push(config.output_dir)
  }
  let files = collect_content_files(content_root, exclude) catch {
    err => return Err(err)
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
    total_articles,
    total_pages,
    note: "Content discovery scans the content directory recursively, excluding configured patterns.",
  })
}

///|
pub fn discover_content_task(
  config : @core.MooninkConfig,
) -> RuntimeIOTask[Result[@core.ContentInventory, @core.ContentDiscoveryError]] {
  Ready(discover_content_result(config))
}
