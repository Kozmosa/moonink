# 13 IO Runtime And Async Refactor Plan

## 1. Purpose

This document defines the near-term IO engineering direction for MoonInk.
It translates the current project decision into an executable refactor plan:

- filesystem access should use `moonbitlang/x/fs` as the current baseline API;
- `native` is the required first-class target;
- existing IO should be refactored gradually toward an async-oriented runtime model;
- core parsing, modeling, and rendering logic should remain as synchronous as practical.

## 2. Current Constraint Set

### 2.1 Confirmed Constraints

- MoonInk must support the `native` target.
- Filesystem operations should be built on top of `moonbitlang/x/fs`.
- IO refactoring should move toward async execution instead of expanding synchronous direct calls.

### 2.2 Architectural Implication

MoonInk should not let filesystem details leak across the whole codebase.
The project should adopt a split between:

- synchronous core logic for parsing, normalization, routing, and modeling;
- asynchronous runtime boundaries for filesystem and future external IO.

## 3. Design Principles

### 3.1 Native First, But Not Native Everywhere

The runtime implementation should optimize for `native` now, but avoid hard-coding native details into high-level build logic. Native-specific behavior should live in a dedicated runtime layer.

### 3.2 Use `x/fs` As The Source, Not As The Whole Architecture

`moonbitlang/x/fs` is the current filesystem capability provider, but MoonInk should still wrap it with its own IO facade so that the project can:

- normalize errors;
- normalize path and encoding policy;
- control async evolution;
- test upper layers without scattering raw filesystem calls.

### 3.3 Keep The Core Mostly Synchronous

The following areas should stay synchronous unless there is a strong reason otherwise:

- configuration parsing after source text is loaded;
- content classification and normalization logic;
- frontmatter and Markdown transformation;
- routing, navigation, and site model construction;
- rendering decisions that do not themselves require external IO.

### 3.4 Keep Waiting At The Edges

The following areas are the correct async boundary candidates:

- file reads and writes;
- directory enumeration;
- workspace and project-root discovery;
- future dev-server sockets or stream-based IO;
- external command or process integration if introduced later.

## 4. Target Layering

MoonInk should evolve toward the following execution structure:

1. CLI layer
2. runtime / IO facade layer
3. configuration and content ingestion layer
4. parsing and normalization layer
5. site model layer
6. rendering layer
7. output emission layer

The key change is that runtime IO becomes an explicit boundary instead of remaining embedded in feature modules.

## 5. Initial Refactor Scope

The first IO refactor wave should focus on the existing real filesystem touch points:

- starter project emission in `new`;
- `moonink.toml` loading;
- recursive content discovery under `docs/` and `articles/`.

These are already real, bounded operations and therefore provide the safest migration path.

## 6. Non-Goals For This Refactor Track

This roadmap does not attempt to do the following immediately:

- redesign the public CLI surface;
- make all internal functions async;
- add multi-target abstractions for every backend before `native` is stable;
- introduce plugin-oriented runtime hooks too early;
- solve dev-server concurrency in the same commit as basic filesystem refactoring.

## 7. Staged Atomic Commit Roadmap

### IO-P0: Writing Plan

Write and freeze the IO refactor plan, constraints, and migration guardrails.

Status: completed.

### IO-P1: Inventory Existing IO Surface

Catalog all filesystem and IO touch points, their callers, and their migration priority.

Status: completed via `docs/technical/15-IO-Surface-Inventory.md`.

Current inventory baseline:

- `config.mbt`: raw read of `moonink.toml`;
- `content.mbt`: recursive directory inspection and Markdown discovery;
- `starter.mbt`: starter-project directory creation and file writes.

### IO-P2: Define IO Layer Boundaries

Document and introduce a dedicated runtime or IO facade boundary so feature modules stop growing raw filesystem calls.

Status: completed.

Current boundary shape:

- `moonink.mbt` keeps `cli_run` as the pure command entry;
- `moonink.mbt` routes `cli_exec` into `run_runtime_cli_command(...)`;
- `io_runtime.mbt` is the explicit runtime boundary module for side-effecting CLI flows;
- `render.mbt` exposes `run_build_command_runtime()` for real build-time IO work while `run_build_command()` stays a pure planning result;
- `starter.mbt` exposes `emit_starter_project_runtime(...)` so starter emission is reached only through the runtime boundary.

This does not yet replace raw `x/fs` usage, but it freezes where side-effecting execution is allowed to enter the system.

### IO-P3: Introduce Unified IO Error Model

Normalize filesystem-related errors into project-owned error types.

Status: completed.

Current shared error shape:

- `io_error.mbt` defines `ProjectIOError { operation, path, detail }`;
- `config.mbt` now maps filesystem reads to `ConfigError::IOError(ProjectIOError)`;
- `content.mbt` now maps traversal and inspection failures to `ContentDiscoveryError::IOError(ProjectIOError)`;
- runtime CLI messaging formats IO failures through `format_project_io_error(...)` so command output exposes operation and path context consistently.

This stage does not yet add a full IO facade, but it ensures later facade layers inherit one project-owned error vocabulary.

### IO-P4: Introduce Path And Encoding Policy

Fix path normalization and text encoding assumptions before wider async migration.

Status: completed.

Current policy shape:

- `io_policy.mbt` defines `normalize_relative_path(...)`, `dirname_relative_path(...)`, and `join_relative_path(...)`;
- relative paths are normalized by removing repeated separators and `.` segments;
- absolute paths are rejected at the current policy layer;
- parent traversal via `..` is rejected at the current policy layer;
- `config.mbt` now normalizes `config_path`, `docs_dir`, `articles_dir`, and `output_dir` before use;
- `content.mbt` now resolves content roots through the shared relative-path join policy;
- `starter.mbt` now normalizes project names and output paths through the same policy;
- `TEXT_ENCODING_NAME = "utf-8"` is the current project text-encoding assumption for config and starter text files.

This stage freezes the current relative-path and UTF-8 assumptions so later IO facade work can reuse one stable policy layer.

### IO-P5: Add Sync Facade Over `x/fs`

Wrap current `x/fs` calls with MoonInk-owned helper APIs without changing the whole call graph yet.

Status: completed.

Current sync facade shape:

- `runtime_io.mbt` now owns sync helpers such as `io_read_file_to_string(...)`, `io_path_exists(...)`, `io_is_dir(...)`, `io_is_file(...)`, `io_read_dir(...)`, `io_create_dir(...)`, and `io_write_string(...)`;
- the facade maps raw `x/fs` failures into `ProjectIOError` before feature modules see them;
- `config.mbt`, `content.mbt`, and `starter.mbt` no longer call raw `@fs` APIs directly for current read/write/discovery paths.

This stage makes the project-owned runtime facade real while keeping existing behavior synchronous.

### IO-P6: Introduce Async IO Interface

Add the first async-capable facade surface for native runtime usage.

Status: completed.

Current async-capable shape:

- `runtime_async.mbt` defines `RuntimeIOTask[T]` as the first project-owned async-capable runtime wrapper;
- `run_runtime_io_task(...)` executes the task eagerly today, but freezes the interface shape for later true async native execution;
- `load_config_task(...)`, `discover_content_task(...)`, and `emit_starter_project_task(...)` expose the first runtime IO task constructors;
- `render.mbt` and `io_runtime.mbt` now route build/new execution through the task interface.

This stage does not yet introduce true scheduling or concurrency, but it establishes the first async-oriented facade surface needed for later native runtime adaptation.

### IO-P7: Migrate Read Operations First

Move configuration loading and source-file reads to the async boundary first.

Status: completed.

Current read migration shape:

- `config.mbt` now exposes `parse_loaded_config(...)` so config parsing is synchronous and pure once source text is available;
- `runtime_async.mbt` now exposes `read_config_source_task(...)` as the first explicit read-side runtime task helper;
- `render.mbt` now performs config file reading through `read_config_source_task(...)` and only parses after the read task resolves;
- `load_config_task(...)` is now layered on top of the same read-task-plus-parse split.

This stage moves the current config read path to the runtime task boundary while keeping parsing logic itself synchronous and testable.

### IO-P8: Migrate Write Operations With Safety Guarantees

Move writes after reads are stable, including file creation and output emission safeguards.

Status: completed.

Current write migration shape:

- `starter.mbt` now defines `StarterWriteTarget` and `StarterWritePlan` to make write intent explicit before runtime emission;
- `plan_starter_write(...)` builds the directory/file write plan before any filesystem mutation occurs;
- `validate_starter_write_plan(...)` performs overwrite preflight checks on the root and planned file targets before writes begin;
- `apply_starter_write_plan(...)` applies directory creation and file writes only after preflight succeeds;
- `runtime_async.mbt` now exposes `plan_starter_write_task(...)` so write planning also crosses the runtime task boundary.

This stage does not yet implement rollback or atomic rename-based commits, but it adds explicit preflight validation and write-plan framing before starter emission proceeds.

### IO-P9: Migrate Directory And Workspace Loading

Move recursive discovery and project-root scanning into the runtime IO boundary.

Status: completed.

Current directory/workspace migration shape:

- `content.mbt` now defines `ContentDiscoveryPlan` so workspace roots are made explicit before traversal;
- `plan_content_discovery(...)` computes `docs_root`, `articles_root`, and `workspace_roots` before any recursive directory scanning occurs;
- `discover_planned_content(...)` performs traversal from the planned roots rather than recomputing roots inline;
- `runtime_async.mbt` now exposes `plan_content_discovery_task(...)` and layers `discover_content_task(...)` on top of planning plus planned traversal.

This stage moves directory and workspace loading intent to the runtime boundary while keeping traversal logic itself reusable and synchronous after planning resolves.

### IO-P10: Introduce Native Runtime Adaptation Layer

Isolate native-specific runtime wiring and keep higher layers target-agnostic.

Status: completed.

Current native adaptation shape:

- `runtime_native.mbt` now defines `NativeRuntimeAdapter` as the explicit native runtime wiring surface;
- `run_native_runtime_io_task(...)` isolates native task execution behind adapter helpers instead of exposing generic task execution directly at top-level runtime entrypoints;
- `run_native_build_command()` and `run_native_new_command(...)` are now the native-specific command adapters used by `io_runtime.mbt`;
- `io_runtime.mbt` now delegates side-effecting CLI build/new flows through the native adapter layer.

This stage keeps higher-level runtime dispatch target-agnostic while making native-specific execution wiring explicit and replaceable.

### IO-P11: Remove Direct Synchronous IO Entrypoints

Deprecate and remove remaining raw synchronous filesystem access from feature modules.

Status: completed.

Current cleanup shape:

- `config.mbt` now exposes `load_config_result(...)` instead of a public sync throwing entrypoint;
- `content.mbt` now exposes `discover_content_result(...)` instead of a public sync throwing entrypoint;
- `starter.mbt` now exposes `emit_starter_project_result(...)` instead of a public sync runtime entrypoint for feature-level callers;
- `runtime_async.mbt` now layers task constructors directly on top of these result-oriented runtime-safe APIs.

This stage removes the remaining direct synchronous feature entrypoints from the public surface so runtime/native task or adapter paths become the intended execution model.

### IO-P12: Add Tests For Async IO Contracts

Cover success paths, missing-file behavior, traversal failures, and error mapping.

Status: completed.

Current async contract coverage:

- config read tasks now have explicit tests for success, missing-file behavior, and parse-error propagation;
- discovery tasks now have explicit tests for success, missing-directory behavior, and runtime planning coverage;
- starter write tasks now have explicit tests for overwrite-protection behavior after one successful emission;
- native adapter contract tests now verify that read and discovery failures propagate through `run_native_runtime_io_task(...)` unchanged.

This stage strengthens the runtime task boundary by ensuring async-capable task wrappers preserve success and failure contracts consistently across read, discovery, and write paths.

### IO-P13: Add Concurrency And Cancellation Policy

Define conflict handling, cancellation semantics, and future runtime scheduling rules.

Status: completed.

Current policy shape:

- `runtime_policy.mbt` now defines `RuntimeConflictPolicy`, `RuntimeCancellationPolicy`, and `RuntimeTaskPolicy`;
- `default_runtime_task_policy()` freezes the current native runtime defaults as `AbortOnConflict` plus `CancelBeforeSideEffects`;
- `runtime_async.mbt` now exposes `runtime_task_policy()` so generic task code can reference the shared policy surface;
- `runtime_native.mbt` now carries `policy` inside `NativeRuntimeAdapter` and exposes `run_native_runtime_io_task_with_policy(...)` as the explicit native policy hook.

This stage does not yet implement parallel scheduling or active cancellation interrupts, but it makes conflict handling and cancellation semantics explicit in the runtime surface so later schedulers have a concrete policy contract to honor.

### IO-P14: Documentation And Migration Closure

Update architecture, contributor guidance, and the long-lived docs so the new model becomes the default engineering path.

Status: completed.

Closure result:

- `docs/technical/00-Architecture.md` now treats `runtime_io.mbt`, `runtime_async.mbt`, `runtime_native.mbt`, and `runtime_policy.mbt` as the settled runtime layer;
- `docs/agent-working/MoonInkCliArch.md` now reflects the current CLI execution stack and no longer treats runtime IO architecture as transitional;
- `docs/technical/13-IO-Runtime-and-Async-Plan.md` records the completed IO-P0 through IO-P14 migration path;
- `docs/Roadmap.md` now reflects the IO track as completed through policy/documentation closure.

The IO refactor track should now be treated as the default engineering model for future MoonInk runtime work.

## 8. Milestones

### M1 - Decision And Boundary Freeze

Covers `IO-P0` to `IO-P4`.

Goal: freeze constraints, boundaries, error model, and policy before code churn increases.

### M2 - Facade Establishment

Covers `IO-P5` to `IO-P6`.

Goal: make the runtime IO boundary real before broader migration.

### M3 - Mainline Migration

Covers `IO-P7` to `IO-P10`.

Goal: move the current real read, write, and discovery flows to the new runtime model.

### M4 - Consolidation And Stabilization

Covers `IO-P11` to `IO-P14`.

Goal: remove legacy paths, add tests, and finalize contributor-facing guidance.

## 9. Exit Signals

The IO refactor track should be considered successful when:

- new feature work no longer adds raw `x/fs` calls directly in feature modules;
- runtime filesystem access has a single project-owned boundary;
- the first native async path is in place for real build operations;
- the synchronous core remains readable and testable;
- architecture and roadmap documents clearly describe the new execution model.
