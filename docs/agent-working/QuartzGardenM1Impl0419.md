# Quartz Garden M1 Implementation 0419

## Goal

Implement the first practical slice of the 2026-04-19 Quartz-style product-direction spec so MoonInk's default article pages feel like destination pages rather than plain rendered documents.

This milestone targets the spec's `M1` scope only:

- metadata and frontmatter upgrade;
- branded article page v1;
- backlinks v2 with contextual snippets;
- related notes v1.

Homepage curation, collection pages, RSS/social metadata, and the broader explore layer remain out of scope.

## Files Changed

Core and metadata:

- `src/core/frontmatter.mbt`
- `src/core/model.mbt`
- `src/core/search_index.mbt`
- `src/core/core_test.mbt`

DocFlow signals:

- `src/docflow/adapters.mbt`
- `src/docflow/markdown.mbt`
- `src/docflow/signals.mbt`
- `src/docflow/wikilinker.mbt`
- `src/docflow/docflow_test.mbt`

CLI build assembly:

- `src/cli/cmd_build.mbt`
- `src/cli/cli_test.mbt`

Built-in Theme V2:

- `src/runtime/builtin_theme/theme.json`
- `src/runtime/builtin_theme/assets/moonink-default.css`
- `src/runtime/builtin_theme/layouts/article.html`
- `src/runtime/builtin_theme/layouts/index.html`
- `src/runtime/builtin_theme/layouts/page.html`
- `src/runtime/builtin_theme/partials/header.html`
- `src/runtime/builtin_theme/partials/sidebar.html`

Fixtures and docs:

- `fixtures/v2/article_experience_basic/*`
- `docs/agent-working/MoonInkCliArch.md`
- `docs/agent-working/QuartzGardenM1Impl0419.md`
- `docs/agent-working/worklog/20260419.md`
- `docs/superpowers/specs/2026-04-19-quartz-knowledge-garden-product-direction-design.md`

## What Landed

### Frontmatter and page metadata upgrade

MoonInk now recognizes these additional article-facing frontmatter fields:

- `summary`
- `updated`
- `series`
- `cover`
- `author`
- `column`

The build pipeline now also derives `reading_time_minutes` from normalized source text. Search-index excerpt selection was updated to prefer `summary` when `excerpt` is absent, and markdown plain-text normalization now strips wikilink syntax as part of general body-text extraction.

### Markdown heading signals and anchor injection

DocFlow now extracts markdown heading outlines and injects stable `id` attributes into rendered heading HTML. That makes the new article TOC a real in-page navigation surface instead of a decorative summary list.

The heading ID strategy is deterministic and de-duplicates repeated headings by appending numeric suffixes.

### Backlinks v2

Backlinks are no longer a bare list of referring page titles. The build layer now scans resolved markdown wikilink mentions and preserves one contextual snippet per referring page.

Each backlink entry carries:

- referring page title and URL;
- contextual mention snippet from the source line;
- optional date;
- optional series name.

Sorting is currently stable by recency, then source path.

### Related notes v1

The build layer now generates related-note candidates for article pages using a lightweight heuristic over:

- direct outbound links;
- reverse links;
- shared tags;
- shared series membership.

Results are capped to a short list, sorted by score and then recency, and rendered through the built-in article layout as continuation cards.

### Branded article page v1

The built-in Theme V2 article layout now renders:

- hero block with optional cover image;
- title, summary, date, updated date, tags, and reading time;
- sticky TOC when headings exist;
- previous/next article navigation;
- series navigation when available;
- contextual backlinks block;
- related-reading block;
- author-presence card.

The visual system was also restyled around a warmer editorial look with a stronger reading lane, card surfaces, and more intentional navigation chrome.

## Design Decisions

### Keep M1 inside the existing build pipeline

The implementation deliberately extends the current `config -> discovery -> build -> theme` flow instead of adding a new Quartz-only path. That keeps the feature reversible and avoids fragmenting the product model.

### Build article-experience signals before templating

TOC data, backlinks, related notes, and series navigation are all computed as build-time data before theme rendering. Templates consume prepared models rather than improvising cross-page behavior themselves.

### Use lightweight heuristics first

Related-note ranking and backlink snippet extraction are intentionally simple in this slice. The goal is not semantic ranking perfection; it is to make the default article page immediately more useful and more navigable without introducing a much larger ranking subsystem.

### Preserve legacy template compatibility where cheap

The richer backlink HTML continues to flow through the legacy `TemplateContext` path, but the main product work is centered in Theme V2 because that is the active default presentation contract.

## Current Limitations

- related-note ranking is heuristic rather than semantic;
- backlink snippets are line-based mention excerpts, not paragraph-aware deep contexts;
- the author card currently uses a simple `author` string or site-name fallback rather than a richer author profile model;
- TOC extraction is markdown-only in this slice;
- homepage curation, topic/tag/series landing pages, archive/RSS/social metadata, and explore surfaces remain out of scope.

## Recommended Next Steps

1. Move from heuristic related-note scoring toward a stronger relationship model once there is a consumer need beyond the built-in theme.
2. Decide whether author data should stay a lightweight frontmatter field or graduate into a richer site/global model.
3. Implement the next Quartz-style milestone around homepage curation and formal collection pages.
4. If backlink depth becomes a product differentiator, add paragraph-aware context and deep return jumps as a later dedicated slice.

## Validation

Validation completed for this milestone:

- `moon check`
- `moon test src/core`
- `moon test src/docflow`
- `moon test src/cli`

Full final validation is still required before handoff:

- `moon test`
- `moon info`
- `moon fmt`
