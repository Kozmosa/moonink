# MoonInk CLI Architecture

## Status

This document is a maintained global architecture note for the MoonInk CLI.
It must be updated whenever the CLI surface, execution flow, or structural
module boundaries change materially.

## Current CLI Surface

The current scaffold supports the following command model:

- `help`
- `new [project-name]`
- `build`
- `serve`
- unknown command fallback

## Current Execution Flow

```text
cmd/main
  -> @env.args()
  -> normalize_runtime_argv(...)
  -> @moonink.cli_exec(argv)
  -> parse_cli_command
  -> io_runtime.mbt runtime dispatch
  -> runtime_native.mbt adapter
  -> runtime_async.mbt task boundary
  -> feature result API / pure planner
```

## Current Command Responsibilities

### help

Returns static scaffold help text.

### new

The CLI now has two execution layers for `new`:

- `cli_run(...)` remains pure and returns the starter-project plan status for tests;
- `cli_exec(...)` delegates to `io_runtime.mbt`, then `runtime_native.mbt`, then the starter write task path.

The emitted starter currently creates:

- `moonink.toml`
- `docs/index.md`
- `docs/getting-started.md`
- `articles/hello-moonink.md`
- `theme/README.md`
- `theme/overrides.css`
- `.gitignore`

The runtime command now applies explicit write safety rules before filesystem mutation:

- starter emission is planned via `StarterWritePlan`;
- overwrite policy is currently `abort_if_target_exists`;
- directory/file writes happen only after preflight validation succeeds.

Filesystem access now flows through the settled runtime stack:

- `runtime_io.mbt` for sync filesystem facade calls;
- `runtime_async.mbt` for starter write tasks;
- `runtime_native.mbt` for native runtime adapter execution;
- `runtime_policy.mbt` for conflict/cancellation policy defaults.

### build

`build` now implements the first real input stage of the pipeline through the settled runtime stack:

```text
io_runtime.mbt
  -> runtime_native.mbt adapter
  -> runtime_async.mbt read/discovery tasks
  -> config result API / pure parsing helpers
  -> content discovery planning + planned traversal
  -> build_site_model_dummy
  -> render_site_dummy
```

Current real behavior includes:

- reading `moonink.toml` through `read_config_source_task(...)`;
- validating the required `site`, `content`, and `build` fields;
- planning workspace roots before recursive traversal;
- recursively scanning `docs/` and `articles/` for `.md` files;
- reporting a real phase-1a summary before the later pipeline stages remain placeholders.

### serve

Delegates to placeholder serve session preparation.

## Current Structural Boundaries

### CLI Core

- `moonink.mbt`
- `cli_output.mbt`

### Feature Modules

- `starter.mbt`
- `config.mbt`
- `content.mbt`
- `model.mbt`
- `render.mbt`
- `serve_runtime.mbt`

### Executable Wrapper

- `cmd/main/main.mbt`
- `cmd/main/moon.pkg`

## Architectural Constraints

- keep `cmd/main` thin;
- keep a pure command core path for tests where possible;
- preserve explicit boundaries between CLI, config, content, model, render, and serve;
- keep starter planning and starter emission in the same feature module without collapsing them into CLI parsing;
- replace dummy implementations incrementally without changing the public command surface too early.

## Runtime IO Direction

The IO refactor track has now landed a concrete default execution model:

- `runtime_io.mbt` is the project-owned sync filesystem facade;
- `runtime_async.mbt` is the async-capable task boundary for IO-backed workflows;
- `runtime_native.mbt` is the default native runtime adapter for CLI-side side effects;
- `runtime_policy.mbt` defines the current conflict and cancellation policy contract;
- feature modules expose result-oriented APIs and pure planning/parsing helpers where practical.

This means direct synchronous feature entrypoints are no longer the intended public path for IO-backed behavior.

## Known Gaps

- no structured option parser yet;
- `build` still uses dummy site-model and render stages after config/discovery;
- `serve` remains entirely placeholder;
- runtime policy exists, but true parallel scheduling and active cancellation are not implemented yet.

## Next Planned Evolution

1. use the settled runtime stack as the default path for any new IO-backed feature work;
2. add structured command options and flags;
3. implement frontmatter parsing and richer content typing after discovery;
4. replace the remaining dummy model/render stages once the content input layer is stable;
5. evolve runtime policy into real scheduling and cancellation mechanics when needed.
