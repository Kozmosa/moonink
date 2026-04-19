///|
pub(all) struct SpawnedProcess {
  pid : Int
} derive(Debug, Eq)

///|
pub fn sleep_millis(milliseconds : Int) -> Unit {
  if milliseconds <= 0 {
    return
  }
  sleep_millis_impl(milliseconds)
}

///|
pub fn spawn_shell_command_result(
  command : String,
) -> Result[SpawnedProcess, @core.ProjectIOError] {
  if command.is_empty() {
    return Err(
      @core.project_io_error(
        "spawn_process", command, "command must not be empty",
      ),
    )
  }
  let pid = spawn_shell_command_pid(command)
  if pid <= 0 {
    Err(
      @core.project_io_error(
        "spawn_process", command, "failed to spawn child process",
      ),
    )
  } else {
    Ok({ pid, })
  }
}

///|
pub fn poll_spawned_process_result(
  process : SpawnedProcess,
) -> Result[Int, @core.ProjectIOError] {
  let status = poll_child_process_status(process.pid)
  if status < 0 {
    Err(
      @core.project_io_error(
        "poll_process",
        process.pid.to_string(),
        "failed to poll child process",
      ),
    )
  } else {
    Ok(status)
  }
}

///|
pub fn terminate_spawned_process_result(
  process : SpawnedProcess,
) -> Result[Unit, @core.ProjectIOError] {
  let status = terminate_child_process_signal(process.pid)
  if status != 0 {
    Err(
      @core.project_io_error(
        "terminate_process",
        process.pid.to_string(),
        "failed to terminate child process",
      ),
    )
  } else {
    Ok(())
  }
}
