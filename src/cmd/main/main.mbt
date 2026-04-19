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
#cfg(target="js")
extern "js" fn runtime_js_try_exit(code : Int) -> Bool =
  #| function(code) {
  #|   if (typeof process !== "undefined" && typeof process.exit === "function") {
  #|     process.exit(code);
  #|     return true;
  #|   }
  #|   return false;
  #| }

///|
#cfg(any(target="native", target="llvm"))
extern "c" fn runtime_native_exit(code : Int) = "exit"

///|
#cfg(any(target="wasm", target="wasm-gc"))
fn runtime_wasm_exit(code : Int) -> Unit = "__moonbit_sys_unstable" "exit"

///|
#cfg(target="js")
fn apply_exit_code(code : Int) -> Unit {
  if !runtime_js_try_exit(code) {
    panic()
  }
}

///|
#cfg(any(target="native", target="llvm"))
fn apply_exit_code(code : Int) -> Unit {
  runtime_native_exit(code)
}

///|
#cfg(any(target="wasm", target="wasm-gc"))
fn apply_exit_code(code : Int) -> Unit {
  runtime_wasm_exit(code)
}

///|
/// Entry point for the MoonInk CLI.
fn main {
  let argv = normalize_runtime_argv(@env.args())
  let outcome = run_main_native_entry(argv)
  if !outcome.message.is_empty() {
    println(outcome.message)
  }
  apply_exit_code(outcome.exit_code)
}
