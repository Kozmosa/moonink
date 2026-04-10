///|
/// Placeholder serve session for the scaffold phase.
pub(all) struct ServeSession {
  host : String
  port : Int
  mode : String
  note : String
} derive(Debug, Eq)

///|
pub fn prepare_serve_dummy() -> ServeSession {
  {
    host: "127.0.0.1",
    port: 3000,
    mode: "preview",
    note: "Local dev server startup is not implemented in the scaffold stage.",
  }
}

///|
fn run_serve_command() -> CliOutcome {
  let session = prepare_serve_dummy()
  {
    exit_code: 0,
    message: "[serve] scaffold runtime prepared\naddress: \{session.host}:\{session.port}\nstatus: placeholder only",
  }
}
