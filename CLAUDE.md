# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Test Commands

```bash
moon check          # Type-check (also runs as pre-commit hook)
moon test           # Run all tests
moon test --update  # Run tests and refresh snapshot expectations
moon fmt            # Format code
moon info           # Regenerate .mbti interface files
moon info && moon fmt  # Standard finalization step after changes
moon coverage analyze > uncovered.log  # Coverage report
```

There is no separate lint command; `moon check` and `moon fmt` cover correctness and style.

## Project Overview

MoonInk is a static documentation/article generator written in **MoonBit**. It runs inside existing Markdown folders (ideally Obsidian vaults) and generates static HTML output. Commands: `moonink onboard` (first-time setup), `moonink build`, `moonink serve`.

## Package Structure

```
src/
  core/       # Pure types & logic (zero external deps): config, content model, frontmatter, route, path policy, errors
  docflow/    # Document processing pipeline: parser/render adapters, wikilinker, markdown backend
  runtime/    # IO boundary: filesystem ops, config loader, content discovery (wraps moonbitlang/x/fs)
  cli/        # CLI entry: command parsing, build/onboard/serve dispatch
  cmd/main/   # Binary entry point (is-main: true)
```

Dependency graph: `cmd/main → cli → runtime → core`, `docflow → core`, `cli uses docflow types indirectly through runtime`

## Architecture

The build pipeline flows through explicit stages:

```
CLI (cli/moonink.mbt) → Runtime boundary (runtime/)
  → Config load (moonink.json) → Content discovery (recursive scan + exclude)
  → DocFlow pipeline: ParserAdapter → WikiLinker → RenderAdapter
  → Templater → SiteConstructor → emit to dist/
```

**Key separation:** `cli_run()` is pure (for testing), `cli_exec()` handles real IO. All IO goes through `runtime/io.mbt` which wraps `moonbitlang/x/fs`. Path policy (`core/io_policy.mbt`) validates all relative paths and blocks parent traversal.

**Content model:** Dual-track article/page. `.html` files → Page. `.md` files with frontmatter `type: page` → Page. Other `.md` files → Article. Classification by file extension and frontmatter, not by directory structure.

**Config:** JSON format (`moonink.json`). Parsed via MoonBit's built-in `@json.parse()`.

**DocFlow adapters** (`docflow/adapters.mbt`): Registry-based parser/render backends keyed by `SourceFormat`. Markdown backend integrates `mizchi/markdown`. ParsedDocument preserves backend-native payloads rather than forcing a universal AST.

**Runtime boundary** (`runtime/async.mbt`): Generic `RuntimeIOTask[T]` wrapper for future async; currently synchronous (`Ready(T)`).

## MoonBit Conventions

- Code blocks separated by `///|`; block order is irrelevant
- Error handling via `Result[T, E]` and `raise`; `suberror` for typed error hierarchies
- Test files: `*_test.mbt` (black-box), `*_wbtest.mbt` (white-box)
- Each package has a `moon.pkg` for imports and a generated `pkg.generated.mbti` interface
- Prefer `assert_eq`/`assert_true` for stable results; snapshot tests (`inspect()`) for recording current behavior
- Keep deprecated code in `deprecated.mbt` per directory

## Binding Project Policy

**You must follow `ProjectBasis.md`** — it is binding for all agents. Key requirements:

1. After any completed change, append a dated summary line to `docs/agent-working/worklog/YYYYMMDD.md`
2. Large features require implementation docs under `docs/agent-working/`
3. Architecture-affecting changes require updates to maintained docs under `docs/agent-working/`
4. A task is **incomplete** if required worklog/doc updates are missing

## Test Fixtures

Located in `fixtures/v2/`:
- `minimal/` — working project with moonink.json, index.md (type:page), hello.md, about.html
- `missing_config/` — directory without moonink.json (error case)
- `with_frontmatter/` — article.md and page.md with full frontmatter fields

## Dependencies

- `moonbitlang/x` (0.4.41) — filesystem, env, utilities
- `mizchi/markdown` (0.4.7) — Markdown parse/render backend
