///|
pub fn validate_native_preview_startup_result(
  host : String,
  port : Int,
) -> Result[Unit, @core.ProjectIOError] {
  native_preview_startup_check_result(host, port)
}
