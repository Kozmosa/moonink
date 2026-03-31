///|
/// Runtime IO boundary for side-effecting CLI command execution.
///
/// This module is the explicit seam introduced by IO-P2. Runtime-facing
/// command dispatch should enter here before reaching any filesystem-backed
/// feature workflow.
pub fn run_runtime_cli_command(command : CliCommand) -> CliOutcome {
  match command {
    CliCommand::Help => run_help_command()
    CliCommand::New(project_name) =>
      run_runtime_io_task(emit_starter_project_task(plan_starter_project(project_name)))
    CliCommand::Build => run_build_command_runtime()
    CliCommand::Serve => run_serve_command()
    CliCommand::Unknown(command_name) => run_unknown_command(command_name)
  }
}
