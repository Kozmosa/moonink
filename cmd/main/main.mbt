///|
/// Entry point for the MoonInk CLI scaffold.
fn main {
  let outcome = @moonink.cli_run(["moonink", "help"])
  println(outcome.message)
}
