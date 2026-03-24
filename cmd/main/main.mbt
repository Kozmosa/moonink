///|
fn normalize_runtime_argv(raw_argv : Array[String]) -> Array[String] {
  if raw_argv.length() >= 3 && raw_argv[1].has_suffix(".js") {
    raw_argv[2:].to_array()
  } else if raw_argv.length() > 1 {
    raw_argv[1:].to_array()
  } else {
    []
  }
}

///|
/// Entry point for the MoonInk CLI scaffold.
fn main {
  let outcome = @moonink.cli_exec(normalize_runtime_argv(@env.args()))
  println(outcome.message)
}
