# 01 Product Scope

## 1. Positioning

MoonInk is a MoonBit-based static site generator with the first release focused on knowledge-oriented publishing for personal authors.

## 2. Version 1 Scope

### Included

- Markdown content
- TOML configuration
- dual-track site structure
- frontmatter metadata
- automatic plus manual navigation control
- internal link validation
- WikiLink support
- one official theme
- local static search index
- `new`, `build`, `serve` commands

### Excluded

- third-party plugins
- full multilingual support
- multiple themes
- deployment automation
- incremental build
- visual knowledge graph

## 3. Product Boundary Principle

If a capability does not directly improve content organization, predictable build behavior, or basic publishing usability, it should not enter V1.

## 4. User Value

The first release should let a user:

- organize stable notes as a documentation tree;
- publish article-like content in parallel;
- use internal links confidently;
- search published content locally;
- run the tool with a small mental model.
