///|
fn trim_host_path(path : String) -> String {
  path.trim().to_string()
}

///|
fn copy_string_array_without_last(source : Array[String]) -> Array[String] {
  let copied : Array[String] = []
  if source.length() <= 1 {
    return copied
  }
  for index in 0..<(source.length() - 1) {
    copied.push(source[index])
  }
  copied
}

///|
fn normalize_host_path_text(path : String, absolute : Bool) -> String {
  let mut normalized_segments : Array[String] = []
  for segment_view in path.split("/") {
    let segment = segment_view.to_string()
    if segment == "" || segment == "." {
      continue
    }
    if segment == ".." {
      if absolute {
        if !normalized_segments.is_empty() {
          normalized_segments = copy_string_array_without_last(
            normalized_segments,
          )
        }
      } else if !normalized_segments.is_empty() &&
        normalized_segments[normalized_segments.length() - 1] != ".." {
        normalized_segments = copy_string_array_without_last(
          normalized_segments,
        )
      } else {
        normalized_segments.push(segment)
      }
      continue
    }
    normalized_segments.push(segment)
  }
  if absolute {
    if normalized_segments.is_empty() {
      "/"
    } else {
      "/" + normalized_segments.iter().join("/")
    }
  } else if normalized_segments.is_empty() {
    "."
  } else {
    normalized_segments.iter().join("/")
  }
}

///|
fn host_path_error(path : String, reason : String) -> @core.ConfigError {
  @core.ConfigError::InvalidPath(path~, reason~)
}

///|
pub fn dirname_host_path(path : String) -> String {
  let trimmed = trim_host_path(path)
  if trimmed.is_empty() || trimmed == "." {
    return "."
  }
  let normalized = normalize_host_path_text(trimmed, trimmed.has_prefix("/"))
  if normalized == "/" {
    return "/"
  }
  let mut last_slash : Int? = None
  for index in 0..<normalized.length() {
    if normalized[index:index + 1].to_string() == "/" {
      last_slash = Some(index)
    }
  }
  match last_slash {
    Some(0) => "/"
    Some(index) => normalized[:index].to_string()
    None => "."
  }
}

///|
pub fn join_host_path(
  base : String,
  child : String,
) -> String raise @core.PathPolicyError {
  let normalized_child = @core.normalize_relative_path(child)
  let trimmed_base = trim_host_path(base)
  if trimmed_base == "" || trimmed_base == "." {
    normalized_child
  } else if trimmed_base == "/" {
    "/" + normalized_child
  } else if trimmed_base.has_suffix("/") {
    trimmed_base + normalized_child
  } else {
    trimmed_base + "/" + normalized_child
  }
}

///|
pub fn resolve_host_path_from_cwd_result(
  path : String,
) -> Result[String, @core.ConfigError] {
  let trimmed = trim_host_path(path)
  if trimmed.is_empty() {
    return Err(host_path_error(path, "empty host path"))
  }
  if trimmed.has_prefix("/") {
    return Ok(normalize_host_path_text(trimmed, true))
  }
  let cwd = match @env.current_dir() {
    Some(cwd) => normalize_host_path_text(cwd, true)
    None =>
      return Err(
        host_path_error(path, "current working directory is unavailable"),
      )
  }
  let combined = if cwd == "/" { "/" + trimmed } else { cwd + "/" + trimmed }
  Ok(normalize_host_path_text(combined, true))
}
