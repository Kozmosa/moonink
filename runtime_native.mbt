///|
/// Native runtime adapter introduced by IO-P10.
pub(all) struct NativeRuntimeAdapter {
  name : String
  note : String
} derive(Show, Eq)

///|
pub fn native_runtime_adapter() -> NativeRuntimeAdapter {
  {
    name: "native-runtime-adapter",
    note:
      "Native runtime wiring is now isolated behind explicit adapter helpers instead of leaking through generic task execution call sites.",
  }
}

///|
pub fn[T] run_native_runtime_io_task(task : RuntimeIOTask[T]) -> T {
  ignore(native_runtime_adapter())
  run_runtime_io_task(task)
}

///|
pub fn run_native_build_command() -> CliOutcome {
  run_build_command_runtime()
}

///|
pub fn run_native_new_command(project_name : String?) -> CliOutcome {
  run_native_runtime_io_task(emit_starter_project_task(plan_starter_project(project_name)))
}
