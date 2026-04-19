///|
#borrow(_command)
extern "c" fn exec_shell_command_ffi(_command : Bytes) -> Int = "moonink_exec_shell_command"

///|
pub fn exec_native_serve_delegate(
  command : String,
) -> Unit raise @core.ProjectIOError {
  let code = exec_shell_command_ffi(nul_terminated_command_bytes(command))
  raise @core.project_io_error(
    "serve_delegate",
    command,
    "failed to exec delegated native serve command (errno: \{code})",
  )
}
