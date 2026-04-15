///|
fn current_unix_second() -> Int64 {
  @env.now().reinterpret_as_int64() / 1000L
}
