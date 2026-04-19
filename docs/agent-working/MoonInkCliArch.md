# MoonInk CLI Architecture

## Status

This document is a maintained global architecture note for the MoonInk CLI.
It must be updated whenever the CLI surface, execution flow, or structural
package boundaries change materially.

**Last updated:** 2026-04-20 — reflects the current `help` / `onboard` /
`build` / `check` / `serve` surface, Theme System V2 bundle rendering,
Obsidian direct-output defaults, content-tree asset handling, homepage
inference, the M1 article-experience contract, the M2 search/public-shell
contract, and the M3 metadata/surface contract for draft exclusion, search
exclusion, homepage modules, generated search/tag/series/archive pages, and
typed site author/profile data, plus the single-binary runtime-compatibility
slice for host-path config resolution, embedded built-in theme fallback, and
main-binary native preview startup with process exit-code propagation.

## Current CLI Surface

- `moonink help`
- `moonink onboard` — first-time setup: generates `moonink.json` with vault-friendly defaults and never rewrites note files
- `moonink build` — real static-site build into `dist/`
- `moonink check` — validation-only pass over discovered content; reports diagnostics without writing output
- `moonink serve` — canonical local preview command: builds into a protected preview pipeline and starts the native-only in-process HTTP preview backend
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
cmd/main -> runtime
cmd/main -> oboard/mocket
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
  -> run_main_native_entry(argv)               [src/cmd/main/native_serve.mbt]
  -> hidden internal serve-prebuilt?           [src/cmd/main/native_serve.mbt]
  -> otherwise @cli.parse_cli_request(argv)
  -> non-serve commands: @cli.cli_exec(argv)
  -> serve command: run_main_native_serve_command(...)
  -> prepare_serve_watch_result(...)            [src/cli/serve_watch.mbt]
  -> staged preview build + publish             [src/cli/serve_watch.mbt]
  -> runtime/launch_preview_result(...)         [src/runtime/serve.mbt]
  -> native preview preflight                   [src/runtime/preview_startup*.mbt]
  -> real mocket HTTP server                    [src/cmd/main/native_serve.mbt]
  -> apply_exit_code(outcome.exit_code)
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
4. Filters `draft: true` entries out of the published build.
5. Resolves the active presentation path with this precedence:
   - configured project Theme V2 bundle at `<theme>/theme.json` when `moonink.json.theme` is set, otherwise `theme/theme.json`;
   - configured project legacy `<theme>/layout.html` when `moonink.json.theme` is set, otherwise `theme/layout.html`, if no project bundle exists;
   - configured `template_file` if no project bundle or legacy project layout exists;
   - embedded built-in Theme V2 bundle otherwise.
6. For Theme V2 builds, validates every source-backed page and generated system surface against the manifest contract before output cleanup:
   - the selected layout key must exist;
   - page overrides must be allowlisted by `page_overrides`.
7. Fully clears `output_dir` before rebuilding.
8. Copies project-root `public/` assets into the output root.
9. Copies active project theme assets or embedded built-in theme assets into `dist/assets/`.
10. For Theme V2 builds, emits `dist/assets/theme-vars.css` from declared manifest tokens plus `theme_config` overrides.
11. Ensures the generated search client asset exists at `dist/assets/moonink-search.js`, even when a custom Theme V2 bundle falls back to `page` for generated surfaces.
12. Builds the site assembly model from published pages, shared card data, collection surfaces, and navigation.
13. Builds a route-aware WikiLinker index plus article-experience signals:
    - outbound relationship mentions from resolved markdown wikilinks;
    - contextual backlinks from markdown wikilink mentions;
    - related-note candidates from link + tag + series overlap;
    - article previous/next navigation;
    - series navigation;
    - markdown heading outlines for TOC rendering.
14. Parses each source document through DocFlow adapters.
15. Applies WikiLink rewriting and collects rendered HTML.
16. For markdown renders, injects stable heading `id` attributes so TOC links can target real anchors.
17. For Theme V2 builds, computes the selected layout key as:
    - `layout` frontmatter override when present;
    - otherwise page kind `index`, `page`, or `article`.
18. For Theme V2 builds, assembles a structured render context with:
    - `site` metadata including `theme_name`, `theme_asset_root`, full `theme_config`, typed `author`, and generated-surface URLs for `search`, `tags`, `series`, and `archive`;
    - `page` metadata including shared behavior fields such as `featured`, `pinned`, `search`, `published_at`, `freshness_at`, author display, homepage hero fields, section context, rendered body, and page-level theme metadata;
    - `collections.nav`, `collections.pages`, `collections.backlinks`, `collections.related`, `collections.relationships`, `collections.toc`, `collections.series`, `collections.sections`, `collections.homepage_featured`, `collections.homepage_recent`, `collections.search_cards`, `collections.tag_pages`, `collections.series_pages`, and `collections.archive_months`;
    - built-in and manifest-declared `slots`.
19. Renders Theme V2 templates through `docflow.render_theme_template(...)`, including `{% if %}`, `{% for %}`, and partial includes.
20. Emits source-backed HTML files using `core.output_html_path(...)`, respecting configured `route_style` (`pretty` or `direct`).
21. Emits generated public surfaces for `/search/`, `/tags/`, `/series/`, and `/archive/`, using dedicated Theme V2 layouts when available and `page` as the fallback for custom bundles.
22. Emits `dist/search-index.json` and `dist/rss.xml` as standard build artifacts, with `search-index.json` excluding drafts and `search: false` pages.
23. Injects canonical, Open Graph, and RSS `<head>` metadata through Theme V2 `head` slots.
24. Reports processed source counts plus page/article breakdown.

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
  -> Search client asset ensure
  -> Site assembly (pages + metadata + navigation)
  -> WikiLink index + article-experience signals
  -> DocFlow: ParserAdapter -> WikiLinker -> RenderAdapter
  -> Theme render context assembly
  -> Source-backed HTML emission
  -> Search-index + RSS emission
  -> Generated search/tag/series/archive surface emission
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
   - missing Theme V2 layouts for generated system surfaces unless the bundle can fall back to `page`;
   - unsupported Theme V2 page override fields;
   - obvious frontmatter type mismatches, including invalid boolean-like `draft`, `featured`, `pinned`, `search`, and `toc` values;
   - invalid author-facing `layout` values;
   - final emitted output path conflicts.
7. Parses each document through format-appropriate parser adapters.
8. Applies WikiLink resolution and records unresolved or ambiguous WikiLink diagnostics as warning-only document diagnostics.
9. Adds a non-blocking site warning when no homepage note can be inferred.
10. Reports processed counts plus grouped error/warning summaries.
11. Returns exit code `0` when only warnings or no diagnostics are present, and `1` when blocking errors are present.
12. Does not clear `dist/`, write HTML, or copy assets.

### serve

`serve` in the main workspace is now the canonical single-binary preview entry.

Current main-workspace behavior:

1. Resolves `--config` as a host path, normalizes it to an absolute config path, and derives the absolute project root from that config file.
2. Loads config and discovers content from the derived project root.
3. Builds preview output into a hidden staging directory instead of writing directly into the live preview root.
4. Writes preview-only runtime artifacts under `dist/__moonink/`, including `live-reload.js` and `preview-status.json`.
5. Publishes staging output into the live preview root only after a successful build.
6. Validates native preview startup requirements against the published preview root.
7. Starts the real mocket HTTP server in-process from the main binary.

Behavior split:

- `src/cli/cmd_serve.mbt` still exposes dry-run preview helpers plus the shared build-before-serve orchestration used by tests and the native main entry.
- `src/cli/serve_watch.mbt` now primarily owns protected preview staging/publish plus preview status artifacts; file watching is no longer part of the supported runtime contract for this slice.
- `src/cmd/main/native_serve.mbt` owns the real in-process mocket startup plus a hidden internal `serve-prebuilt` mode for native smoke validation.
- `src/cmd/main/main.mbt` propagates `CliOutcome.exit_code` to the process so detached shell and CI callers can observe fatal runtime/build/serve failures.
- `native-serve/` remains in the repository as a migration shim rather than a required runtime dependency.
- Real preview serving is intentionally native-only. JS/Wasm targets stop at dry-run/runtime helpers rather than launching an HTTP server.

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
- author-facing `layout: home` normalizes to the internal `index` layout key
- generated system pages use system-owned layout keys such as `search`, `tag`, `series`, and `archive`, with Theme V2 bundles allowed to fall back to `page`

Article-experience metadata now recognized in frontmatter:

- `summary`
- `updated`
- `series`
- `cover`
- `author`
- `column`
- `draft`
- `featured`
- `pinned`
- `search`
- `toc`
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
- `author`
  - typed site-level author/profile metadata used by homepage presence, article author cards, and shared card labels

`theme_config` is preserved as nested `ThemeConfigValue` data rather than flattened at parse time.
Flattening only happens later for Theme V2 token emission.
The M2 build currently reads `theme_config.homepage.hero_title`,
`hero_summary`, `featured_paths`, and `recent_count` for homepage curation.

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
- the embedded built-in Theme V2 bundle generated from `src/runtime/builtin_theme/` and exposed by `runtime/builtin_theme_embedded.mbt` is the default build/check fallback and does not require repository path probing at runtime

Legacy compatibility guarantees:

- configured project `<theme>/layout.html` still wins over `template_file` when no Theme V2 bundle exists
- `template_file` still works without a Theme V2 bundle
- the old built-in layout loader remains available for the legacy layout API
- build/check now prefer the built-in Theme V2 bundle when no project bundle or legacy override path exists
- generated surfaces use Theme V2 layout keys `search`, `collection`, and `archive`, and fall back to `page` when a custom bundle omits them

## Runtime IO Direction

- `runtime/io.mbt` — project-owned sync filesystem facade over `moonbitlang/x/fs`
- `runtime/async.mbt` — `RuntimeIOTask[T]` wrapper (currently synchronous `Ready(T)`)
- `runtime/native.mbt` — default native runtime adapter for CLI-side side effects
- `runtime/policy.mbt` — conflict and cancellation policy types
- `runtime/host_paths.mbt` — host-path resolution helpers for cwd-relative vs absolute config inputs
- `runtime/config_loader.mbt` — config loading and legacy active-layout resolution
- `runtime/builtin_theme_embedded.mbt` — typed embedded built-in theme manifest/layout/partial/asset accessors
- `runtime/theme_loader.mbt` — Theme V2 bundle loading, token flattening, slot extraction, and built-in bundle fallback
- `runtime/content_discovery.mbt` — recursive content discovery / inventory creation
- preview launch helpers — runtime boundary for dry-run vs native preview execution
- `runtime/preview_startup*.mbt` — native preview startup preflight for host/port binding

Feature modules in `core` and `docflow` expose result-oriented APIs and remain IO-free.
Only `runtime` and `cli` touch the filesystem.

## Current Build And Template Responsibilities

The CLI build layer currently owns several presentation-adjacent integration steps
that are intentionally kept above `docflow` and `core`:

- derive `SitePage` records from build inputs
- assemble navigation from page-only structure plus `nav_title` / `nav_hidden` metadata
- derive section context for the current page
- build page-header HTML and contextual backlink HTML helpers
- compute article-local relationship mentions from resolved outbound wikilinks
- compute backlinks from markdown wikilink mention snippets
- compute related-note candidates from outbound links, reverse links, shared tags, and shared series
- compute article previous/next ordering and series navigation
- derive markdown heading outlines and TOC anchors
- validate Theme V2 layout coverage and override allowlists
- merge theme tokens and emit CSS custom properties
- build homepage curation modules from `theme_config.homepage`
- generate `/search/`, `/tags/`, `/series/`, and `/archive/`
- render reusable canonical / Open Graph / RSS metadata slots
- emit `rss.xml`
- construct Theme V2 render context and hand it to `docflow.render_theme_template(...)`
- decide output paths from `route_style`

This keeps `docflow` focused on parser/render adapter behavior plus generic theme-template rendering while leaving site-wide assembly and theme-contract decisions in the CLI build layer.

## Structural Constraints

- keep `src/cmd/main/main.mbt` thin (argv normalization plus exit propagation only); native preview helpers belong in sibling files
- keep `cli_run()` pure for testability
- `core` must remain dependency-free (no `x/fs`, no `markdown`)
- preserve explicit stage boundaries: config -> discovery -> parse -> render -> template -> emit
- keep filesystem access inside `runtime` / CLI runtime entrypoints
- prefer integrating new site-generation behavior into the existing build pipeline rather than introducing parallel pipelines

## Known Gaps

- real preview startup is only supported on native targets; JS/Wasm targets stop at dry-run/runtime helpers instead of launching an HTTP server
- the protected preview pipeline still emits `live-reload.js` / `preview-status.json` artifacts even though hot reload and file watching are not part of the supported contract for this slice
- Theme V2 bundles are currently project-local only; there is no inheritance or layering implementation yet
- partial loading currently scans the `partials/` directory non-recursively
- tokens only emit scalar string/number/bool values to CSS custom properties
- generated collection scope is currently limited to tags, series, and archive; topics and column-root pages are still out of scope
- `search: false` only removes pages from the search index; it is not yet a general publication-visibility control
- homepage curation is intentionally small and config-driven rather than a general module DSL
- related-note scoring is currently a simple heuristic over links, shared tags, and shared series rather than a richer semantic ranking model

## Next Planned Evolution

1. decide whether `serve` should later regain file watching / hot reload as a separate explicitly scoped slice
2. decide whether Theme V2 should grow layered or inheritable bundle composition without breaking the current project-local contract
3. formalize theme-author documentation for the structured `site` / `page` / `collections` / `slots` contract, including the new generated-surface and homepage-curation fields
4. decide whether recursive partial discovery is worth standardizing or whether flat partial sets are sufficient
5. continue strengthening `check` as the non-emitting validation path for theme and content diagnostics
