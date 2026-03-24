# 06 Markdown And Frontmatter

## 1. Input Model

MoonInk V1 accepts Markdown files with optional frontmatter.

## 2. Frontmatter Role

Frontmatter supplies page metadata used in rendering, routing, navigation, and search.

## 3. Supported Metadata In V1

- `title`
- `id`
- `author`
- `tags`
- `date`

## 4. Parsing Responsibilities

The parser should separate:

- metadata extraction;
- body extraction;
- Markdown parsing;
- derived fields such as excerpt or reading metadata if later added.

## 5. Parser Constraints

V1 should prefer a small, deterministic Markdown feature set. Complex embedded components or executable blocks should be deferred.

## 6. Error Handling

Malformed frontmatter should produce actionable diagnostics with file path context.
