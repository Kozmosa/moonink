///|
/// Content discovery failures for build phase 1a.
pub(all) suberror ContentDiscoveryError {
  IOError(ProjectIOError)
  InvalidPath(path~ : String, reason~ : String)
  MissingDirectory(String)
  NotDirectory(String)
} derive(Show, Eq)

///|
/// Workspace discovery plan introduced by IO-P9.
pub(all) struct ContentDiscoveryPlan {
  docs_root : String
  articles_root : String
  workspace_roots : Array[String]
  note : String
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
fn io_discovery_error(err : ProjectIOError) -> ContentDiscoveryError {
  ContentDiscoveryError::IOError(err)
}

///|
pub fn plan_content_discovery(
  config : LoadedConfig,
) -> ContentDiscoveryPlan raise ContentDiscoveryError {
  let docs_root = join_content_path(config.project_root, config.docs_dir)
  let articles_root = join_content_path(config.project_root, config.articles_dir)
  {
    docs_root,
    articles_root,
    workspace_roots: [docs_root, articles_root],
    note:
      "Content discovery planning now freezes workspace roots before runtime traversal begins.",
  }
}

///|
fn collect_markdown_files(root : String) -> Array[String] raise ContentDiscoveryError {
  if !io_path_exists(root) {
    raise ContentDiscoveryError::MissingDirectory(root)
  }
  let is_dir = io_is_dir(root) catch {
    err => raise io_discovery_error(err)
  }
  if !is_dir {
    raise ContentDiscoveryError::NotDirectory(root)
  }
  let discovered = []
  let entries = io_read_dir(root) catch {
    err => raise io_discovery_error(err)
  }
  for entry in entries {
    let full_path = join_content_path(root, entry)
    let is_dir = io_is_dir(full_path) catch {
      err => raise io_discovery_error(err)
    }
    if is_dir {
      let nested = collect_markdown_files(full_path)
      for file in nested {
        discovered.push(file)
      }
      continue
    }
    let is_file = io_is_file(full_path) catch {
      err => raise io_discovery_error(err)
    }
    if is_file && full_path.has_suffix(".md") {
      discovered.push(full_path)
    }
  }
  discovered.sort()
  discovered
}

///|
pub fn discover_planned_content(
  plan : ContentDiscoveryPlan,
) -> ContentInventory raise ContentDiscoveryError {
  let docs_files = collect_markdown_files(plan.docs_root)
  let article_files = collect_markdown_files(plan.articles_root)
  let discovered_docs = docs_files.length()
  let discovered_articles = article_files.length()
  {
    docs_root: plan.docs_root,
    articles_root: plan.articles_root,
    docs_files,
    article_files,
    discovered_docs,
    discovered_articles,
    discovered_documents: discovered_docs + discovered_articles,
    discovered_assets: 0,
    note:
      "Content discovery now scans planned workspace roots for Markdown files through the runtime IO boundary.",
  }
}

///|
pub fn discover_content_result(
  config : LoadedConfig,
) -> Result[ContentInventory, ContentDiscoveryError] {
  let plan = try plan_content_discovery(config) catch {
    err => return Err(err)
  }
  try discover_planned_content(plan) catch {
    err => Err(err)
  } noraise {
    inventory => Ok(inventory)
  }
}
