# MoonInk M3 Frontmatter-Driven Site Behavior And Collection Contract Design

_Date_: 2026-04-19

## Context

MoonInk has already established the M1 article surface and is using M2 to turn search and the public site shell into first-class product surfaces. The next milestone should not add more page families. It should make the existing public output behave deliberately by moving visibility, ordering, and surface contracts out of theme-time guesswork and into typed metadata plus build-owned rules.

This milestone exists to make the generated site feel intentional rather than merely well-rendered. The key shift is that homepage, search, tags, series, and archive should stop relying on ad hoc template logic and instead consume a stable content contract defined by the build pipeline.

## Goal

Define the M3 metadata and build contracts that drive site behavior across the existing public surfaces:

- `homepage`
- `search`
- `tags`
- `series`
- `archive`

The result should be a build output whose visibility, ordering, card presentation, and author presence are predictable and configurable through stable metadata rather than implicit defaults.

## Confirmed decisions

- M3 collection and surface contract scope is limited to the existing page family: `homepage`, `search`, `tags`, `series`, and `archive`.
- The canonical search exclusion contract remains `search: false`; M3 does not rename it to `search_exclude`.
- `draft: true` is excluded from the standard published build entirely. Future preview-only exceptions may exist later, but M3 does not implement them.
- Ordering uses two derived time axes:
  - `published_at = date`
  - `freshness_at = updated ?? date`
- Richer author/profile metadata is site-led through `moonink.json`, while page-level author fields remain limited overrides.
- The recommended implementation approach is `contract-first, build-owned`.

## Non-goals

This design intentionally does not include:

- introducing new page families such as `topics`, `author`, `about`, or `now`;
- implementing preview-specific draft behavior in `serve`;
- building a general plugin or extension API for metadata-driven surfaces;
- turning `layout` into an arbitrary page-routing or theme-programming mechanism;
- shifting core ordering and visibility decisions into JavaScript or templates.

## Recommended approach

The recommended approach is `contract-first, build-owned`.

In this approach, `src/core/` owns typed metadata and derived site models, the build pipeline computes visibility and ordering decisions once, and the theme consumes prepared surface models. This keeps M3 aligned with the current architecture while preventing homepage, search, collection pages, RSS, and public metadata outputs from developing separate implicit rules.

Two alternatives were considered and rejected as the primary route:

- `theme-first normalization` would keep most behavior scattered across CLI and theme rendering logic. It would ship faster in the short term but would weaken the long-term contract.
- `full metadata platform` would formalize every merge rule and page family at once. That would exceed the confirmed M3 scope and turn the milestone into a broader platform refactor.

## Design

### 1. Architecture boundaries

M3 should split responsibility across the existing layers in a stricter way.

`src/core/frontmatter.mbt` should own the typed page-level behavior fields. This layer is responsible for parsing, field-shape tracking, and scalar validation for metadata that changes site behavior.

`src/core/config.mbt` should own typed site-level author/profile metadata. Metadata that affects author cards, homepage author presence, RSS author output, and public head metadata should no longer live only inside generic `theme_config` objects.

`src/core/model.mbt` should own the derived build-facing models that all public surfaces share. This includes derived time fields, visibility flags, card models, and collection page models.

The build path in `src/cli/` and supporting site-surface helpers should aggregate site-wide state once, compute visibility and ordering once, and emit prepared models for the theme to render. The theme should not invent its own visibility, ranking, or card-shape rules.

`theme_config` remains valid, but its scope narrows to composition and presentation concerns such as homepage module arrangement and theme-specific visual settings. Publication semantics, ordering semantics, and shared card semantics move into core/build contracts.

### 2. Page metadata contract

M3 should formalize the following page-level fields as typed behavior controls instead of leaving them as loosely interpreted extras:

- `draft: Bool`
- `featured: Bool`
- `pinned: Bool`
- `search: Bool` with canonical author-facing usage `search: false`
- `toc: Bool?`
- `layout: String?`
- `author: String?` as a limited page-level override

Recommended semantics:

- `draft` defaults to `false`
- `featured` defaults to `false`
- `pinned` defaults to `false`
- `search` defaults to `true`
- `toc` is tri-state:
  - unset means use the system default behavior;
  - `true` means force show;
  - `false` means force hide.
- `layout` is optional and validated against a closed set of allowed values.
- `author` is optional and only affects the displayed page-level byline or label.

Malformed scalar values for these fields should produce explicit `check` diagnostics rather than silently degrading.

### 3. Site metadata contract

M3 should add a typed site-level author/profile model in `moonink.json` for the metadata that multiple surfaces consume.

The minimum stable model should cover:

- author identity used across the site;
- author bio/presence copy for cards and homepage blocks;
- author avatar or image reference;
- author links for public profile surfaces and feeds;
- optional homepage-facing profile text that expresses author presence.

The exact JSON schema can stay compact, but the contract must be typed rather than buried in free-form theme configuration. This is necessary because author/profile data is no longer just theme decoration. It affects the default product surface.

Page-level `author` should remain a narrow override. It may replace the displayed name string on a page, but it should not redefine avatar, bio, or profile links. M3 does not introduce a full multi-author merge system.

### 4. Derived visibility and time semantics

M3 should define stable derived fields that every public surface can rely on.

Visibility rules:

- `draft: true` excludes the document from standard output entirely.
- A draft document produces no emitted page and does not participate in `homepage`, `search`, `tags`, `series`, `archive`, `RSS`, or public head metadata outputs.
- `search: false` excludes the document only from search artifacts and search results.
- A non-draft document with `search: false` still participates in homepage and collection surfaces when it otherwise qualifies.

Time rules:

- `published_at = date`
- `freshness_at = updated ?? date`

Stability rules:

- for date-based lists, dated content sorts ahead of undated content;
- when two entries have the same effective time, ordering falls back to `source_path` ascending;
- surfaces must not rely on filesystem traversal order for ties.

This gives M3 two different editorial meanings:

- `published_at` represents release chronology;
- `freshness_at` represents recent activity.

### 5. Shared card contract

M3 should introduce a build-owned shared card model used by homepage modules, search results, and collection pages.

The shared card model should expose a stable subset of fields:

- title;
- url;
- summary or excerpt;
- display date;
- `published_at` and `freshness_at`;
- tags;
- series label when present;
- cover or hero image reference when present;
- author label;
- `featured` and `pinned` flags.

Card density should also be normalized as a small closed set owned by the surface contract rather than re-decided in every template. A compact but sufficient model is:

- `hero`
- `standard`
- `compact`

Recommended default surface mapping:

- homepage featured modules use `hero` or `standard`;
- homepage recent lists and tag/series pages use `standard`;
- search results and archive lists use `compact`.

The theme still controls the visual treatment. What M3 standardizes is which data fields and density tiers a surface can rely on.

### 6. Surface-specific contract

#### Homepage

Homepage composition remains configuration-driven, but auto-generated modules should use the shared contract.

- Explicit curated homepage entries continue to come from site configuration.
- `featured: true` is a signal for homepage featured surfaces, but explicit homepage configuration wins when both exist.
- Automatically generated recent content uses `pinned desc`, then `freshness_at desc`, then `source_path asc`.

#### Search

Search remains relevance-first.

- Search eligibility is controlled only by draft exclusion and `search: false`.
- Search ranking stays relevance-driven.
- Tie-breaking uses `pinned desc`, then `freshness_at desc`, then `source_path asc`.
- Search should consume the shared card contract where possible instead of inventing a separate result view model.

#### Tags

- Tag pages group by exact tag string.
- Within a tag page, ordering uses `pinned desc`, then `freshness_at desc`, then `source_path asc`.
- Undated entries are allowed and sort after dated entries.

#### Series

- Series pages group by exact series name.
- Series ordering is reading-order oriented, not recency oriented.
- Within a series, ordering uses `published_at asc`, then `source_path asc`.
- `pinned` does not override series reading order.

#### Archive

- Archive uses publication chronology, not freshness.
- Archive grouping is derived from `date`.
- Entries with `date` participate in year/month archive grouping ordered by `published_at desc`.
- Entries without `date` do not appear in archive.

This keeps archive meaning consistent as a publication-history surface rather than a generic content dump.

### 7. `featured` and `pinned` semantics

M3 should keep `featured` and `pinned` distinct.

- `featured` is an editorial/homepage signal. It exists to help curated homepage composition.
- `pinned` is a cross-surface priority signal for card-based lists.

This separation avoids overloading a single field with two different meanings and keeps homepage curation from leaking into every other surface.

### 8. `toc`, `layout`, and author behavior

`toc` becomes an explicit page behavior contract.

- when unset, the build/theme pair uses the system default heuristic;
- `toc: true` forces a TOC to render when heading data exists;
- `toc: false` forces the TOC module to stay hidden.

`layout` stays intentionally constrained.

- M3 should validate `layout` against a small allowed set aligned with supported source-backed page types.
- A practical initial set is `article`, `page`, and `home`.
- Invalid layout values should be reported by `check`.
- Generated system surfaces such as `search`, `tags`, `series`, and `archive` keep system-owned layouts and are not author-selectable through ordinary page frontmatter.

Author behavior remains site-led.

- site-level author/profile metadata supplies the default author card and author presence fields;
- page-level `author` may override the displayed byline string;
- page-level `author` does not override the site-level avatar, bio, or profile links.

### 9. Validation and diagnostics

`moon check` should expose contract failures clearly.

M3 should add validation for:

- non-boolean scalar values for `draft`, `featured`, `pinned`, `search`, and `toc`;
- list-vs-scalar field-shape mismatches for behavior fields;
- invalid `layout` values;
- malformed site-level author/profile config shapes.

M3 should not turn missing optional metadata into noisy failures. For example, missing `updated` is valid, and missing `date` is valid for non-archive surfaces.

### 10. Files likely affected by implementation

Primary code areas:

- `src/core/frontmatter.mbt`
- `src/core/config.mbt`
- `src/core/model.mbt`
- `src/core/search_index.mbt`
- `src/runtime/config_loader.mbt`
- `src/cli/cmd_build.mbt`
- supporting generated-surface helpers under `src/cli/`
- built-in theme templates and assets under `src/runtime/builtin_theme/`

Primary docs likely affected:

- `docs/technical/03-Configuration-Design.md`
- `docs/technical/06-Markdown-and-Frontmatter.md`
- `docs/technical/08-Theme-System.md`
- `docs/technical/09-Search-Index.md`
- `docs/agent-working/MoonInkCliArch.md`

## Testing strategy for implementation

Implementation should verify at least:

- frontmatter parsing and validation for every new behavior field;
- build exclusion for `draft: true` across emitted pages and generated public artifacts;
- search-only exclusion behavior for `search: false`;
- stable ordering for homepage, tags, series, and archive;
- archive participation rules for dated vs undated content;
- shared card model coverage across homepage/search/collection surfaces;
- site-level author/profile parsing and page-level author override behavior;
- `toc` and `layout` contract enforcement in rendered output and `check` diagnostics.

## Acceptance criteria

This design should be considered successful when all of the following are true:

- a draft document is absent from the published build and every public aggregate surface;
- a non-draft document with `search: false` is still publishable but absent from search artifacts;
- homepage, tags, series, and archive each use stable documented ordering rules;
- search tie-breaking is deterministic once relevance ties occur;
- author card and author-presence data come from a typed site-level model rather than ad hoc theme-only fields;
- `toc`, `layout`, `featured`, and `pinned` behave as documented contracts rather than template-local conventions;
- the built-in theme can render the shared public surfaces without re-implementing the contract logic itself.
