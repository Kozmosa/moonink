///|
/// Shared help text for the cold-start CLI scaffold.
pub fn cli_help_text() -> String {
  let text =
    #|MoonInk CLI scaffold
    #|
    #|Usage:
    #|  moonink help
    #|  moonink new [project-name]
    #|  moonink build
    #|  moonink serve
    #|
    #|Status:
    #|  This is the cold-start scaffold. All command implementations are
    #|  placeholders that establish module boundaries for later phases.
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
