# MoonInk Quartz-Style Knowledge Garden Product Direction Design

_Date_: 2026-04-19

## Context

MoonInk already has a credible foundation as a Markdown-first static site generator oriented toward existing folders and Obsidian-style vaults. The current codebase supports a layered pipeline, a built-in theme system, wiki-style linking, backlinks, and a generated search index. That makes it viable as a functional publishing engine, but not yet fully competitive as a product against Quartz for public knowledge-garden publishing.

The user’s target is not a generic documentation site in the MkDocs sense. The desired product direction is a Quartz-style public knowledge garden and blog hybrid, with a strong author presence, a high-quality article-reading experience, and clearly visible bidirectional-link browsing.

This matters because product competitiveness here is driven less by feature count than by whether the default generated site already feels like a finished public-facing writing product. MoonInk should not merely render Markdown correctly; it should help authors publish a site that feels curated, connected, and worth exploring.

## Goal

Define the next-stage product direction for MoonInk so it becomes a stronger Quartz-style public knowledge garden and blog hybrid, while staying aligned with the current architecture and a balanced static-first implementation style.

For this direction, MoonInk should:

- prioritize a branded, polished article-reading experience over a plain document output feel;
- make backlinks and bidirectional-link browsing highly visible and useful in the default article experience;
- support homepage and collection-page curation so the generated site feels like an authored publication, not a raw file listing;
- strengthen content relationships through tags, topics, series, and related-reading paths;
- reserve heavier interaction layers for places where they materially improve discovery rather than turning the site into a front-end-heavy application.

## Non-goals

This design intentionally does **not** include:

- full Quartz parity in one milestone;
- a broad pivot toward MkDocs-style team documentation priorities;
- immediate introduction of a large plugin ecosystem or public extension API;
- a fully dynamic client-side application architecture;
- a complete all-at-once redesign of the existing build pipeline;
- graph visualizations as a first implementation priority before the underlying relationship model is strong enough.

## Product positioning

MoonInk should position its default output as:

`author-branded site shell + longform-first article page + visible knowledge network`

This differs from a pure blog in that relationships between notes and essays are central to the reading journey. It differs from a pure knowledge-garden product in that the default visual language should still support polished public writing and author expression rather than feeling like a utility note dump.

The product should therefore optimize for three outcomes:

- a strong first impression when landing on the homepage;
- a high-retention reading experience on individual article pages;
- a natural next-click path through backlinks, related notes, topics, and series.

## Recommended approach

The recommended strategy is `brand-first article experience + visible knowledge network`, with article experience as the primary axis and knowledge-network features as the reinforcing layer.

This is the recommended approach because it best matches the target scenario: a public knowledge garden and blog hybrid where site quality and reading depth matter immediately, but bidirectional linking remains a core differentiator. If MoonInk optimized only for branded presentation, it would risk becoming a prettier generic blog generator. If it optimized only for graph-style exploration first, it would risk shipping a technically interesting but visually underpowered site.

A platform-first approach was considered, where the product would first emphasize metadata infrastructure, feeds, SEO, and theme APIs before reader-visible upgrades. That was rejected as the primary route because it would improve internal completeness more than perceived product quality. A knowledge-network-first approach was also considered, but deferred as the main axis because strong backlinks and relationship browsing land better when the site already feels like a finished publication.

## Design

### 1. Information architecture should center the homepage, article page, and exploration loop

MoonInk’s default site structure should be organized around five page classes:

- `homepage`
- `article page`
- `collection pages` for tags, topics, and series
- `explore page`
- `author/about/now pages`

The homepage should not be a simple chronological list. It should combine author positioning, featured writing, section entry points, recent updates, and explicit exploration entry points.

The article page should be the strongest page in the system. It should carry enough visual and structural richness that any single shared link already feels like a destination page, not just a rendered Markdown artifact.

Collection pages should exist as real discovery surfaces rather than passive tag dumps. They should help readers move through topics, recurring themes, or long-running series.

The explore page should aggregate knowledge-garden style browsing entry points such as recent updates, random reading, tags, and topic-oriented exploration.

Author-centric pages such as About or Now should reinforce that the site belongs to a specific writer or publishing voice.

### 2. The article page should become the primary product surface

The article page should carry the largest share of product differentiation.

Its default experience should include:

- cover or article hero treatment where available;
- title, summary, date, updated date, tags, and reading time;
- stronger reading rhythm through spacing, typography, and section structure;
- table of contents where content depth justifies it;
- previous/next navigation when meaningful;
- series or topic navigation when available;
- author card or author-presence block;
- backlinks and related reading as end-of-article continuation modules.

The core principle is that article pages should feel authored and consumable, not merely transformed from source Markdown.

### 3. Backlinks must become a first-class visible feature

Backlinks are a core product feature and should no longer behave like a minor appendix.

The default article page should include a dedicated backlinks block near the end of the page. That block should show more than page titles. Each entry should include:

- the referring page title;
- a contextual excerpt or mention snippet where possible;
- lightweight metadata such as date, series, or topic when available;
- a stable ordering strategy, preferably by relevance, recency, or editorial usefulness.

The product goal is not simply to prove that bidirectional links exist. The goal is to make them readable and actionable enough that they create the next navigation step for the reader.

### 4. Content relationships should be visible through multiple navigational surfaces

MoonInk should treat content relationships as more than raw links between files.

The system should support and expose:

- `tags` as thematic metadata;
- `topics` as stronger curated grouping surfaces;
- `series` as ordered reading sequences;
- `related notes` as build-time inferred continuation links;
- optional trails or local relationship navigation as the product matures.

This creates multiple discovery paths: direct reading, thematic browsing, sequential reading, and associative exploration.

For the first implementation slice, `tags` and `topics` should not be treated as interchangeable. `tags` should remain lightweight author-facing metadata, while `topics` should be explicit curated landing-page groupings defined by stable metadata or site configuration rather than inferred automatically.

### 5. The homepage should become a curation surface, not just an index

The default homepage should support a curated, author-branded composition. It should be capable of including:

- hero statement or author manifesto;
- featured writing section;
- section or column entry points;
- recent writing or recent changes;
- exploration entry points into tags, topics, or random reading;
- author/about/subscribe-style links where appropriate.

This should be supported by a stable page model rather than theme-only hardcoded logic so the product can evolve without entangling presentation and build logic.

### 6. Interaction should stay balanced and purposeful

MoonInk should remain primarily static-first. Small interaction layers are justified where they materially improve browsing.

This includes medium-priority enhancements such as:

- hover preview for links on desktop;
- local relationship visualizations;
- richer explore-page browsing affordances.

These should arrive only after the underlying relationship data is accurate and the static reading experience is already strong. The site should remain useful even with little or no client-side JavaScript.

## Feature roadmap

### Current baseline: M1 is complete

MoonInk has already completed the first practical Quartz-style slice:

- metadata and frontmatter upgrade for article pages;
- branded article page v1;
- backlinks v2;
- related notes v1.

This means the next roadmap no longer starts from article-surface viability. It starts from the need to turn the current engine into a more complete public-facing product.

### M2 roadmap: Search productization and public site shell v1

The next milestone should turn existing infrastructure into reader-visible product surfaces.

Primary deliverables:

- built-in `/search/` page;
- default-theme search UI that consumes `search-index.json`;
- title / summary / tag-aware weighted matching;
- per-document search inclusion control such as `search: false` or an equivalent stable frontmatter contract;
- homepage curation v1;
- formal tag, topic, series, and archive collection pages;
- RSS, Open Graph, canonical, and related public metadata support.

This milestone should make MoonInk feel like a coherent authored publication rather than a set of strong individual article pages.

### M3 roadmap: Frontmatter-driven site behavior and collection-page contract

Once search and the public shell exist, the next milestone should strengthen the content model so more of the site behavior is intentionally driven by metadata instead of implicit defaults.

Primary deliverables:

- `draft` exclusion from standard output;
- deterministic ordering rules based on `date` and `updated`;
- `featured`, `pinned`, `search_exclude`, `toc`, and `layout` style fields where they materially affect site behavior;
- richer `author`, `profile`, and site-level metadata models;
- unified card density and ordering rules across homepage, search results, and collection pages;
- a stable contract for how collection pages are grouped, sorted, and rendered.

This milestone should make MoonInk's build output feel deliberate and configurable rather than merely well-rendered.

### M4 roadmap: Developer experience and exploration differentiation

After the public product shell and metadata model are stable, the next milestone should improve author workflow and add stronger discovery features.

Primary deliverables:

- `serve` watch mode;
- live reload or equivalent preview refresh behavior;
- incremental or partial rebuild strategy where feasible;
- better preview-time error reporting and failure visibility;
- stronger explore/discovery surfaces;
- local relationship navigation and other higher-value exploration affordances.

This milestone should make MoonInk feel stronger both as an authoring tool during development and as a knowledge-garden product during browsing.

### Flagship follow-on priorities

These remain strong differentiators once M2 through M4 are in place:

- local relationship graph or topic graph;
- paragraph-aware backlink context and deep return jumps;
- composable homepage module system;
- wander / random / trail exploration mode.

## Scope for the next implementation plan

This design is intentionally broader than a single coding milestone.

`M1` is now complete and should be treated as the current product baseline. The next implementation plan should therefore target `M2` first:

- built-in search page and theme-side search consumption;
- weighted search behavior and search inclusion/exclusion controls;
- homepage curation v1;
- tag/topic/series/archive collection pages;
- RSS, Open Graph, canonical, and related public metadata support.

Frontmatter-deepening work beyond what is needed for `M2`, along with `serve` watch/reload behavior and heavier exploration features, should remain out of scope for that next implementation plan unless a later user decision explicitly broadens it.

## Architecture mapping

These capabilities should be introduced as data-model and build-pipeline improvements first, then consumed by themes.

### Core

`src/core/` should own the stable content and site-view contracts.

This layer should expand the frontmatter and content model to include the metadata needed for article presentation and relationship-aware navigation. It should also define richer site-view structures such as:

- `BacklinkEntry`
- `RelatedEntry`
- `SeriesNav`
- `TopicPageModel`
- `HomepageSectionModel`
- `AuthorCardModel`

The responsibility here is to define what the system can express, independent of how a theme renders it.

### Docflow

`src/docflow/` should produce richer per-document signals during parsing and linking.

That includes:

- outbound links;
- heading structure;
- excerpt candidates;
- paragraph or section-level snippets when feasible;
- reading-time signals;
- resource and relationship hints useful for backlinks and related-content generation.

The responsibility here is to extract structured signals from individual documents.

### Runtime and build pipeline

`src/runtime/` and the build path should aggregate site-wide relationships into build artifacts and page models.

This is where MoonInk should compute:

- backlinks;
- related notes;
- tag, topic, and series pages;
- homepage section content;
- archive views;
- exploration views.

These should not be left as ad hoc theme-time calculations. Relationship features should be generated deliberately as build-time site data.

### Theme layer

The theme should consume prepared site models rather than inventing product behavior in templates.

The default theme should expose article hero, metadata, table of contents, backlinks, related notes, author card, and homepage modules as composable rendering units. This keeps future product evolution possible without scattering logic across templates.

### Lightweight interaction layer

Any client-side enhancement should remain narrowly scoped and optional in effect. Hover previews, local relationship views, and similar features should enhance exploration rather than become prerequisites for using the site.

## Milestones

### M1: Articles become destination pages

Status: complete.

Delivered:

- metadata upgrade;
- branded article page v1;
- backlinks v2;
- related notes v1.

Success means that a shared article link already feels like a polished product surface and that the page clearly offers a next-step reading path.

### M2: Search becomes productized and the site gains a public shell

Deliver:

- built-in `/search/` page and default-theme search UI;
- title / summary / tag-aware weighted search behavior;
- search inclusion and exclusion controls in frontmatter;
- homepage curation v1;
- tag/topic/series/archive collection pages;
- RSS, Open Graph, canonical, and related public metadata support.

Success means the site no longer feels like a collection of isolated article pages. It should feel like a coherent authored publication with a visible discovery path.

### M3: Frontmatter drives site behavior and collection-page rules

Deliver:

- `draft` exclusion from standard builds;
- stable ordering and freshness rules based on `date` and `updated`;
- `featured`, `pinned`, `search_exclude`, `toc`, and `layout` style contracts where justified;
- richer author/profile/site metadata;
- unified card, ranking, and collection-page presentation rules.

Success means the build output is no longer shaped mainly by theme conventions and implicit defaults. It is shaped by an intentional metadata model that authors can rely on.

### M4: Developer experience and exploration both improve materially

Deliver:

- `serve` watch mode;
- live reload or equivalent preview refresh;
- incremental rebuild improvements where feasible;
- stronger preview-time error visibility;
- explore and relationship-navigation improvements that deepen discovery.

Success means MoonInk becomes stronger both while authors are iterating locally and while readers are browsing the generated site.

## Acceptance criteria

This design should be considered successful when the default MoonInk experience meets all of the following:

- the homepage clearly reads as an author-branded public site rather than a plain document list;
- an individual article page feels complete and high-quality without additional custom work;
- backlinks are strongly visible and useful enough to drive further reading;
- content relationships are discoverable through tags, topics, series, and related-reading surfaces;
- the built-in theme can produce a publishable public knowledge garden and blog hybrid with minimal extra author customization.

## Prioritized feature list

### Must-have

- built-in `/search/` page
- default-theme search UI
- weighted title / summary / tag matching
- homepage curation v1
- tag/topic/series/archive collection pages
- RSS, Open Graph, canonical, and related public metadata support

### Should-have

- `draft` exclusion from normal builds
- stable `date` / `updated` ordering rules
- `featured`, `pinned`, `search_exclude`, `toc`, and `layout` style fields where justified
- richer `author` / `profile` / site metadata
- unified card density and ranking rules across search and collection pages
- `serve` watch mode and live reload

### Flagship

- incremental rebuild and stronger preview failure surfaces
- explore page and local relationship navigation
- local relationship graph or topic graph
- paragraph-aware backlink context and return jumps
- composable homepage module system
- wander-style exploration mode

## Trade-offs

### Why not pursue full Quartz parity immediately?

Because product quality comes from a clear core experience, not from copying every visible feature at once. MoonInk will become more competitive by making the article page, homepage, and backlink experience excellent before expanding into heavier exploration features.

### Why prioritize article experience over graph features?

Because article pages are the primary landing surface for public writing. If the page itself feels weak, stronger graph or relationship tooling will not fix the first impression.

### Why keep interaction light at first?

Because the current architecture already supports strong static-site strengths. A balanced static-first approach reduces implementation risk and keeps the generated site resilient while still leaving room for selective high-value interactions later.

## Files likely affected by future implementation

Primary code areas:

- `src/core/`
- `src/docflow/`
- `src/runtime/`
- `src/cli/`
- `src/runtime/builtin_theme/`

Primary maintained docs likely affected:

- `docs/technical/00-Architecture.md`
- `docs/technical/07-Linking-and-WikiLink.md`
- `docs/technical/08-Theme-System.md`
- `docs/technical/09-Search-Index.md`
- `docs/agent-working/MoonInkCliArch.md`

## Testing strategy for future implementation

Implementation should verify at least:

- metadata parsing and fallback behavior for new article fields;
- site-wide relationship computation for backlinks, related notes, topics, and series;
- build outputs for curated homepage and collection pages;
- built-in theme rendering coverage for article-page modules and relationship modules;
- focused CLI/runtime integration coverage for end-to-end output behavior;
- search artifact consumption and ranking behavior for the built-in search experience;
- frontmatter-driven visibility, ordering, and layout contracts;
- `serve` watch / reload behavior and preview-time failure reporting when those features land.
