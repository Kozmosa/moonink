///|
/// Native runtime adapter introduced by IO-P10.
pub(all) struct NativeRuntimeAdapter {
  name : String
  note : String
  policy : RuntimeTaskPolicy
} derive(Show, Eq)

///|
pub fn native_runtime_adapter() -> NativeRuntimeAdapter {
  {
    name: "native-runtime-adapter",
    note:
      "Native runtime wiring is now isolated behind explicit adapter helpers instead of leaking through generic task execution call sites.",
    policy: runtime_task_policy(),
  }
}

///|
pub fn[T] run_native_runtime_io_task(task : RuntimeIOTask[T]) -> T {
  ignore(native_runtime_adapter())
  run_runtime_io_task(task)
}

///|
pub fn[T] run_native_runtime_io_task_with_policy(
  task : RuntimeIOTask[T],
  policy : RuntimeTaskPolicy,
) -> T {
  ignore(policy)
  run_native_runtime_io_task(task)
}

///|
pub fn run_native_build_command() -> CliOutcome {
  run_native_runtime_io_task_with_policy(
    Ready(run_build_command_runtime()),
    native_runtime_adapter().policy,
  )
}

///|
pub fn run_native_new_command(project_name : String?) -> CliOutcome {
  run_native_runtime_io_task_with_policy(
    emit_starter_project_task(plan_starter_project(project_name)),
    native_runtime_adapter().policy,
  )
}
