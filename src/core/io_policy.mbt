///|
/// Shared path-policy failures introduced by IO-P4.
pub(all) suberror PathPolicyError {
  EmptyPath(String)
  AbsolutePath(String)
  ParentTraversal(String)
} derive(Debug, Eq)

///|
/// MoonInk currently treats text files as UTF-8 at the policy layer.
pub const TEXT_ENCODING_NAME : String = "utf-8"

///|
pub fn format_path_policy_error(err : PathPolicyError) -> String {
  match err {
    PathPolicyError::EmptyPath(path) => "empty relative path: \{path}"
    PathPolicyError::AbsolutePath(path) => "absolute paths are not allowed: \{path}"
    PathPolicyError::ParentTraversal(path) =>
      "parent traversal is not allowed: \{path}"
  }
}

///|
pub impl Show for PathPolicyError with output(self, logger) {
  match self {
    PathPolicyError::EmptyPath(path) => {
      logger.write_string("EmptyPath(\"")
      logger.write_string(path)
      logger.write_string("\")")
    }
    PathPolicyError::AbsolutePath(path) => {
      logger.write_string("AbsolutePath(\"")
      logger.write_string(path)
      logger.write_string("\")")
    }
    PathPolicyError::ParentTraversal(path) => {
      logger.write_string("ParentTraversal(\"")
      logger.write_string(path)
      logger.write_string("\")")
    }
  }
}

///|
pub fn normalize_relative_path(path : String) -> String raise PathPolicyError {
  let trimmed = path.trim().to_string()
  if trimmed.is_empty() {
    raise PathPolicyError::EmptyPath(path)
  }
  if trimmed.has_prefix("/") {
    raise PathPolicyError::AbsolutePath(trimmed)
  }
  let normalized_segments = []
  for segment_view in trimmed.split("/") {
    let segment = segment_view.to_string()
    if segment == "" || segment == "." {
      continue
    }
    if segment == ".." {
      raise PathPolicyError::ParentTraversal(trimmed)
    }
    normalized_segments.push(segment)
  }
  if normalized_segments.is_empty() {
    raise PathPolicyError::EmptyPath(path)
  }
  normalized_segments.iter().join("/")
}

///|
pub fn dirname_relative_path(path : String) -> String raise PathPolicyError {
  let normalized = normalize_relative_path(path)
  let segments = normalized.split("/").map(StringView::to_string).collect()
  if segments.length() <= 1 {
    "."
  } else {
    let parents = []
    let parent_count = segments.length() - 1
    for i in 0..<parent_count {
      parents.push(segments[i])
    }
    parents.iter().join("/")
  }
}

///|
pub fn join_relative_path(
  base : String,
  child : String,
) -> String raise PathPolicyError {
  let normalized_child = normalize_relative_path(child)
  if base == "." || base == "" {
    normalized_child
  } else {
    let normalized_base = normalize_relative_path(base)
    "\{normalized_base}/\{normalized_child}"
  }
}
