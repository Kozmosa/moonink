# 09 Search Index

## 1. Goal

MoonInk V1 should provide built-in local search without relying on external services.

## 2. Strategy

Build time generates:

- `dist/search-index.json` as the canonical machine-consumable search artifact;
- a built-in `/search/` page plus built-in client-side JavaScript that consume the same search contract.

## 3. Indexed Fields

The emitted index currently includes:

- title
- summary
- excerpt
- tags
- kind
- url
- date
- source path
- published date
- freshness date (`updated ?? date`)
- series
- cover
- author label
- `featured`
- `pinned`

Eligibility rules:

- draft pages are excluded entirely;
- `search: false` excludes only the search artifact and search results.

## 4. Built-In Search Behavior

MoonInk M2 ships a generated `/search/` page plus a small vanilla-JS client.

The current ranking order is weighted toward:

1. title
2. summary
3. tags
4. excerpt

When search relevance ties occur, fallback ordering is:

1. `pinned desc`
2. `freshness_at desc`
3. `source_path asc`

## 5. Constraints

- search output must remain lightweight;
- index generation should be deterministic;
- indexing should reuse parsed content rather than reparsing rendered HTML.

## 6. Future Enhancements

- section-level indexing;
- multilingual indexing;
- pluggable external search backends.
