///|
/// Async-capable operation descriptor for runtime IO work introduced by IO-P6.
pub(all) enum RuntimeIOTask[T] {
  Ready(T)
} derive(Show, Eq)

///|
/// Execute an async-capable runtime IO task.
///
/// The current native-first implementation is eager, but the `RuntimeIOTask`
/// wrapper freezes the interface shape needed for a later true async runtime.
pub fn[T] run_runtime_io_task(task : RuntimeIOTask[T]) -> T {
  match task {
    Ready(value) => value
  }
}

///|
pub fn load_config_task(config_path : String) -> RuntimeIOTask[Result[LoadedConfig, ConfigError]] {
  Ready(try? load_config(config_path=config_path))
}

///|
pub fn discover_content_task(
  config : LoadedConfig,
) -> RuntimeIOTask[Result[ContentInventory, ContentDiscoveryError]] {
  Ready(try? discover_content(config))
}

///|
pub fn emit_starter_project_task(
  plan : StarterTemplatePlan,
) -> RuntimeIOTask[CliOutcome] {
  Ready(emit_starter_project_runtime(plan))
}
