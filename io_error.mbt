///|
/// Shared project-owned filesystem error payload introduced by IO-P3.
pub(all) struct ProjectIOError {
  operation : String
  path : String
  detail : String
} derive(Show, Eq)

///|
pub fn project_io_error(operation : String, path : String, detail : String) -> ProjectIOError {
  { operation, path, detail }
}

///|
pub fn format_project_io_error(error : ProjectIOError) -> String {
  "operation: \{error.operation}\npath: \{error.path}\ndetail: \{error.detail}"
}
