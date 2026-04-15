///|
fn current_unix_second() -> Int64 =
  #| BigInt.asIntN(64, BigInt(Math.floor(Date.now() / 1000)))
