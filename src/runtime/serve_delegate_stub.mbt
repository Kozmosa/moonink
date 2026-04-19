///|
pub fn exec_native_serve_delegate(
  command : String,
) -> Unit raise @core.ProjectIOError {
  ignore(nul_terminated_command_bytes(command))
  raise @core.project_io_error(
    "serve_delegate", command, "native serve delegation is only available on native targets",
  )
}
