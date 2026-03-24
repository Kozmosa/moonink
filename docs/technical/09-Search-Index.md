# 09 Search Index

## 1. Goal

MoonInk V1 should provide built-in local search without relying on external services.

## 2. Strategy

Build time generates a static search index file consumed by client-side JavaScript in the generated site.

## 3. Indexed Fields

Recommended indexed fields:

- title
- tags
- page type
- body text excerpt or normalized content
- route

## 4. Constraints

- search output must remain lightweight;
- index generation should be deterministic;
- indexing should reuse parsed content rather than reparsing rendered HTML.

## 5. Future Enhancements

- weighted ranking;
- section-level indexing;
- multilingual indexing;
- pluggable external search backends.
