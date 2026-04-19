# MoonInk CLI Architecture

## Status

This document is a maintained global architecture note for the MoonInk CLI.
It must be updated whenever the CLI surface, execution flow, or structural
package boundaries change materially.

**Last updated:** 2026-04-19 — reflects the current `help` / `onboard` /
`build` / `check` / `serve` surface, Theme System V2 bundle rendering,
Obsidian direct-output defaults, content-tree asset handling, homepage
inference, and the M1 article-experience contract for metadata, TOC,
contextual backlinks, related notes, and series navigation.

## Current CLI Surface

- `moonink help`
- `moonink onboard` — first-time setup: generates `moonink.json` with vault-friendly defaults and never rewrites note files
- `moonink build` — real static-site build into `dist/`
- `moonink check` — validation-only pass over discovered content; reports diagnostics without writing output
- `moonink serve` — canonical local preview command: builds first, then delegates real HTTP serving to the native-only preview backend
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
  -> @cli.parse_cli_request(argv)
  -> non-serve commands: @cli.cli_exec(argv)
  -> serve command: @cli.run_main_serve_command(...)
  -> prepare_serve_runtime_session(...)         [src/cli/cmd_serve.mbt]
  -> real build pipeline                        [src/cli/cmd_build.mbt]
  -> runtime/native_serve_delegate_command...   [src/runtime/serve.mbt]
  -> native-serve/src/cmd/main -- serve-prebuilt
  -> real mocket HTTP server
```

Pure dispatch behavior:

- `cli_run()` returns "runtime execution required" placeholders for `build`, `check`, and `serve`
- `cli_exec()` crosses the runtime boundary and performs real IO-backed execution

## Current Command Responsibilities

### help

Returns static help text.

### onboard

1. Checks if `moonink.json` already exists.
2. If not: emits a default `moonink.json` configured for `content_dir: "."`, `output_dir: "dist"`, and vault-friendly exclude defaults.
3. Does not scan content files or inject frontmatter.
4. Reports whether config generation succeeded or was aborted to avoid overwriting an existing config.

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
10. Builds the site assembly model from discovered pages, presentation metadata, and navigation.
11. Builds a route-aware WikiLinker index plus article-experience signals:
    - contextual backlinks from markdown wikilink mentions;
    - related-note candidates from link + tag + series overlap;
    - article previous/next navigation;
    - series navigation;
    - markdown heading outlines for TOC rendering.
12. Parses each source document through DocFlow adapters.
13. Applies WikiLink rewriting and collects rendered HTML.
14. For markdown renders, injects stable heading `id` attributes so TOC links can target real anchors.
15. For Theme V2 builds, computes the selected layout key as:
    - `layout` frontmatter override when present;
    - otherwise page kind `index`, `page`, or `article`.
16. For Theme V2 builds, assembles a structured render context with:
    - `site` metadata including `theme_name`, `theme_asset_root`, and full `theme_config`;
    - `page` metadata including kind, layout key, summary/date/updated/tags/series/cover/author/column/reading-time, section context, rendered body, and page-level theme metadata;
    - `collections.nav`, `collections.pages`, `collections.backlinks`, `collections.related`, `collections.toc`, `collections.series`, and `collections.sections`;
    - built-in and manifest-declared `slots`.
17. Renders Theme V2 templates through `docflow.render_theme_template(...)`, including `{% if %}`, `{% for %}`, and partial includes.
18. Emits HTML files using `core.output_html_path(...)`, respecting configured `route_style` (`pretty` or `direct`).
19. Emits `dist/search-index.json` as part of the standard build artifact set.
20. Reports processed source counts plus page/article breakdown.

Obsidian direct-output extensions on top of that baseline:

- content discovery now keeps non-content files as passthrough assets instead of dropping them;
- build-input loading infers homepage metadata from root `index.*` or fallback `README.md`;
- title resolution can use the first Markdown H1 when frontmatter is absent;
- the build preflight rejects passthrough-asset collisions against generated HTML or reserved artifacts;
- content-tree assets are copied into the output root alongside `public/` and theme assets;
- WikiLink rewriting now resolves both note targets and vault resource targets.

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
  -> Site assembly (pages + metadata + navigation)
  -> WikiLink index + article-experience signals
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
   - `wikilinks`
6. Applies blocking validation for:
   - active theme bundle or legacy layout resolution failures;
   - missing Theme V2 layouts for required page kinds or layout overrides;
   - unsupported Theme V2 page override fields;
   - obvious frontmatter type mismatches, including invalid boolean-like `draft` values;
   - final emitted output path conflicts.
7. Parses each document through format-appropriate parser adapters.
8. Applies WikiLink resolution and records unresolved or ambiguous WikiLink diagnostics as warning-only document diagnostics.
9. Adds a non-blocking site warning when no homepage note can be inferred.
10. Reports processed counts plus grouped error/warning summaries.
11. Returns exit code `0` when only warnings or no diagnostics are present, and `1` when blocking errors are present.
12. Does not clear `dist/`, write HTML, or copy assets.

### serve

`serve` in the main workspace is now the canonical preview entry while still
keeping the real HTTP listener in the native-only subproject.

Current main-workspace behavior:

1. Loads config and discovers content.
2. Reuses the real `build_site_result(...)` path to build preview output.
3. Prints build-complete or build-with-warnings output from the main CLI.
4. Delegates the built preview root plus host/port to the native-only preview backend.
5. Lets the delegated backend validate preview startup and own the long-running server lifecycle.

Behavior split:

- `src/cli/cmd_serve.mbt` still exposes dry-run preview helpers for runtime tests and non-blocking validation coverage.
- `src/cmd/main/main.mbt` special-cases `serve` so the user-facing binary can build once and then `exec` into the delegated native preview backend.
- The standalone real preview server still lives in the separate `native-serve/` subproject, which now supports both direct `serve` and internal `serve-prebuilt` entry modes.

## Content Model

Dual-track classification (no separate directories required):

| File type | Classification |
|-----------|---------------|
| `.html` | Page |
| `.md` with `type: page` in frontmatter | Page |
| other `.md` | Article |
| other discovered files under `content_dir` | Static asset copied into output |

Theme V2 additionally derives a page-kind layout key:

- section/index content -> `index`
- non-index pages -> `page`
- articles -> `article`
- explicit frontmatter `layout` overrides the derived key

Article-experience metadata now recognized in frontmatter:

- `summary`
- `updated`
- `series`
- `cover`
- `author`
- `column`
- derived `reading_time_minutes` from source body text

Default exclude patterns now include `.obsidian`, `.git`, `node_modules`, `dist`, `.trash`, `templates`, `Templates`, plus any hidden directory.

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
- build page-header HTML and contextual backlink HTML helpers
- compute backlinks from markdown wikilink mention snippets
- compute related-note candidates from outbound links, reverse links, shared tags, and shared series
- compute article previous/next ordering and series navigation
- derive markdown heading outlines and TOC anchors
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
- `serve` still has no watch mode, live reload, or incremental rebuild behavior
- Theme V2 bundles are currently project-local only; there is no inheritance or layering implementation yet
- partial loading currently scans the `partials/` directory non-recursively
- tokens only emit scalar string/number/bool values to CSS custom properties
- homepage curation, collection pages, RSS/social metadata, and the broader explore layer remain out of scope for this M1 article-experience slice
- related-note scoring is currently a simple heuristic over links, shared tags, and shared series rather than a richer semantic ranking model

## Next Planned Evolution

1. decide whether Theme V2 should grow layered or inheritable bundle composition without breaking the current project-local contract
2. formalize theme-author documentation for the structured `site` / `page` / `collections` / `slots` contract, including the new article-experience fields
3. decide whether homepage curation, topic/tag/series pages, and archive/RSS/social metadata should form the next Quartz-style milestone
4. decide whether recursive partial discovery is worth standardizing or whether flat partial sets are sufficient
5. continue strengthening `check` as the non-emitting validation path for theme and content diagnostics
6. add structured command flags such as `--config`, `--output`, or serve host/port overrides
