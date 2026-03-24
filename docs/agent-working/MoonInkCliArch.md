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
  -> @moonink.cli_run(argv placeholder)
  -> parse_cli_command
  -> dispatch_cli_command
  -> command handler
  -> feature module
```

## Current Command Responsibilities

### help

Returns static scaffold help text.

### new

Delegates to starter-project planning logic and now returns a concrete sample
MoonInk site layout for Phase 1 milestone M1. The command remains pure for now:
it models which files and directories should be emitted, but it does not yet
write them to disk.

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
- keep the command core testable as pure functions where possible;
- preserve explicit boundaries between CLI, config, content, model, render, and serve;
- evolve the starter-project planner into file emission without collapsing the module boundary;
- replace dummy implementations incrementally without changing the public execution shape too early.

## Known Gaps

- no real runtime argv plumbing yet;
- no option parser yet;
- `new` still plans starter emission instead of performing side effects;
- no real build or serve implementation yet.

## Next Planned Evolution

1. make `new` emit the planned sample project files to disk;
2. wire real runtime argv into `cmd/main`;
3. add structured command options;
4. replace build placeholders stage by stage while preserving the current pipeline shape.
