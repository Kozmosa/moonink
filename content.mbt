///|
/// Content discovery failures for build phase 1a.
pub(all) suberror ContentDiscoveryError {
  IOError(ProjectIOError)
  InvalidPath(path~ : String, reason~ : String)
  MissingDirectory(String)
  NotDirectory(String)
} derive(Show, Eq)

///|
/// Real content discovery summary for the build phase 1a pipeline.
pub(all) struct ContentInventory {
  docs_root : String
  articles_root : String
  docs_files : Array[String]
  article_files : Array[String]
  discovered_docs : Int
  discovered_articles : Int
  discovered_documents : Int
  discovered_assets : Int
  note : String
} derive(Show, Eq)

///|
fn path_operation_error(operation : String, path : String, err : @fs.IOError) -> ContentDiscoveryError {
  ContentDiscoveryError::IOError(project_io_error(operation, path, err.to_string()))
}

///|
fn content_path_policy_error(path : String, err : PathPolicyError) -> ContentDiscoveryError {
  ContentDiscoveryError::InvalidPath(path=path, reason=err.to_string())
}

///|
fn join_content_path(base : String, child : String) -> String raise ContentDiscoveryError {
  join_relative_path(base, child) catch {
    err => raise content_path_policy_error(child, err)
  }
}

///|
fn collect_markdown_files(root : String) -> Array[String] raise ContentDiscoveryError {
  if !@fs.path_exists(root) {
    raise ContentDiscoveryError::MissingDirectory(root)
  }
  let is_dir = @fs.is_dir(root) catch {
    err => raise path_operation_error("inspect_directory", root, err)
  }
  if !is_dir {
    raise ContentDiscoveryError::NotDirectory(root)
  }
  let discovered = []
  let entries = @fs.read_dir(root) catch {
    err => raise path_operation_error("read_directory", root, err)
  }
  for entry in entries {
    let full_path = join_content_path(root, entry)
    let is_dir = @fs.is_dir(full_path) catch {
      err => raise path_operation_error("inspect_path", full_path, err)
    }
    if is_dir {
      let nested = collect_markdown_files(full_path)
      for file in nested {
        discovered.push(file)
      }
      continue
    }
    let is_file = @fs.is_file(full_path) catch {
      err => raise path_operation_error("inspect_path", full_path, err)
    }
    if is_file && full_path.has_suffix(".md") {
      discovered.push(full_path)
    }
  }
  discovered.sort()
  discovered
}

///|
pub fn discover_content(config : LoadedConfig) -> ContentInventory raise ContentDiscoveryError {
  let docs_root = join_content_path(config.project_root, config.docs_dir)
  let articles_root = join_content_path(config.project_root, config.articles_dir)
  let docs_files = collect_markdown_files(docs_root)
  let article_files = collect_markdown_files(articles_root)
  let discovered_docs = docs_files.length()
  let discovered_articles = article_files.length()
  {
    docs_root,
    articles_root,
    docs_files,
    article_files,
    discovered_docs,
    discovered_articles,
    discovered_documents: discovered_docs + discovered_articles,
    discovered_assets: 0,
    note: "Content discovery now scans the docs/articles trees for Markdown files with normalized relative paths.",
  }
}
