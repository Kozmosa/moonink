# MoonInk CLI Architecture

## Status

This document is a maintained global architecture note for the MoonInk CLI.
It must be updated whenever the CLI surface, execution flow, or structural
package boundaries change materially.

**Last updated:** 2026-04-14 — reflects the current `help` / `onboard` / `build` /
`check` / `serve` surface, the real build pipeline, and the split between the main
workspace dry-run preview path and the standalone native preview entrypoint.

## Current CLI Surface

- `moonink help`
- `moonink onboard` — first-time setup: generates `moonink.json`, injects default frontmatter into `.md` files that lack it
- `moonink build` — real static-site build into `dist/`
- `moonink check` — validation-only pass over discovered content; reports diagnostics without writing output
- `moonink serve` — runtime preview orchestration: builds first, validates preview launch, and reports preview address/output root
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

The current CLI implementation keeps parsing and dispatch in `src/cli/moonink.mbt`.
`cli_run()` remains the pure test path, while `cli_exec()` routes side-effecting
commands through the runtime boundary.

## Current Execution Flow

```text
src/cmd/main/main.mbt
  -> @env.args()
  -> normalize_runtime_argv(...)
  -> @cli.cli_exec(argv)
  -> parse_cli_command                          [src/cli/moonink.mbt]
  -> runtime command dispatch                   [src/cli/moonink.mbt]
  -> build/check/serve/onboard runtime entry    [src/cli/cmd_build.mbt / cmd_serve.mbt / cmd_onboard.mbt]
  -> runtime/native.mbt adapter
  -> runtime/async.mbt task boundary
  -> runtime/config + discovery + IO helpers
  -> core/docflow result APIs
```

Pure dispatch behavior:

- `cli_run()` returns "runtime execution required" placeholders for `build`, `check`, and `serve`
- `cli_exec()` crosses the runtime boundary and performs real IO-backed execution

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

1. Reads `moonink.json` via `runtime/config_loader.mbt`.
2. Discovers content via `runtime/content_discovery.mbt` using recursive scan + exclude rules.
3. Loads build inputs with parsed frontmatter metadata and classified content kind.
4. Fully clears `output_dir` before rebuilding.
5. Copies project-root `public/` assets into the output root.
6. Resolves the active layout source with this precedence:
   - `theme/layout.html` if present in the project;
   - configured `template_file` if present in config;
   - repository-owned built-in default theme otherwise.
7. Copies theme assets into `dist/assets/` when the active layout exposes an asset directory.
8. Builds the site assembly model from discovered pages and navigation metadata.
9. Builds a route-aware WikiLinker index and a markdown-wikilink backlink index.
10. Parses each source document through DocFlow adapters.
11. Applies WikiLink rewriting and collects rendered HTML.
12. Injects template context including:
    - site/page metadata;
    - `navigation_html`;
    - section context (`current_section_title`, `current_section_url`);
    - page header fields (`page_header_title`, `page_header_html`);
    - `backlinks_html`;
    - theme metadata (`theme_name`, `theme_asset_root`, `page_body_class`);
    - rendered `body_html`.
13. Emits HTML files using `core.output_html_path(...)`, respecting configured `route_style` (`pretty` or `direct`).
14. Reports processed source counts plus page/article breakdown.

Current build pipeline:

```text
Config load
  -> Content discovery (recursive scan + exclude)
  -> Build input load (frontmatter parse + article/page classification)
  -> Output cleanup
  -> Public asset copy
  -> Active theme/layout resolution
  -> Theme asset copy
  -> Site assembly (pages + navigation)
  -> WikiLink index + backlink index
  -> DocFlow: ParserAdapter -> WikiLinker -> RenderAdapter
  -> TemplateContext assembly
  -> emit to dist/
```

### check

`check` shares the same config load, discovery, build-input load, and WikiLink
resolution path as `build`, but stops before rendering/output emission.

Current behavior:

1. Reads config and discovers content.
2. Loads build inputs.
3. Builds the WikiLink target index.
4. Parses each document through format-appropriate parser adapters.
5. Applies WikiLink resolution and collects document diagnostics.
6. Reports processed counts and diagnostic count.
7. Returns exit code `0` when diagnostics are empty, otherwise `1`.
8. Does not clear `dist/`, write HTML, or copy assets.

This makes `check` the non-emitting validation pass for content/configuration issues
that surface during parse and WikiLink resolution.

### serve

`serve` in the main workspace is no longer a pure placeholder, but it is also not the
full native server implementation.

Current main-workspace behavior:

1. Loads config and discovers content.
2. Reuses the real `build_site_result(...)` path to build preview output.
3. Prepares preview launch metadata for `127.0.0.1:3000`.
4. Validates the preview launch through a preview-runner boundary.
5. Reports preview address, preview root, and runner status.

Behavior split:

- `src/cli/cmd_serve.mbt` uses a dry-run preview runner in normal runtime tests and main-workspace execution semantics.
- The native mocket preview runner is delegated through the runtime boundary.
- The standalone real preview server lives in the separate `native-serve/` subproject, which is launched independently from the main MoonInk workspace.

So `serve` is best described as **build-plus-preview orchestration with delegated native serving**, not as a stub and not as an all-in-one in-workspace server.

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

Key fields currently exercised by the CLI include:

- `site_name`
- `site_url`
- `content_dir` (default `"."`)
- `output_dir` (default `"dist"`)
- `exclude`
- `route_style` (`"pretty"` or `"direct"`)
- `template_file`

Theme/layout precedence is resolved at runtime rather than in config parsing:

1. project `theme/layout.html`
2. configured `template_file`
3. built-in default theme

## Runtime IO Direction

- `runtime/io.mbt` — project-owned sync filesystem facade over `moonbitlang/x/fs`
- `runtime/async.mbt` — `RuntimeIOTask[T]` wrapper (currently synchronous `Ready(T)`)
- `runtime/native.mbt` — default native runtime adapter for CLI-side side effects
- `runtime/policy.mbt` — conflict and cancellation policy types
- `runtime/config_loader.mbt` — config loading and active layout resolution
- `runtime/content_discovery.mbt` — recursive content discovery / inventory creation
- preview launch helpers — runtime boundary for dry-run vs native preview execution

Feature modules in `core` and `docflow` expose result-oriented APIs and remain IO-free.
Only `runtime` and `cli` touch the filesystem.

## Current Build/Template Responsibilities

The CLI build layer currently owns several presentation-adjacent integration steps
that are intentionally kept above `docflow` and `core`:

- derive `SitePage` records from build inputs;
- assemble navigation from page-only structure plus `nav_title` / `nav_hidden` metadata;
- derive section context for the current page;
- build page-header HTML;
- compute backlinks from markdown wikilink sources;
- construct template context and hand it to `docflow.apply_template(...)`;
- decide output paths from `route_style`.

This keeps `docflow` focused on parser/render adapter behavior while leaving site-wide
assembly and theme-facing context composition in the CLI build layer.

## Structural Constraints

- keep `cmd/main` thin (argv normalization only);
- keep `cli_run()` pure for testability;
- `core` must remain dependency-free (no `x/fs`, no `markdown`);
- preserve explicit stage boundaries: config → discovery → parse → render → template → emit;
- keep filesystem access inside `runtime` / CLI runtime entrypoints;
- prefer integrating new site-generation behavior into the existing build pipeline rather than introducing parallel pipelines.

## Known Gaps

- no structured option parser yet (flags and options are not parsed);
- `serve` in the main workspace validates preview launch and reports readiness, but the real long-running preview server still lives in `native-serve/` rather than the main workspace binary;
- backlinks are currently exposed as pre-rendered `backlinks_html` rather than a richer structured template model;
- custom project themes must explicitly render supported context fields themselves; built-in-theme behavior is not automatically inherited;
- backlink coverage is currently explicit for pretty-route output, while direct-route-specific backlink assertions are still a follow-up.

## Next Planned Evolution

1. add structured command flags (for example `--config`, `--output`, or serve host/port overrides);
2. decide whether theme/template documentation should formally freeze the full current template contract, including `backlinks_html`;
3. extend backlink coverage and/or evolve backlinks from pre-rendered HTML into a richer structured model if the presentation requirements grow;
4. decide whether the main workspace `serve` command should remain delegated orchestration or absorb more of the native preview lifecycle over time;
5. continue strengthening `check` as the non-emitting validation path for config/content diagnostics.
