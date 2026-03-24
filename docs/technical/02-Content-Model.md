# 02 Content Model

## 1. Overview

MoonInk V1 uses a dual-track content model to support both stable knowledge hierarchies and time-oriented writing.

## 2. Content Types

### Document Page

A document page belongs to the hierarchical knowledge tree. It is usually part of a conceptual structure and appears in side navigation.

### Article Page

An article page belongs to a stream-like collection, usually ordered by date or grouped by tags.

## 3. Common Metadata Fields

- `title`: required display title
- `id`: stable content identifier, recommended
- `date`: recommended for article ordering and freshness metadata
- `author`: optional attribution field
- `tags`: optional classification field

## 4. Future Reserved Fields

MoonInk V1 may reserve, but not fully depend on:

- `summary`
- `draft`
- `order`
- `aliases`

## 5. Identity Rules

Page identity should not rely only on file path. When available, `id` should be used for stable referencing, especially for WikiLink resolution and future multilingual evolution.

## 6. Collection Semantics

- documentation pages are organized by hierarchy;
- article pages are organized by chronology and tags;
- both content types share rendering, metadata, and search infrastructure where possible.
