# Multi-Package Restructuring — 2026-04-01

## Goal And Scope

Migrate MoonInk from a single root package (~19 files, ~3000 lines) to a 4-package architecture under `src/`, while simultaneously:

- replacing TOML config with JSON (`moonink.json`);
- adding frontmatter parsing (`core/frontmatter.mbt`);
- adding route generation (`core/route.mbt`) and `PageMeta` type (`core/page_meta.mbt`);
- updating content classification to dual-track by file extension + frontmatter (not directory);
- replacing `moonink new` with `moonink onboard`;
- creating `fixtures/v2/` for the new JSON-based test fixtures.

## Files Changed

**New packages created:**
- `src/core/` — config, content, frontmatter, route, page_meta, model, io_error, io_policy
- `src/docflow/` — parser, adapters, markdown, wikilinker, pipeline
- `src/runtime/` — io, async, native, policy, config_loader, content_discovery
- `src/cli/` — moonink, cli_output, cmd_build, cmd_onboard, cmd_serve
- `src/cmd/main/` — main

**New fixtures:**
- `fixtures/v2/minimal/` — moonink.json, index.md (type:page), hello.md, about.html
- `fixtures/v2/missing_config/` — readme.md only (no moonink.json)
- `fixtures/v2/with_frontmatter/` — article.md and page.md with full frontmatter

**Removed:**
- All root-level `.mbt` files (migrated to packages)
- `cmd/main/` (replaced by `src/cmd/main/`)
- `fixtures/build_phase1a/` (replaced by `fixtures/v2/`)

**Updated:**
- `moon.mod.json` — added `"source": "src"`, bumped version to `0.2.0`
- `CLAUDE.md` — updated architecture section
- `docs/agent-working/MoonInkCliArch.md` — major rewrite
- `docs/technical/00-Architecture.md`, `02-Content-Model.md`, `03-Configuration-Design.md`, `10-CLI-and-Dev-Server.md`

## Design Decisions And Trade-Offs

### 1. Moderate Package Split (4 packages, not ~50)

Chose 4 packages for clean dependency isolation without over-fragmentation. `core` remains IO-free; `runtime` is the only package touching `moonbitlang/x/fs`.

### 2. JSON Over TOML

Replaced custom TOML parser with MoonBit's built-in `@json.parse()`. Reduces maintenance burden; JSON is widely understood and sufficient for the config schema.

### 3. Content Classification Without Directory Structure

Removed the `docs/` + `articles/` directory requirement. MoonInk now scans any folder recursively. Classification uses file extension (`.html` → Page) and frontmatter `type` field (`.md` with `type: page` → Page, otherwise Article). This enables Obsidian vault compatibility.

### 4. Frontmatter Extra Field As `Map[String, String]`

Used `Map[String, String]` instead of `Map[String, Json]` to avoid constructing Json values at runtime (MoonBit Json constructors are read-only). Sufficient for V1 extensibility.

### 5. Two-Pass Classification

Initial discovery defaults all `.md` to Article (no file reads). A planned second pass reads frontmatter to reclassify `type: page` files. This keeps discovery fast and IO-minimal.

## Current Limitations / Placeholders

- build now performs frontmatter-aware source loading, dummy-template rendering, and full HTML emission to `dist/`, but still uses direct-style output paths for this first end-to-end iteration;
- WikiLinker is a no-op stub;
- build still uses the dummy template rather than a real theme/template engine;
- `onboard` command is scaffolded but file-injection logic may need testing with real vaults;
- `serve` is entirely placeholder.

## Test Coverage

50 tests across all 4 packages. All passing. Zero compiler warnings after cleanup.

- `src/core/core_test.mbt` — 21 tests: path policy, JSON config, frontmatter, classification, route generation, output-path mapping
- `src/docflow/docflow_test.mbt` — 14 tests: adapters, registry, markdown backend, pipeline, assembly
- `src/runtime/runtime_test.mbt` — 8 tests: config loading, content discovery, source-backed build inputs, native adapter
- `src/cli/cli_test.mbt` — 7 tests: command parsing, dispatch, real build emission

## Next Implementation Steps

1. restore configurable pretty-route output layout instead of the temporary direct-style emitter mapping;
2. implement Obsidian-compatible WikiLink resolution in `docflow/wikilinker.mbt`;
3. replace the dummy template with a real theme/template system;
4. add structured command flags (`--config`, `--output`, `--dry-run`);
5. decide whether discovery-stage provisional counts should be narrowed now that source-backed build inputs exist.
