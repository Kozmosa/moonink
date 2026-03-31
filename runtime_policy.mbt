///|
/// Conflict handling policy for runtime IO tasks introduced by IO-P13.
pub(all) enum RuntimeConflictPolicy {
  AbortOnConflict
  AllowRepeatableRead
} derive(Show, Eq)

///|
/// Cancellation handling policy for runtime IO tasks introduced by IO-P13.
pub(all) enum RuntimeCancellationPolicy {
  NonCancelable
  CancelBeforeSideEffects
} derive(Show, Eq)

///|
/// Scheduling policy for runtime IO task execution.
pub(all) struct RuntimeTaskPolicy {
  conflict_policy : RuntimeConflictPolicy
  cancellation_policy : RuntimeCancellationPolicy
  scheduling_note : String
} derive(Show, Eq)

///|
pub fn default_runtime_task_policy() -> RuntimeTaskPolicy {
  {
    conflict_policy: RuntimeConflictPolicy::AbortOnConflict,
    cancellation_policy: RuntimeCancellationPolicy::CancelBeforeSideEffects,
    scheduling_note:
      "MoonInk currently executes tasks eagerly on the native runtime, but future schedulers should honor abort-on-conflict and cancel-before-side-effects semantics.",
  }
}
