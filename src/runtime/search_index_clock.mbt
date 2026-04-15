///|
fn pad_two(value : Int) -> String {
  if value < 10 {
    "0" + value.to_string()
  } else {
    value.to_string()
  }
}

///|
pub fn current_utc_iso8601_second() -> String {
  let generated_at = @time.unix(current_unix_second(), zone=@time.utc_zone) catch {
    _ => panic()
  }
  let plain = generated_at.to_plain_date_time()
  plain.year().to_string() +
  "-" +
  pad_two(plain.month()) +
  "-" +
  pad_two(plain.day()) +
  "T" +
  pad_two(plain.hour()) +
  ":" +
  pad_two(plain.minute()) +
  ":" +
  pad_two(plain.second()) +
  "Z"
}

///|
fn current_unix_second() -> Int64 {
  @env.now().reinterpret_as_int64() / 1000L
}
