# 09 Search Index

## 1. Goal

MoonInk V1 should provide built-in local search without relying on external services.

## 2. Strategy

Build time generates a static `search-index.json` file consumed by built-in client-side
JavaScript in the generated site.

## 3. Indexed Fields

Current indexed fields:

- title
- summary
- excerpt
- tags
- kind
- url
- date

## 4. Built-In Search Behavior

MoonInk M2 ships a generated `/search/` page plus a small vanilla-JS client.

The current ranking order is weighted toward:

1. title
2. summary
3. tags
4. excerpt

Documents with `search: false` are omitted from the generated index.

## 5. Constraints

- search output must remain lightweight;
- index generation should be deterministic;
- indexing should reuse parsed content rather than reparsing rendered HTML.

## 6. Future Enhancements

- section-level indexing;
- multilingual indexing;
- pluggable external search backends.
