# CLI Scaffold Implementation 0324

## Goal

Record the cold-start implementation of the MoonInk CLI scaffold that turns the
repository from a template into a runnable placeholder command-line skeleton.

## Scope

Implemented in this milestone:

- command model and pure CLI execution entry;
- parsing and dispatch for `help`, `new`, `build`, and `serve`;
- placeholder handlers for the command surface;
- placeholder pipeline modules for starter, config, content, model, render, and serve;
- thin executable wrapper in `cmd/main`;
- black-box tests for parse and dispatch behavior.

Not implemented in this milestone:

- runtime argv integration in `cmd/main`;
- real starter project file emission;
- TOML parsing;
- real content discovery;
- Markdown/frontmatter parsing;
- actual site rendering or local dev server startup.

## Files Changed In The Scaffold Milestone

- `moonink.mbt`
- `cli_output.mbt`
- `starter.mbt`
- `config.mbt`
- `content.mbt`
- `model.mbt`
- `render.mbt`
- `serve_runtime.mbt`
- `cmd/main/moon.pkg`
- `cmd/main/main.mbt`
- `moonink_test.mbt`
- `README.mbt.md`
- `moon.mod.json`

## Design Decisions

### Root Package First

The scaffold was implemented in the root package instead of being split into
multiple packages immediately. This keeps the cold-start cost low while still
making future package extraction straightforward.

### Pure CLI Core

`cli_run(argv)` returns a `CliOutcome` rather than printing directly. This keeps
command parsing and dispatch testable without shelling out.

### Placeholder Pipeline Boundaries

The `build` command already flows through:

- config loading;
- content discovery;
- site model construction;
- render planning.

These functions remain dummy implementations, but they preserve the future
architecture boundaries described in the RFC and technical docs.

## Current Limitations

- `cmd/main` currently invokes the help command deterministically rather than reading runtime CLI args.
- Command options such as `--output`, `--port`, or `--config` are not parsed.
- `new/build/serve` return placeholder results only.
- No file-writing side effects are performed yet.

## Recommended Next Steps

1. integrate real argv reading into `cmd/main`;
2. implement starter project file emission for `moonink new`;
3. introduce config path handling and TOML parsing placeholders with richer result types;
4. evolve the build dummy pipeline into fixture-driven implementations in milestone M1.
