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
  -> runtime dispatch
  -> command handler
  -> feature module
```

## Current Command Responsibilities

### help

Returns static scaffold help text.

### new

The CLI now has two execution layers for `new`:

- `cli_run(...)` remains pure and returns the starter-project plan status for tests;
- `cli_exec(...)` performs real starter project emission at runtime.

The emitted starter currently creates:

- `moonink.toml`
- `docs/index.md`
- `docs/getting-started.md`
- `articles/hello-moonink.md`
- `theme/README.md`
- `theme/overrides.css`
- `.gitignore`

The runtime command refuses to overwrite an existing target directory.
Current real emission support is implemented on the JS runtime target; non-JS
runtimes return a clear guidance message instead of attempting filesystem work.

### build

Delegates into the current dummy pipeline:

```text
load_config_dummy
  -> discover_content_dummy
  -> build_site_model_dummy
  -> render_site_dummy
```

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

## Known Gaps

- no structured option parser yet;
- starter emission currently uses minimal JS runtime filesystem bridges instead of a richer abstraction layer;
- no real build or serve implementation yet;
- non-JS runtime starter emission is not implemented yet.

## Next Planned Evolution

1. extract starter filesystem operations behind a dedicated runtime IO layer;
2. add structured command options and flags;
3. implement real config loading/content discovery for `build`;
4. add native or wasm-compatible filesystem support once the runtime surface is stable.
