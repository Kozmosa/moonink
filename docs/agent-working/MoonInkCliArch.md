# MoonInk CLI Architecture

## Status

This document is a maintained global architecture note for the MoonInk CLI.
It must be updated whenever the CLI surface, execution flow, or structural
package boundaries change materially.

**Last updated:** 2026-04-01 — reflects multi-package restructuring (core/docflow/runtime/cli).

## Current CLI Surface

- `moonink help`
- `moonink onboard` — first-time setup: generates `moonink.json`, injects default frontmatter into `.md` files that lack it
- `moonink build`
- `moonink serve` (placeholder)
- unknown command fallback

`new` has been replaced by `onboard`.

## Current Package Structure

```
src/
  core/       — pure types and logic; zero external deps
  docflow/    — document pipeline adapters and backends
  runtime/    — filesystem IO boundary; wraps moonbitlang/x/fs
  cli/        — command dispatch and user-facing execution
  cmd/main/   — binary entry point
```

Dependency graph:

```
cmd/main → cli → core
                 runtime → core
                 docflow → core
```

## Current Execution Flow

```text
src/cmd/main/main.mbt
  -> @env.args()
  -> normalize_runtime_argv(...)
  -> @cli.cli_exec(argv)
  -> parse_cli_command          [src/cli/moonink.mbt]
  -> runtime task dispatch      [src/cli/cmd_build.mbt / cmd_onboard.mbt]
  -> runtime/native.mbt adapter
  -> runtime/async.mbt task boundary
  -> feature result APIs in core / runtime
```

`cli_run()` is the pure path (used by tests). `cli_exec()` drives real IO through the runtime stack.

## Current Command Responsibilities

### help

Returns static help text.

### onboard

1. Checks if `moonink.json` already exists.
2. If not: inspects current directory name to infer `site_name`, emits a default `moonink.json`.
3. Scans all `.md` files; for those missing a frontmatter block, injects minimal frontmatter (`title` inferred from filename or first heading, `type: article`).
4. Reports a summary of what was created and modified.

### build

Current real behavior:

1. Reads `moonink.json` via `runtime/config_loader.mbt` → `parse_config_json`.
2. Discovers content via `runtime/content_discovery.mbt` → recursive scan with exclude patterns.
3. Reports phase-1a summary (config + discovery ready).
4. Rendering/emit stages remain scaffold placeholders.

Pipeline target (explicit stages):

```text
Config load
  -> Content discovery (recursive scan + exclude)
  -> Frontmatter parse (classify article/page)
  -> DocFlow: ParserAdapter -> WikiLinker -> RenderAdapter
  -> Templater -> SiteConstructor -> emit to dist/
```

### serve

Placeholder; delegates to stub serve session.

## Content Model

Dual-track classification (no separate directories required):

| File type | Classification |
|-----------|---------------|
| `.html` | Page |
| `.md` with `type: page` in frontmatter | Page |
| other `.md` | Article |

Default exclude patterns: `.obsidian`, `.git`, `node_modules`, `dist`, any hidden directory.

## Configuration

Config file: `moonink.json` (JSON format). Parsed via MoonBit's built-in `@json.parse()`.

Key fields: `site_name`, `site_url`, `content_dir` (default `"."`), `output_dir` (default `"dist"`), `exclude`, `route_style` (`"pretty"` or `"direct"`).

## Runtime IO Direction

- `runtime/io.mbt` — project-owned sync filesystem facade over `moonbitlang/x/fs`
- `runtime/async.mbt` — `RuntimeIOTask[T]` wrapper (currently synchronous `Ready(T)`)
- `runtime/native.mbt` — default native runtime adapter for CLI-side side effects
- `runtime/policy.mbt` — conflict and cancellation policy types

Feature modules in `core` and `docflow` expose result-oriented APIs and remain IO-free. Only `runtime` and `cli` touch the filesystem.

## Structural Constraints

- keep `cmd/main` thin (argv normalization only);
- keep `cli_run()` pure for testability;
- `core` must remain dependency-free (no `x/fs`, no `markdown`);
- preserve explicit stage boundaries: config → discovery → parse → render → emit;
- replace dummy/scaffold stages incrementally without changing the public command surface prematurely.

## Known Gaps

- no structured option parser yet (flags and options are not parsed);
- `build` still uses dummy site-model and render/emit stages after config/discovery;
- `serve` is entirely placeholder;
- frontmatter-based `type: page` classification happens during content discovery without reading file contents (initial discovery defaults all `.md` to Article; refinement after frontmatter parse is a planned next step);
- WikiLink resolution (`wikilinker.mbt`) is a no-op stub.

## Next Planned Evolution

1. implement frontmatter reading during content discovery to enable `type: page` reclassification;
2. wire DocFlow pipeline into real `build` command output (replace dummy render stages);
3. emit actual HTML files to `dist/` with route-derived filenames;
4. add structured command flags (e.g. `--config`, `--output`);
5. evolve WikiLinker from no-op to Obsidian-compatible `[[filename]]` resolution.
