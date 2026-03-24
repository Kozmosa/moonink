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
Filesystem access for starter emission now goes through `moonbitlang/x/fs`, and
runtime IO failures are converted into `CliOutcome` error messages instead of
being handled by JS-only extern bridges.

### build

`build` now implements the first real input stage of the pipeline:

```text
load_config
  -> validate required fields
  -> discover_content
  -> build_site_model_dummy
  -> render_site_dummy
```

Current real behavior includes:

- reading `moonink.toml` from the current project;
- validating the required `site`, `content`, and `build` fields;
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

## Known Gaps

- no structured option parser yet;
- runtime filesystem handling is still embedded in feature modules rather than a dedicated IO package;
- `build` still uses dummy site-model and render stages after config/discovery;
- `serve` remains entirely placeholder.

## Next Planned Evolution

1. decide whether filesystem helpers should move into a shared runtime IO layer as more commands gain real behavior;
2. add structured command options and flags;
3. implement frontmatter parsing and richer content typing after discovery;
4. replace the remaining dummy model/render stages once the content input layer is stable.
