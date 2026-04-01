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

MoonInk is a static documentation/article generator written in **MoonBit**. It follows a content-first, explicit-stages architecture. The CLI entry point is `cmd/main/main.mbt` → `moonink.mbt` dispatches commands (help, new, build, serve).

## Architecture

The build pipeline flows through explicit stages:

```
CLI (moonink.mbt) → Runtime boundary (runtime_*.mbt)
  → Config load (config.mbt) → Content discovery (content.mbt)
  → DocFlow pipeline: ParserAdapter → WikiLinker → RenderAdapter
  → Templater → SiteConstructor → emit
```

**Key separation:** `cli_run()` is pure (for testing), `cli_exec()` handles real IO. All IO goes through `runtime_io.mbt` which wraps `moonbitlang/x/fs`. Path policy (`io_policy.mbt`) validates all relative paths and blocks parent traversal.

**DocFlow adapters** (`docflow_adapters.mbt`): Registry-based parser/render backends keyed by `SourceFormat`. Markdown backend integrates `mizchi/markdown`. ParsedDocument preserves backend-native payloads rather than forcing a universal AST.

**Runtime boundary** (`runtime_async.mbt`): Generic `RuntimeIOTask[T]` wrapper for future async; currently synchronous (`Ready(T)`).

## MoonBit Conventions

- Code blocks separated by `///|`; block order is irrelevant
- Error handling via `Result[T, E]` and `raise`
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

Located in `fixtures/build_phase1a/`:
- `minimal/` — working project with moonink.toml, docs/, articles/
- `missing_site_name/`, `missing_articles_dir/` — error case fixtures

## Dependencies

- `moonbitlang/x` (0.4.41) — filesystem, env, utilities
- `mizchi/markdown` (0.4.7) — Markdown parse/render backend
