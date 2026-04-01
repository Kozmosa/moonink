///|
/// Pure onboard command — reports what would be done without filesystem access.
fn run_onboard_command_pure() -> CliOutcome {
  {
    exit_code: 0,
    message: "[onboard] runtime execution required\nstatus: use cli_exec or the runtime IO boundary to scan files and generate config",
  }
}

///|
/// Runtime onboard command — scans current directory and generates moonink.json.
fn run_native_onboard_command() -> CliOutcome {
  @runtime.run_native_runtime_io_task_with_policy(
    @runtime.RuntimeIOTask::Ready(run_onboard_command_runtime()),
    @runtime.native_runtime_adapter().policy,
  )
}

///|
fn run_onboard_command_runtime() -> CliOutcome {
  // Check if moonink.json already exists
  if @runtime.io_path_exists("moonink.json") {
    return {
      exit_code: 1,
      message: "[onboard] moonink.json already exists\nstatus: aborted to avoid overwriting existing config",
    }
  }
  // Generate default config JSON
  let config_content =
    #|{
    #|  "site_name": "My Site",
    #|  "content_dir": ".",
    #|  "output_dir": "dist",
    #|  "exclude": [".obsidian", "dist", ".git", "node_modules"],
    #|  "route_style": "pretty"
    #|}
  @runtime.io_write_string("moonink.json", config_content) catch {
    err =>
      return {
        exit_code: 1,
        message: "[onboard] failed to write moonink.json\n\{@core.format_project_io_error(err)}",
      }
  }
  {
    exit_code: 0,
    message: "[onboard] moonink.json created\nstatus: config generated, run `moonink build` to generate your site",
  }
}
