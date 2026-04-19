# M2 Search And Public Shell Implementation

## Goal And Scope

Deliver the M2 milestone by turning MoonInk's existing article/search/theme
infrastructure into reader-visible public surfaces:

- productized built-in search with `/search/` and weighted client-side ranking;
- curated homepage modules from `theme_config.homepage`;
- generated `/tags/`, `/series/`, and `/archive/` pages;
- canonical, Open Graph, RSS, and feed outputs for the default public shell.

Out of scope for this slice:

- topic pages;
- column-root collections;
- watch mode / live reload;
- frontmatter-deep publication controls beyond `search: false`.

## Files Changed

Primary implementation areas:

- `src/core/frontmatter.mbt`
- `src/core/model.mbt`
- `src/core/search_index.mbt`
- `src/cli/site_surfaces.mbt`
- `src/cli/cmd_build.mbt`
- `src/runtime/builtin_theme/theme.json`
- `src/runtime/builtin_theme/layouts/index.html`
- `src/runtime/builtin_theme/layouts/search.html`
- `src/runtime/builtin_theme/layouts/collection.html`
- `src/runtime/builtin_theme/layouts/archive.html`
- `src/runtime/builtin_theme/assets/moonink-default.css`
- `src/runtime/builtin_theme/assets/moonink-search.js`
- `fixtures/v2/m2_public_shell_basic/*`

Validation coverage was added in:

- `src/core/core_test.mbt`
- `src/runtime/runtime_test.mbt`
- `src/cli/cli_test.mbt`

## Design Decisions

### Generated Surfaces Stay In The Build Layer

Search, tags, series, archive, homepage modules, and RSS are all derived from
build-time site models instead of being computed ad hoc in templates or client
JavaScript. This keeps the theme contract small and keeps custom themes from
having to reimplement site-wide derivation logic.

### Reserved Surface Roots Are Explicit

`search/`, `tags/`, `series/`, and `archive/` are treated as reserved generated
roots. Source content under those roots now fails the build instead of silently
competing with generated output.

### Search Is Static-First

The emitted `search-index.json` remains the only search artifact. The built-in
search page loads it with a small vanilla-JS client and applies weighted token
matching across:

1. title
2. summary
3. tags
4. excerpt

`search: false` removes a document from the search index without changing the
rest of the site build contract.

### Homepage Curation Uses A Small Typed Config

Homepage curation is intentionally limited to:

- `hero_title`
- `hero_summary`
- `featured_paths`
- `recent_count`

This gives MoonInk a real authored homepage without prematurely committing to a
full homepage module DSL.

### Theme V2 Generated-Surface Fallback Is Conservative

The built-in default bundle now ships `search`, `collection`, and `archive`
layouts. Custom Theme V2 bundles are allowed to omit those keys; generated
surfaces fall back to the bundle's `page` layout instead of hard-failing.

## Current Limitations

- Topics and column-root collection pages are still not generated.
- `search: false` only affects search indexing, not general publication
  visibility.
- Archive pages are still simple chronological lists rather than richer year /
  month groupings.
- RSS is intentionally lightweight and does not yet emit richer item metadata
  such as enclosure data or formatted publication dates.

## Next Steps

- M3: promote more site behavior into stable frontmatter contracts such as
  draft exclusion, ordering, and richer author/profile metadata.
- M4: add watch mode, live reload, and stronger preview-time developer
  ergonomics.
- Later explore slices: topic pages, stronger collection rules, and richer
  browse/explore surfaces.
