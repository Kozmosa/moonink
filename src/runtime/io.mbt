///|
/// Sync runtime IO facade introduced by IO-P5.
pub fn io_read_file_to_string(path : String) -> String raise @core.ProjectIOError {
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
    err =>
      raise @core.project_io_error("read_directory", path, err.to_string())
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
pub fn io_write_string(
  path : String,
  content : String,
) -> Unit raise @core.ProjectIOError {
  @fs.write_string_to_file(path, content) catch {
    err => raise @core.project_io_error("write_file", path, err.to_string())
  }
}
