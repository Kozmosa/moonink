# MoonInk Search Index Design

_Date_: 2026-04-15

## Context

MoonInk already builds structured site output from parsed content, route generation, wikilink rewriting, and theme/template rendering. The current pipeline can emit HTML pages and supporting static assets, and recent work has strengthened backlinks and `check`-time diagnostics. However, there is still no first-class search index artifact that themes or frontend scripts can consume.

A search feature is already implied by the project roadmap and technical docs. The next useful slice is not a full search UI; it is a stable build artifact that exposes searchable document metadata in a predictable JSON format.

## Goal

Enhance `moonink build` so it always emits a versioned search index file at:

- `dist/search-index.json`

This file should be a standard build artifact, produced alongside HTML output, and should provide a stable consumption contract for future theme code or frontend search scripts.

The first version of the search index should:

- cover both `Article` and `Page` content;
- include `title`, `url`, `excerpt`, `tags`, and `date` for each indexed item;
- prefer frontmatter-provided `excerpt` and fall back to derived body text when missing;
- use final build routes so index URLs exactly match generated site links.

## Non-goals

This design intentionally does **not** include:

- a search UI, search page, or search box;
- query ranking, tokenization, stemming, highlighting, or fuzzy matching;
- chunked or sharded indexes;
- incremental index generation;
- configurable per-document inclusion/exclusion rules;
- a new standalone search-index command;
- re-parsing rendered HTML to derive search data.

## Recommended approach

Generate the search index directly at the end of the existing `build` flow.

This is the chosen approach because it keeps the feature small, direct, and aligned with how MoonInk already thinks about build artifacts. The site build already computes the information needed for search—content classification, metadata, and final routes—so the search index should be emitted from those in-memory results rather than by introducing a separate pipeline stage.

A more explicit standalone search-index generation stage was considered, but deferred. For this slice, the priority is to ship a stable artifact and schema quickly, not to introduce extra internal structure before the feature proves itself.

## Design

### 1. Emit a standard search artifact from `build`

`moonink build` should write `search-index.json` into the same output root as the generated HTML.

This file is part of the normal build contract, just like HTML pages. It is not gated behind config or a CLI flag in the first version.

Expected top-level structure:

```json
{
  "version": 1,
  "generated_at": "2026-04-15T00:00:00Z",
  "items": [
    {
      "title": "Hello World",
      "url": "/hello.html",
      "excerpt": "A short introduction...",
      "tags": ["intro", "demo"],
      "date": "2026-04-01"
    }
  ]
}
```

`version` gives the schema an explicit evolution point. `generated_at` records when the artifact was produced. `items` contains the indexed content records.

### 2. Define a stable first-version item contract

Each indexed item should expose:

- `title: String`
- `url: String`
- `excerpt: String`
- `tags: Array[String]`
- `date: String | null`

The contract should stay stable across implementation refactors. Consumers should be able to depend on:

- the artifact path;
- the top-level wrapper object;
- the field names and base types above.

Future versions can extend the schema, but this first slice should avoid optional shape drift.

### 3. Source fields from existing build metadata

Search data should come from the same structured content model already used by build. The implementation should not inspect rendered HTML or re-run content discovery.

Field sourcing rules:

- `title`
  - use the existing resolved title already available in page/article metadata;
  - do not add new title inference rules in this slice.

- `url`
  - use the final resolved route that build will emit;
  - the value must match the actual generated site link.

- `excerpt`
  - if frontmatter provides an excerpt, use it;
  - otherwise derive a plain-text summary from the document body;
  - the fallback should be deterministic and simple rather than “smart.”

- `tags`
  - use frontmatter tags;
  - if absent, emit `[]`.

- `date`
  - use the frontmatter date field;
  - if absent, emit `null`.

### 4. Index both articles and pages

The first version should include both `Article` and `Page` documents.

This keeps the user-facing rule simple: if content is part of the generated site and has a route, it is searchable by default. There is no need in the first version to distinguish “searchable articles” from “navigable pages.”

### 5. Treat search-index emission as a required build artifact

If the build reaches the artifact-writing stage, `search-index.json` must also be written successfully. Failure to emit the search index should fail the overall build.

That behavior is appropriate because the index is defined as a standard output artifact, not a best-effort extra. Silent omission would make the contract unreliable for themes or scripts that depend on it.

## Files to modify

Primary files:
- `src/cli/cmd_build.mbt`
- search-related build/runtime helpers already participating in final page metadata assembly
- `src/cli/cli_test.mbt`

Likely supporting reads only:
- `src/core/page_meta.mbt`
- `src/docflow/pipeline.mbt`
- `docs/technical/09-Search-Index.md`
- relevant fixture directories under `fixtures/v2/`

## Testing strategy

### Add build coverage for artifact creation

Add a build test that verifies `moonink build` writes:

- the normal HTML outputs; and
- `dist/search-index.json`

This confirms the artifact is part of the default build contract.

### Verify item inclusion scope

Add coverage showing that both:
- article content; and
- page content

appear in the index when they are part of the site output.

### Verify field sourcing rules

Add fixture-backed tests for:
- frontmatter excerpt taking precedence over derived excerpt;
- missing excerpt falling back to body-derived text;
- missing tags producing `[]`;
- missing date producing `null`.

### Verify route consistency

Assert that indexed `url` values match the same final route paths used by generated output files.

### Verify schema stability

Add tests that confirm:
- top-level `version`, `generated_at`, and `items` exist;
- item field names match the contract;
- base field types remain stable for the first version.

## Trade-offs

### Why not create a separate search-index pipeline stage now?

Because the chosen goal is to ship a stable output contract with the smallest amount of internal movement. A dedicated stage may become useful later, but it is not required to make search-index output correct or useful in the first iteration.

### Why not make search-index generation optional?

Because that would weaken the consumption contract immediately. If search support is a standard site capability, the artifact should be produced consistently by default.

### Why not derive excerpts from rendered HTML?

Because the search index should be generated from canonical structured content, not from output that has already been transformed by templates or HTML rendering. Reusing build metadata keeps the source of truth single and predictable.

## Success criteria

This feature is complete when:

1. `moonink build` writes `dist/search-index.json` by default.
2. The file uses a versioned wrapper object with `version`, `generated_at`, and `items`.
3. Each indexed item exposes `title`, `url`, `excerpt`, `tags`, and `date`.
4. `Article` and `Page` content are both included.
5. `excerpt` prefers frontmatter and otherwise falls back to body-derived text.
6. Search-index write failure fails the build instead of being silently ignored.

## Verification

Planned verification commands:

- `moon test src/cli`
- `moon check`
- `moon info && moon fmt`

Targeted behavior to verify:
- build emits search-index.json by default;
- item URLs match final build routes;
- excerpt sourcing rules behave as specified;
- missing tags/date produce stable fallback values;
- schema shape remains stable for the first version.
