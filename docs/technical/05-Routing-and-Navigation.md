# 05 Routing And Navigation

## 1. Routing Goals

- predictable URLs;
- stable canonical page identity;
- clean output structure;
- support for mixed content types.

## 2. Routing Strategy

MoonInk keeps both route styles, but homepage handling is now explicit:

- `pretty` routes emit directory-style URLs and write `index.html` under the corresponding folder;
- `direct` routes emit `.html` URLs for normal pages, but the root homepage still uses `/` as its canonical URL and writes `index.html`;
- root `index.*` wins as the homepage; otherwise root `README.md` is promoted to `/`.

## 3. Navigation Strategy

MoonInk V1 adopts a mixed strategy:

- generate navigation automatically from content structure by default;
- allow manual override or refinement from configuration;
- derive navigation from resolved page metadata (`url_path`, `output_path`, `resolved_title`, `is_index`) instead of re-deriving from raw source-path rules downstream.

## 4. Documentation Navigation

Documentation pages should appear as a hierarchical tree, based on folder structure unless configuration explicitly adjusts the tree.

## 5. Article Navigation

Articles now participate in automatic navigation unless `nav_hidden: true` is set. When a nested note has no matching section index page, MoonInk lifts it to the nearest visible root entry so vault folders such as `notes/project.md` still appear in the generated nav.

## 6. Conflict Rules

The routing system must detect:

- duplicate output paths;
- duplicate page identifiers;
- navigation entries that target non-existent pages;
- passthrough asset collisions with generated HTML or reserved build artifacts.
