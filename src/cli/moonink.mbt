///|
/// Public command model for the MoonInk CLI.
pub enum CliCommand {
  Help
  Onboard
  Build
  Check
  Serve
  Unknown(String)
} derive(Debug, Eq)

///|
pub struct BuildCliOptions {
  config_path : String
  output_dir : String?
} derive(Debug, Eq)

///|
pub impl Show for BuildCliOptions with output(self, logger) {
  logger.write_string("{ config_path: \"")
  logger.write_string(self.config_path)
  logger.write_string("\", output_dir: ")
  match self.output_dir {
    Some(path) => {
      logger.write_string("Some(\"")
      logger.write_string(path)
      logger.write_string("\")")
    }
    None => logger.write_string("None")
  }
  logger.write_string(" }")
}

///|
pub struct CheckCliOptions {
  config_path : String
  output_dir : String?
} derive(Debug, Eq)

///|
pub impl Show for CheckCliOptions with output(self, logger) {
  logger.write_string("{ config_path: \"")
  logger.write_string(self.config_path)
  logger.write_string("\", output_dir: ")
  match self.output_dir {
    Some(path) => {
      logger.write_string("Some(\"")
      logger.write_string(path)
      logger.write_string("\")")
    }
    None => logger.write_string("None")
  }
  logger.write_string(" }")
}

///|
pub struct ServeCliOptions {
  config_path : String
  output_dir : String?
  host : String
  port : Int
} derive(Debug, Eq)

///|
pub impl Show for ServeCliOptions with output(self, logger) {
  logger.write_string("{ config_path: \"")
  logger.write_string(self.config_path)
  logger.write_string("\", output_dir: ")
  match self.output_dir {
    Some(path) => {
      logger.write_string("Some(\"")
      logger.write_string(path)
      logger.write_string("\")")
    }
    None => logger.write_string("None")
  }
  logger.write_string(", host: \"")
  logger.write_string(self.host)
  logger.write_string("\", port: ")
  logger.write_string(self.port.to_string())
  logger.write_string(" }")
}

///|
pub(all) enum ParsedCliRequest {
  Help
  Onboard
  Build(BuildCliOptions)
  Check(CheckCliOptions)
  Serve(ServeCliOptions)
  Unknown(String)
  Invalid(String)
} derive(Debug, Eq)

///|
pub impl Show for ParsedCliRequest with output(self, logger) {
  match self {
    ParsedCliRequest::Help => logger.write_string("Help")
    ParsedCliRequest::Onboard => logger.write_string("Onboard")
    ParsedCliRequest::Build(options) => {
      logger.write_string("Build(")
      logger.write_string(options.to_string())
      logger.write_string(")")
    }
    ParsedCliRequest::Check(options) => {
      logger.write_string("Check(")
      logger.write_string(options.to_string())
      logger.write_string(")")
    }
    ParsedCliRequest::Serve(options) => {
      logger.write_string("Serve(")
      logger.write_string(options.to_string())
      logger.write_string(")")
    }
    ParsedCliRequest::Unknown(command) => {
      logger.write_string("Unknown(\"")
      logger.write_string(command)
      logger.write_string("\")")
    }
    ParsedCliRequest::Invalid(message) => {
      logger.write_string("Invalid(\"")
      logger.write_string(message.replace(old="\n", new="\\n"))
      logger.write_string("\")")
    }
  }
}

///|
pub impl Show for CliCommand with output(self, logger) {
  match self {
    CliCommand::Help => logger.write_string("Help")
    CliCommand::Onboard => logger.write_string("Onboard")
    CliCommand::Build => logger.write_string("Build")
    CliCommand::Check => logger.write_string("Check")
    CliCommand::Serve => logger.write_string("Serve")
    CliCommand::Unknown(command) => {
      logger.write_string("Unknown(\"")
      logger.write_string(command)
      logger.write_string("\")")
    }
  }
}

///|
/// Pure execution result for the CLI.
pub(all) struct CliOutcome {
  exit_code : Int
  message : String
} derive(Debug, Eq)

///|
fn parse_command_token(command : String) -> CliCommand {
  if command == "help" {
    CliCommand::Help
  } else if command == "onboard" {
    CliCommand::Onboard
  } else if command == "build" {
    CliCommand::Build
  } else if command == "check" {
    CliCommand::Check
  } else if command == "serve" {
    CliCommand::Serve
  } else {
    CliCommand::Unknown(command)
  }
}

///|
fn parse_port_value(raw : String) -> Int? {
  if raw == "0" {
    return Some(0)
  }
  let known_ports = [
    ("3000", 3000),
    ("4173", 4173),
    ("8080", 8080),
    ("8000", 8000),
  ]
  for entry in known_ports {
    let (text, value) = entry
    if raw == text {
      return Some(value)
    }
  }
  None
}

///|
fn next_flag_value(
  command_name : String,
  flag_name : String,
  tokens : Array[String],
  index : Int,
) -> Result[String, String] {
  if index + 1 >= tokens.length() {
    return Err(
      "[\{command_name}] invalid arguments\nreason: missing value for \{flag_name}",
    )
  }
  Ok(tokens[index + 1])
}

///|
fn parse_build_options(
  tokens : Array[String],
) -> Result[BuildCliOptions, String] {
  let mut config_path = "moonink.json"
  let mut output_dir : String? = None
  let mut index = 0
  while index < tokens.length() {
    let token = tokens[index]
    if token == "--config" {
      let value = match next_flag_value("build", "--config", tokens, index) {
        Ok(value) => value
        Err(err) => return Err(err)
      }
      config_path = value
      index = index + 2
    } else if token == "--output" {
      let value = match next_flag_value("build", "--output", tokens, index) {
        Ok(value) => value
        Err(err) => return Err(err)
      }
      output_dir = Some(value)
      index = index + 2
    } else if token == "--host" || token == "--port" {
      return Err(
        "[build] invalid arguments\nreason: \{token} is only supported for serve",
      )
    } else if token.has_prefix("--") {
      return Err("[build] invalid arguments\nreason: unknown flag \{token}")
    } else {
      return Err(
        "[build] invalid arguments\nreason: unexpected positional argument \{token}",
      )
    }
  }
  Ok({ config_path, output_dir })
}

///|
fn parse_check_options(
  tokens : Array[String],
) -> Result[CheckCliOptions, String] {
  let mut config_path = "moonink.json"
  let mut output_dir : String? = None
  let mut index = 0
  while index < tokens.length() {
    let token = tokens[index]
    if token == "--config" {
      let value = match next_flag_value("check", "--config", tokens, index) {
        Ok(value) => value
        Err(err) => return Err(err)
      }
      config_path = value
      index = index + 2
    } else if token == "--output" {
      let value = match next_flag_value("check", "--output", tokens, index) {
        Ok(value) => value
        Err(err) => return Err(err)
      }
      output_dir = Some(value)
      index = index + 2
    } else if token == "--host" || token == "--port" {
      return Err(
        "[check] invalid arguments\nreason: \{token} is only supported for serve",
      )
    } else if token.has_prefix("--") {
      return Err("[check] invalid arguments\nreason: unknown flag \{token}")
    } else {
      return Err(
        "[check] invalid arguments\nreason: unexpected positional argument \{token}",
      )
    }
  }
  Ok({ config_path, output_dir })
}

///|
fn parse_serve_options(
  tokens : Array[String],
) -> Result[ServeCliOptions, String] {
  let mut config_path = "moonink.json"
  let mut output_dir : String? = None
  let mut host = DEFAULT_SERVE_HOST
  let mut port = DEFAULT_SERVE_PORT
  let mut index = 0
  while index < tokens.length() {
    let token = tokens[index]
    if token == "--config" {
      let value = match next_flag_value("serve", "--config", tokens, index) {
        Ok(value) => value
        Err(err) => return Err(err)
      }
      config_path = value
      index = index + 2
    } else if token == "--output" {
      let value = match next_flag_value("serve", "--output", tokens, index) {
        Ok(value) => value
        Err(err) => return Err(err)
      }
      output_dir = Some(value)
      index = index + 2
    } else if token == "--host" {
      let value = match next_flag_value("serve", "--host", tokens, index) {
        Ok(value) => value
        Err(err) => return Err(err)
      }
      host = value
      index = index + 2
    } else if token == "--port" {
      let value = match next_flag_value("serve", "--port", tokens, index) {
        Ok(value) => value
        Err(err) => return Err(err)
      }
      let parsed = match parse_port_value(value) {
        Some(port) => port
        None =>
          return Err("[serve] invalid arguments\nreason: invalid port \{value}")
      }
      port = parsed
      index = index + 2
    } else if token.has_prefix("--") {
      return Err("[serve] invalid arguments\nreason: unknown flag \{token}")
    } else {
      return Err(
        "[serve] invalid arguments\nreason: unexpected positional argument \{token}",
      )
    }
  }
  Ok({ config_path, output_dir, host, port })
}

///|
fn normalize_parse_argv(argv : Array[String]) -> Array[String] {
  if argv.is_empty() {
    []
  } else if argv.length() == 1 {
    let first = argv[0]
    if first == "moonink" {
      []
    } else {
      argv
    }
  } else {
    let first = argv[0]
    if first == "moonink" {
      argv[1:].to_array()
    } else {
      argv
    }
  }
}

///|
pub fn parse_cli_request(argv : Array[String]) -> ParsedCliRequest {
  let tokens = normalize_parse_argv(argv)
  if tokens.is_empty() {
    return ParsedCliRequest::Help
  }
  let command = parse_command_token(tokens[0])
  let payload = tokens[1:].to_array()
  match command {
    CliCommand::Help =>
      if payload.is_empty() {
        ParsedCliRequest::Help
      } else {
        ParsedCliRequest::Invalid(
          "[help] invalid arguments\nreason: help does not accept flags or positional arguments",
        )
      }
    CliCommand::Onboard =>
      if payload.is_empty() {
        ParsedCliRequest::Onboard
      } else {
        ParsedCliRequest::Invalid(
          "[onboard] invalid arguments\nreason: onboard does not accept flags or positional arguments",
        )
      }
    CliCommand::Build =>
      match parse_build_options(payload) {
        Ok(options) => ParsedCliRequest::Build(options)
        Err(message) => ParsedCliRequest::Invalid(message)
      }
    CliCommand::Check =>
      match parse_check_options(payload) {
        Ok(options) => ParsedCliRequest::Check(options)
        Err(message) => ParsedCliRequest::Invalid(message)
      }
    CliCommand::Serve =>
      match parse_serve_options(payload) {
        Ok(options) => ParsedCliRequest::Serve(options)
        Err(message) => ParsedCliRequest::Invalid(message)
      }
    CliCommand::Unknown(command_name) => ParsedCliRequest::Unknown(command_name)
  }
}

///|
/// Parse either raw CLI arguments like `["build"]` or full argv like
/// `["moonink", "build"]` into a command model.
pub fn parse_cli_command(argv : Array[String]) -> CliCommand {
  match parse_cli_request(argv) {
    ParsedCliRequest::Help => CliCommand::Help
    ParsedCliRequest::Onboard => CliCommand::Onboard
    ParsedCliRequest::Build(_) => CliCommand::Build
    ParsedCliRequest::Check(_) => CliCommand::Check
    ParsedCliRequest::Serve(_) => CliCommand::Serve
    ParsedCliRequest::Unknown(command_name) => CliCommand::Unknown(command_name)
    ParsedCliRequest::Invalid(_) => CliCommand::Help
  }
}

///|
/// Execute the pure CLI model so tests can validate command parsing and dispatch
/// without performing filesystem side effects.
pub fn cli_run(argv : Array[String]) -> CliOutcome {
  dispatch_cli_request(parse_cli_request(argv))
}

///|
/// Execute the runtime CLI entry. Side-effecting commands must cross the
/// explicit runtime IO boundary before touching filesystem-backed features.
pub fn cli_exec(argv : Array[String]) -> CliOutcome {
  run_runtime_cli_request(parse_cli_request(argv))
}

///|
fn dispatch_cli_request(request : ParsedCliRequest) -> CliOutcome {
  match request {
    ParsedCliRequest::Help => run_help_command()
    ParsedCliRequest::Onboard => run_onboard_command_pure()
    ParsedCliRequest::Build(options) => run_build_command(options)
    ParsedCliRequest::Check(options) => run_check_command(options)
    ParsedCliRequest::Serve(options) => run_serve_command(options)
    ParsedCliRequest::Unknown(command_name) => run_unknown_command(command_name)
    ParsedCliRequest::Invalid(message) => { exit_code: 1, message }
  }
}

///|
/// Runtime IO boundary for side-effecting CLI command execution.
pub fn run_runtime_cli_request(request : ParsedCliRequest) -> CliOutcome {
  match request {
    ParsedCliRequest::Help => run_help_command()
    ParsedCliRequest::Onboard => run_native_onboard_command()
    ParsedCliRequest::Build(options) => run_native_build_command(options)
    ParsedCliRequest::Check(options) => run_native_check_command(options)
    ParsedCliRequest::Serve(options) => run_native_serve_command(options)
    ParsedCliRequest::Unknown(command_name) => run_unknown_command(command_name)
    ParsedCliRequest::Invalid(message) => { exit_code: 1, message }
  }
}
