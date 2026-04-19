///|
fn nul_terminated_utf8_bytes(source : String) -> Bytes {
  @utf8.encode(source + "\u{00}")
}

///|
#borrow(_host)
extern "c" fn preview_startup_check_ffi(_host : Bytes, port : Int) -> Int = "moonink_preview_startup_check"

///|
fn preview_startup_reason(code : Int) -> String {
  if code == -1 {
    "failed to create the preview server socket"
  } else if code == -2 {
    "preview port must be between 1 and 65535"
  } else if code == -3 {
    "preview host must be localhost, 0.0.0.0, or an IPv4 address"
  } else if code == -4 {
    "failed to listen on the preview server socket"
  } else {
    "failed to bind the preview server socket (errno: \{code})"
  }
}

///|
fn native_preview_startup_check_result(
  host : String,
  port : Int,
) -> Result[Unit, @core.ProjectIOError] {
  let code = preview_startup_check_ffi(nul_terminated_utf8_bytes(host), port)
  if code == 0 {
    Ok(())
  } else {
    Err(
      @core.project_io_error(
        "serve_preview",
        host + ":" + port.to_string(),
        preview_startup_reason(code),
      ),
    )
  }
}
