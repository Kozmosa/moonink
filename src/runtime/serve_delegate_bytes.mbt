///|
fn nul_terminated_command_bytes(command : String) -> Bytes {
  @utf8.encode(command + "\u{00}")
}
