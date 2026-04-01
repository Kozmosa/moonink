///|
/// Shared help text for the CLI.
pub fn cli_help_text() -> String {
  let text =
    #|MoonInk CLI
    #|
    #|Usage:
    #|  moonink help
    #|  moonink onboard
    #|  moonink build
    #|  moonink serve
    #|
    #|Status:
    #|  This is the scaffold phase. Command implementations are being
    #|  progressively wired to real feature workflows.
    #|
  text
}

///|
fn run_help_command() -> CliOutcome {
  { exit_code: 0, message: cli_help_text() }
}

///|
fn run_unknown_command(command_name : String) -> CliOutcome {
  {
    exit_code: 1,
    message: "Unknown command: \{command_name}\n\n\{cli_help_text()}",
  }
}
