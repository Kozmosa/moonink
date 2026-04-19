# Quartz Garden M4 Implementation 0419

## Goal

Implement the M4 slice of the 2026-04-19 Quartz-style roadmap on top of the
current `main` baseline:

- upgrade `serve` from one-shot preview startup to watch-mode preview;
- add preview-time full-page reload and clearer failure visibility;
- improve rebuild efficiency without introducing a second build pipeline;
- strengthen article-local discovery through a dedicated relationship section.

This implementation intentionally stays on the current repository baseline
instead of waiting for a future fully landed M2/M3 product shell.

## Files Changed

Serve and runtime:

- `src/cli/cmd_serve.mbt`
- `src/cli/serve_watch.mbt`
- `src/runtime/io.mbt`
- `src/runtime/serve_process.mbt`
- `src/runtime/serve_process_native.mbt`
- `src/runtime/serve_process_stub.mbt`
- `src/runtime/serve_delegate.c`
- `src/runtime/moon.pkg`

Relationship-aware article presentation:

- `src/core/model.mbt`
- `src/cli/cmd_build.mbt`
- `src/runtime/builtin_theme/layouts/article.html`
- `src/runtime/builtin_theme/assets/moonink-default.css`

Tests and docs:

- `src/cli/cli_test.mbt`
- `docs/technical/10-CLI-and-Dev-Server.md`
- `docs/technical/07-Linking-and-WikiLink.md`
- `docs/technical/08-Theme-System.md`
- `docs/agent-working/MoonInkCliArch.md`
- `docs/agent-working/QuartzGardenM4Impl0419.md`
- `docs/agent-working/worklog/20260419.md`

## What Landed

### Watch-mode preview with protected output publishing

`moonink serve` no longer rebuilds directly into the live preview root.
Preview builds now render into a hidden staging output under `.moonink-preview/`
first. Only a successful rebuild is copied into the real preview root.

That keeps the last successful site output available when a rebuild fails.

### Preview runtime artifacts and full-page reload

Serve-mode output now includes preview-only artifacts under:

- `dist/__moonink/live-reload.js`
- `dist/__moonink/preview-status.json`

Theme V2 preview builds inject the reload script through `slots.scripts`, and a
post-template fallback also ensures legacy or custom layouts still receive the
script tag.

The browser client polls `preview-status.json`, reloads on revision changes,
and shows a small overlay when the latest rebuild ended with warnings or errors.

### Incremental rebuild reuse

Preview rebuilds still reuse the standard config/discovery/build pipeline, but
they now cache unchanged DocFlow stages in memory:

- parsed documents;
- wikilink-applied documents;
- rendered HTML before templating.

Reuse is keyed by per-source content fingerprints plus a site-wide link-target
signature. If link targets change, cached parsed documents remain reusable but
linked/rendered artifacts are recomputed conservatively.

### Stronger article-local relationship navigation

Article pages now expose a dedicated “Explore this thread” block with three
ordered relationship groups:

- `Mentioned here`
- `Referenced by`
- `Keep reading`

Theme V2 now receives a structured `collections.relationships` object that
contains grouped relationship collections in addition to the existing backlink
and related-note collections.

## Design Decisions

### Keep preview state outside the normal build artifact contract

Preview-only state lives under `__moonink/` and is written only by `serve`.
Normal `build` output remains free of live-reload assets.

### Reuse the existing build pipeline instead of forking it

The serve path now has a dedicated safe-output wrapper, but it still reuses the
same discovery, theme resolution, site assembly, DocFlow parsing, and template
rendering logic as `build`.

### Prefer conservative caching over partial output writes

M4 adds meaningful incremental reuse without trying to standardize a more risky
partial-emission or per-page publish contract.

## Current Limitations

- preview serving is still native-only;
- rebuild publishing is protected but not fully atomic;
- watch mode uses polling rather than platform-specific file notification APIs;
- the new relationship surface is article-local and does not yet add a full
  standalone `/explore/` page;
- related-note ranking is still heuristic rather than semantic.

## Validation

Validation completed for this slice:

- `moon check`
- `moon test src/cli`
- `moon test`
- `moon check --target native`
- `moon check --manifest-path native-serve/moon.mod.json --target native`

Final handoff validation still required:

- `moon info`
- `moon fmt`
