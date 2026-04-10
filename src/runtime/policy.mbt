///|
/// Conflict handling policy for runtime IO tasks introduced by IO-P13.
pub(all) enum RuntimeConflictPolicy {
  AbortOnConflict
  AllowRepeatableRead
} derive(Debug, Eq)

///|
pub impl Show for RuntimeConflictPolicy with output(self, logger) {
  match self {
    AbortOnConflict => logger.write_string("AbortOnConflict")
    AllowRepeatableRead => logger.write_string("AllowRepeatableRead")
  }
}

///|
/// Cancellation handling policy for runtime IO tasks introduced by IO-P13.
pub(all) enum RuntimeCancellationPolicy {
  NonCancelable
  CancelBeforeSideEffects
} derive(Debug, Eq)

///|
/// Scheduling policy for runtime IO task execution.
pub(all) struct RuntimeTaskPolicy {
  conflict_policy : RuntimeConflictPolicy
  cancellation_policy : RuntimeCancellationPolicy
  scheduling_note : String
} derive(Debug, Eq)

///|
pub fn default_runtime_task_policy() -> RuntimeTaskPolicy {
  {
    conflict_policy: RuntimeConflictPolicy::AbortOnConflict,
    cancellation_policy: RuntimeCancellationPolicy::CancelBeforeSideEffects,
    scheduling_note: "MoonInk currently executes tasks eagerly on the native runtime, but future schedulers should honor abort-on-conflict and cancel-before-side-effects semantics.",
  }
}
