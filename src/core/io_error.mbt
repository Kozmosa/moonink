///|
/// Shared project-owned filesystem error payload introduced by IO-P3.
pub(all) suberror ProjectIOError {
  Failure(operation~ : String, path~ : String, detail~ : String)
} derive(Show, Eq)

///|
pub fn project_io_error(
  operation : String,
  path : String,
  detail : String,
) -> ProjectIOError {
  ProjectIOError::Failure(operation~, path~, detail~)
}

///|
pub fn format_project_io_error(error : ProjectIOError) -> String {
  match error {
    ProjectIOError::Failure(operation~, path~, detail~) =>
      "operation: \{operation}\npath: \{path}\ndetail: \{detail}"
  }
}
