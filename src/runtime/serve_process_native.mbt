///|
#borrow(_command)
extern "c" fn spawn_shell_command_ffi(_command : Bytes) -> Int = "moonink_spawn_shell_command"

///|
extern "c" fn poll_child_process_ffi(pid : Int) -> Int = "moonink_poll_child_process"

///|
extern "c" fn terminate_child_process_ffi(pid : Int) -> Int = "moonink_terminate_child_process"

///|
extern "c" fn sleep_millis_ffi(milliseconds : Int) -> Unit = "moonink_sleep_millis"

///|
fn spawn_shell_command_pid(command : String) -> Int {
  spawn_shell_command_ffi(nul_terminated_command_bytes(command))
}

///|
fn poll_child_process_status(pid : Int) -> Int {
  poll_child_process_ffi(pid)
}

///|
fn terminate_child_process_signal(pid : Int) -> Int {
  terminate_child_process_ffi(pid)
}

///|
fn sleep_millis_impl(milliseconds : Int) -> Unit {
  sleep_millis_ffi(milliseconds)
}
