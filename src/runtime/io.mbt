///|
/// Sync runtime IO facade introduced by IO-P5.
pub fn io_read_file_to_string(
  path : String,
) -> String raise @core.ProjectIOError {
  @fs.read_file_to_string(path) catch {
    err => raise @core.project_io_error("read_file", path, err.to_string())
  }
}

///|
pub fn io_path_exists(path : String) -> Bool {
  @fs.path_exists(path)
}

///|
pub fn io_is_dir(path : String) -> Bool raise @core.ProjectIOError {
  @fs.is_dir(path) catch {
    err =>
      raise @core.project_io_error("inspect_directory", path, err.to_string())
  }
}

///|
pub fn io_is_file(path : String) -> Bool raise @core.ProjectIOError {
  @fs.is_file(path) catch {
    err => raise @core.project_io_error("inspect_path", path, err.to_string())
  }
}

///|
pub fn io_read_dir(path : String) -> Array[String] raise @core.ProjectIOError {
  @fs.read_dir(path) catch {
    err => raise @core.project_io_error("read_directory", path, err.to_string())
  }
}

///|
pub fn io_create_dir(path : String) -> Unit raise @core.ProjectIOError {
  @fs.create_dir(path) catch {
    err =>
      raise @core.project_io_error("create_directory", path, err.to_string())
  }
}

///|
pub fn io_remove_file(path : String) -> Unit raise @core.ProjectIOError {
  @fs.remove_file(path) catch {
    err => raise @core.project_io_error("remove_file", path, err.to_string())
  }
}

///|
pub fn io_remove_dir(path : String) -> Unit raise @core.ProjectIOError {
  @fs.remove_dir(path) catch {
    err =>
      raise @core.project_io_error("remove_directory", path, err.to_string())
  }
}

///|
pub fn io_ensure_dir(path : String) -> Unit raise @core.ProjectIOError {
  if path == "." || path == "" {
    return
  }
  if io_path_exists(path) {
    let is_dir = io_is_dir(path)
    if !is_dir {
      raise @core.project_io_error(
        "create_directory", path, "path exists and is not a directory",
      )
    }
    return
  }
  let parent = @core.dirname_relative_path(path) catch {
    err =>
      raise @core.project_io_error(
        "create_directory",
        path,
        @core.format_path_policy_error(err),
      )
  }
  io_ensure_dir(parent)
  io_create_dir(path)
}

///|
pub fn io_remove_dir_all(path : String) -> Unit raise @core.ProjectIOError {
  if !io_path_exists(path) {
    return
  }
  let is_dir = io_is_dir(path)
  if !is_dir {
    io_remove_file(path)
    return
  }
  let entries = io_read_dir(path)
  for entry in entries {
    let child = @core.join_relative_path(path, entry) catch {
      err =>
        raise @core.project_io_error(
          "remove_directory",
          path,
          @core.format_path_policy_error(err),
        )
    }
    if io_is_dir(child) {
      io_remove_dir_all(child)
    } else {
      io_remove_file(child)
    }
  }
  io_remove_dir(path)
}

///|
pub fn io_write_string(
  path : String,
  content : String,
) -> Unit raise @core.ProjectIOError {
  @fs.write_string_to_file(path, content) catch {
    err => raise @core.project_io_error("write_file", path, err.to_string())
  }
}
