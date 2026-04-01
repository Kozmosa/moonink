///|
/// Public command model for the MoonInk CLI scaffold.
pub enum CliCommand {
  Help
  New(String?)
  Build
  Serve
  Unknown(String)
} derive(Show, Eq)

///|
/// Pure execution result for the CLI scaffold.
pub(all) struct CliOutcome {
  exit_code : Int
  message : String
} derive(Show, Eq)

///|
fn parse_command_and_payload(
  command : String,
  payload : Array[String],
) -> CliCommand {
  if command == "help" {
    CliCommand::Help
  } else if command == "new" {
    if payload.is_empty() {
      CliCommand::New(None)
    } else {
      CliCommand::New(Some(payload[0]))
    }
  } else if command == "build" {
    CliCommand::Build
  } else if command == "serve" {
    CliCommand::Serve
  } else {
    CliCommand::Unknown(command)
  }
}

///|
/// Parse either raw CLI arguments like `["build"]` or full argv like
/// `["moonink", "build"]` into a command model.
pub fn parse_cli_command(argv : Array[String]) -> CliCommand {
  if argv.is_empty() {
    CliCommand::Help
  } else if argv.length() == 1 {
    let first = argv[0]
    if first == "moonink" {
      CliCommand::Help
    } else {
      parse_command_and_payload(first, [])
    }
  } else {
    let first = argv[0]
    if first == "moonink" {
      parse_command_and_payload(argv[1], argv[2:][:].to_array())
    } else {
      parse_command_and_payload(first, argv[1:][:].to_array())
    }
  }
}

///|
/// Execute the pure CLI model so tests can validate command parsing and dispatch
/// without performing filesystem side effects.
pub fn cli_run(argv : Array[String]) -> CliOutcome {
  dispatch_cli_command(parse_cli_command(argv))
}

///|
/// Execute the runtime CLI entry. Side-effecting commands must cross the
/// explicit runtime IO boundary before touching filesystem-backed features.
pub fn cli_exec(argv : Array[String]) -> CliOutcome {
  run_runtime_cli_command(parse_cli_command(argv))
}

///|
fn dispatch_cli_command(command : CliCommand) -> CliOutcome {
  match command {
    CliCommand::Help => run_help_command()
    CliCommand::New(project_name) => run_new_command(project_name)
    CliCommand::Build => run_build_command()
    CliCommand::Serve => run_serve_command()
    CliCommand::Unknown(command_name) => run_unknown_command(command_name)
  }
}
