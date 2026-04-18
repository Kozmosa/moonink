# MoonInk CLI Architecture

## Status

This document is a maintained global architecture note for the MoonInk CLI.
It must be updated whenever the CLI surface, execution flow, or structural
package boundaries change materially.

**Last updated:** 2026-04-18 — reflects the current `help` / `onboard` /
`build` / `check` / `serve` surface, Theme System V2 bundle rendering,
compatibility fallback rules, and the current build-time theme context contract.

## Current CLI Surface

- `moonink help`
- `moonink onboard` — first-time setup: generates `moonink.json`, injects default frontmatter into `.md` files that lack it
- `moonink build` — real static-site build into `dist/`
- `moonink check` — validation-only pass over discovered content; reports diagnostics without writing output
- `moonink serve` — runtime preview orchestration: builds first, validates preview launch, and reports preview address/output root
- unknown command fallback

`new` has been replaced by `onboard`.

## Current Package Structure

```text
src/
  core/       — pure types and logic; zero external deps
  docflow/    — document pipeline adapters and theme template engine
  runtime/    — filesystem IO boundary; wraps moonbitlang/x/fs
  cli/        — command dispatch and user-facing execution
  cmd/main/   — binary entry point
```

Dependency flow:

```text
cmd/main -> cli
cli -> runtime
cli -> docflow
cli -> core
runtime -> core
docflow -> core
```

`src/cli/moonink.mbt` still owns command parsing and dispatch.
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
4. Resolves the active presentation path with this precedence:
   - configured project Theme V2 bundle at `<theme>/theme.json` when `moonink.json.theme` is set, otherwise `theme/theme.json`;
   - configured project legacy `<theme>/layout.html` when `moonink.json.theme` is set, otherwise `theme/layout.html`, if no project bundle exists;
   - configured `template_file` if no project bundle or legacy project layout exists;
   - repository-owned built-in Theme V2 bundle otherwise.
5. For Theme V2 builds, validates every page against the manifest contract before output cleanup:
   - the selected layout key must exist;
   - page overrides must be allowlisted by `page_overrides`.
6. Fully clears `output_dir` before rebuilding.
7. Copies project-root `public/` assets into the output root.
8. Copies active theme assets into `dist/assets/`.
9. For Theme V2 builds, emits `dist/assets/theme-vars.css` from declared manifest tokens plus `theme_config` overrides.
10. Builds the site assembly model from discovered pages and navigation metadata.
11. Builds a route-aware WikiLinker index and a markdown-wikilink backlink index.
12. Parses each source document through DocFlow adapters.
13. Applies WikiLink rewriting and collects rendered HTML.
14. For Theme V2 builds, computes the selected layout key as:
    - `layout` frontmatter override when present;
    - otherwise page kind `index`, `page`, or `article`.
15. For Theme V2 builds, assembles a structured render context with:
    - `site` metadata including `theme_name`, `theme_asset_root`, and full `theme_config`;
    - `page` metadata including kind, layout key, section context, rendered body, and page-level theme metadata;
    - `collections.nav`, `collections.pages`, `collections.backlinks`, and `collections.sections`;
    - built-in and manifest-declared `slots`.
16. Renders Theme V2 templates through `docflow.render_theme_template(...)`, including `{% if %}`, `{% for %}`, and partial includes.
17. Emits HTML files using `core.output_html_path(...)`, respecting configured `route_style` (`pretty` or `direct`).
18. Emits `dist/search-index.json` as part of the standard build artifact set.
19. Reports processed source counts plus page/article breakdown.

Current build pipeline:

```text
Config load
  -> Content discovery (recursive scan + exclude)
  -> Build input load (frontmatter parse + article/page classification)
  -> Active theme resolution (Theme V2 bundle or legacy layout path)
  -> Theme preflight validation
  -> Output cleanup
  -> Public asset copy
  -> Theme asset copy
  -> Theme token CSS emission
  -> Site assembly (pages + navigation)
  -> WikiLink index + backlink index
  -> DocFlow: ParserAdapter -> WikiLinker -> RenderAdapter
  -> Theme render context assembly
  -> HTML + search-index emission
```

### check

`check` shares the same config load, discovery, build-input load, and WikiLink
resolution path as `build`, but stops before rendering/output emission.

Current behavior:

1. Reads config and discovers content.
2. Loads build inputs.
3. Resolves the active theme path using the same Theme V2 vs legacy precedence as `build`.
4. Builds the WikiLink target index.
5. Aggregates non-emitting diagnostics into grouped categories:
   - `theme/template`
   - `frontmatter`
   - `routes`
   - `document`
6. Applies blocking validation for:
   - active theme bundle or legacy layout resolution failures;
   - missing Theme V2 layouts for required page kinds or layout overrides;
   - unsupported Theme V2 page override fields;
   - obvious frontmatter type mismatches, including invalid boolean-like `draft` values;
   - final emitted output path conflicts.
7. Parses each document through format-appropriate parser adapters.
8. Applies WikiLink resolution and records unresolved or ambiguous WikiLink diagnostics as warning-only document diagnostics.
9. Reports processed counts plus grouped error/warning summaries.
10. Returns exit code `0` when only warnings or no diagnostics are present, and `1` when blocking errors are present.
11. Does not clear `dist/`, write HTML, or copy assets.

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

## Content Model

Dual-track classification (no separate directories required):

| File type | Classification |
|-----------|---------------|
| `.html` | Page |
| `.md` with `type: page` in frontmatter | Page |
| other `.md` | Article |

Theme V2 additionally derives a page-kind layout key:

- section/index content -> `index`
- non-index pages -> `page`
- articles -> `article`
- explicit frontmatter `layout` overrides the derived key

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
- `theme`
  - selects the project-local theme directory name used for Theme V2 bundles or legacy theme layouts; defaults to `theme`
- `theme_config`

`theme_config` is preserved as nested `ThemeConfigValue` data rather than flattened at parse time.
Flattening only happens later for Theme V2 token emission.

## Theme V2 Contract

Theme V2 bundles are project-local manifests rooted at `<theme>/theme.json`, where `<theme>` comes from `moonink.json.theme` or defaults to `theme`.
The manifest currently supports:

- `name`
- `layouts`
- `tokens`
- `page_overrides`
- `slots`

Runtime loader guarantees:

- layout sources are loaded eagerly from the manifest map
- missing partial references fail during bundle load
- invalid token names fail during manifest parse
- duplicate token names are rejected
- the built-in Theme V2 bundle under `src/runtime/builtin_theme/` is the default build/check fallback

Legacy compatibility guarantees:

- configured project `<theme>/layout.html` still wins over `template_file` when no Theme V2 bundle exists
- `template_file` still works without a Theme V2 bundle
- the old built-in layout loader remains available for the legacy layout API
- build/check now prefer the built-in Theme V2 bundle when no project bundle or legacy override path exists

## Runtime IO Direction

- `runtime/io.mbt` — project-owned sync filesystem facade over `moonbitlang/x/fs`
- `runtime/async.mbt` — `RuntimeIOTask[T]` wrapper (currently synchronous `Ready(T)`)
- `runtime/native.mbt` — default native runtime adapter for CLI-side side effects
- `runtime/policy.mbt` — conflict and cancellation policy types
- `runtime/config_loader.mbt` — config loading and legacy active-layout resolution
- `runtime/theme_loader.mbt` — Theme V2 bundle loading, token flattening, slot extraction, and built-in bundle fallback
- `runtime/content_discovery.mbt` — recursive content discovery / inventory creation
- preview launch helpers — runtime boundary for dry-run vs native preview execution

Feature modules in `core` and `docflow` expose result-oriented APIs and remain IO-free.
Only `runtime` and `cli` touch the filesystem.

## Current Build And Template Responsibilities

The CLI build layer currently owns several presentation-adjacent integration steps
that are intentionally kept above `docflow` and `core`:

- derive `SitePage` records from build inputs
- assemble navigation from page-only structure plus `nav_title` / `nav_hidden` metadata
- derive section context for the current page
- build page-header HTML and backlink HTML helpers
- compute backlinks from markdown wikilink sources
- validate Theme V2 layout coverage and override allowlists
- merge theme tokens and emit CSS custom properties
- construct Theme V2 render context and hand it to `docflow.render_theme_template(...)`
- decide output paths from `route_style`

This keeps `docflow` focused on parser/render adapter behavior plus generic theme-template rendering while leaving site-wide assembly and theme-contract decisions in the CLI build layer.

## Structural Constraints

- keep `cmd/main` thin (argv normalization only)
- keep `cli_run()` pure for testability
- `core` must remain dependency-free (no `x/fs`, no `markdown`)
- preserve explicit stage boundaries: config -> discovery -> parse -> render -> template -> emit
- keep filesystem access inside `runtime` / CLI runtime entrypoints
- prefer integrating new site-generation behavior into the existing build pipeline rather than introducing parallel pipelines

## Known Gaps

- no structured option parser yet (flags and options are not parsed)
- `serve` in the main workspace validates preview launch and reports readiness, but the real long-running preview server still lives in `native-serve/` rather than the main workspace binary
- Theme V2 bundles are currently project-local only; there is no inheritance or layering implementation yet
- partial loading currently scans the `partials/` directory non-recursively
- tokens only emit scalar string/number/bool values to CSS custom properties
- backlink presentation is still partly exposed as pre-rendered HTML helpers in addition to the richer collection model

## Next Planned Evolution

1. decide whether Theme V2 should grow layered or inheritable bundle composition without breaking the current project-local contract
2. formalize theme-author documentation for the structured `site` / `page` / `collections` / `slots` contract
3. decide whether recursive partial discovery is worth standardizing or whether flat partial sets are sufficient
4. continue strengthening `check` as the non-emitting validation path for theme and content diagnostics
5. add structured command flags such as `--config`, `--output`, or serve host/port overrides
