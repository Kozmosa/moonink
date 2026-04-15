# Search Index Implementation 0415

## Goal

Record the completed search-index emission milestone so the current `main`-line architecture now produces a stable search artifact during `moonink build`.

## Scope

Implemented in this milestone:

- a first-version search-index schema in core helpers;
- deterministic excerpt normalization and fallback extraction for markdown, HTML, and unknown source formats;
- runtime timestamp helpers exposed across native, JS, and Wasm targets;
- build-time `dist/search-index.json` emission wired into the standard build artifact path;
- CLI, core, and runtime coverage for artifact shape, excerpt behavior, and clock exposure;
- required Task 5 worklog and implementation-note finalization.

Not implemented in this milestone:

- a search UI, search page, or client-side query logic;
- configurable opt-out or per-document indexing rules;
- weighted ranking, tokenization, section-level indexing, or chunked artifacts;
- theme-side consumption of the emitted artifact;
- separate maintenance docs beyond this task-specific implementation note.

## Files Changed In This Milestone

Implementation files already completed for the feature:

- `src/core/search_index.mbt`
- `src/core/core_test.mbt`
- `src/core/pkg.generated.mbti`
- `src/runtime/search_index_clock.c`
- `src/runtime/search_index_clock.mbt`
- `src/runtime/search_index_clock_js.mbt`
- `src/runtime/search_index_clock_native.mbt`
- `src/runtime/search_index_clock_wasm.mbt`
- `src/runtime/runtime_test.mbt`
- `src/runtime/moon.pkg`
- `src/runtime/pkg.generated.mbti`
- `src/cli/cmd_build.mbt`
- `src/cli/cli_test.mbt`
- `fixtures/v2/search_index_contract/moonink.json`
- `fixtures/v2/search_index_contract/index.md`
- `fixtures/v2/search_index_contract/guide.md`
- `fixtures/v2/search_index_contract/about.html`

Task 5 finalization files:

- `docs/agent-working/worklog/20260415.md`
- `docs/agent-working/SearchIndexImpl0415.md`

## Design Decisions And Trade-offs

### Emit search index as a required build artifact

The feature emits `search-index.json` from the existing build flow instead of creating a separate command or optional artifact. This keeps the contract simple for downstream consumers: if `moonink build` succeeds, the search index exists beside the generated HTML.

The trade-off is that index emission failure now fails the build, but that is consistent with treating the artifact as part of the standard output contract rather than a best-effort extra.

### Keep schema construction in core helpers

The schema wrapper and JSON serialization live in `src/core/search_index.mbt`, which keeps the item/document contract independent of CLI orchestration and makes the artifact format easier to test directly.

The trade-off is a small amount of hand-rolled JSON assembly, but this avoids introducing a broader serialization dependency for a narrow, stable schema.

### Prefer deterministic text normalization over smart summarization

Excerpt generation prefers frontmatter text when present, then falls back to deterministic source normalization. Markdown excerpts strip lightweight syntax markers and link destinations while HTML excerpts strip tags.

The trade-off is that excerpts stay predictable and easy to test, but they are intentionally simple and do not attempt richer summarization, weighting, or semantic extraction.

### Use target-specific runtime clock bridges

`generated_at` is provided through dedicated runtime helpers for native, JS, and Wasm targets rather than hardcoding one platform path. That keeps the build artifact contract available across compilation targets.

The trade-off is a few small runtime bridge files, but it avoids target drift and keeps timestamp generation off the CLI layer.

## Current Limitations

- The artifact contract is fixed at version 1 and does not yet include richer fields such as content type, headings, or structured excerpts.
- Searchable content is emitted as one item per routed document; there is no section-level indexing.
- Excerpt fallback is normalization-based and does not trim to a ranked or length-bounded summary.
- There is no theme or frontend integration in this milestone, so consumers must be added separately.
- Search inclusion is currently implicit for routed content; there is no per-document configuration yet.

## Next Implementation Steps

1. Decide whether themes should receive a documented built-in search-loader contract for consuming `search-index.json`.
2. Add optional schema extensions only if there is a concrete consumer need, preserving `version: 1` compatibility for existing fields.
3. Consider explicit inclusion/exclusion controls once real content sets make indexing scope a user-facing concern.
4. If search UX work begins, add fixture-backed coverage that validates the emitted artifact against the consuming frontend contract.

## Validation Completed

Final verification requested for Task 5:

- `moon test src/core`
- `moon test src/runtime`
- `moon test src/cli`
- `moon check`
- `moon info`
- `moon fmt`
