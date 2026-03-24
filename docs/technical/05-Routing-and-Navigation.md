# 05 Routing And Navigation

## 1. Routing Goals

- predictable URLs;
- stable canonical page identity;
- clean output structure;
- support for mixed content types.

## 2. Routing Strategy

MoonInk V1 should prefer directory-style output URLs for content pages. This produces human-readable paths and aligns with documentation-style browsing.

## 3. Navigation Strategy

MoonInk V1 adopts a mixed strategy:

- generate navigation automatically from content structure by default;
- allow manual override or refinement from configuration.

## 4. Documentation Navigation

Documentation pages should appear as a hierarchical tree, based on folder structure unless configuration explicitly adjusts the tree.

## 5. Article Navigation

Articles should not be forced into the documentation side tree. Instead, they should appear in article listings, tag listings, or home-page sections.

## 6. Conflict Rules

The routing system must detect:

- duplicate output paths;
- duplicate page identifiers;
- navigation entries that target non-existent pages.
