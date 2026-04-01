///|
/// Async-capable operation descriptor for runtime IO work introduced by IO-P6.
pub(all) enum RuntimeIOTask[T] {
  Ready(T)
} derive(Show, Eq)

///|
/// Execute an async-capable runtime IO task generically.
pub fn[T] run_runtime_io_task(task : RuntimeIOTask[T]) -> T {
  match task {
    Ready(value) => value
  }
}

///|
pub fn runtime_task_policy() -> RuntimeTaskPolicy {
  default_runtime_task_policy()
}
