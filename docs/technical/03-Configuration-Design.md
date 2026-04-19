# 03 Configuration Design

## 1. Format Choice

MoonInk uses JSON as its project configuration format (`moonink.json`).

## 2. Design Principles

- easy to read and edit manually;
- deterministic to parse using MoonBit's built-in `@json.parse()`;
- explicit over magical defaults;
- small schema focused on current product needs.

## 3. Configuration Schema

```json
{
  "site_name": "My Site",
  "site_url": "https://example.com",
  "content_dir": ".",
  "output_dir": "dist",
  "exclude": [".obsidian", "dist", ".git", "node_modules", ".trash", "templates", "Templates"],
  "route_style": "pretty",
  "text_encoding": "utf-8",
  "theme": "theme",
  "theme_config": {
    "homepage": {
      "hero_title": "Notes From The Workbench",
      "hero_summary": "Essays, field notes, and connected writing from the MoonInk lab.",
      "featured_paths": ["essays/stone-garden.md"],
      "recent_count": 2
    }
  },
  "author": {
    "name": "Site Author",
    "bio": "Writes careful notes.",
    "homepage_text": "Building intentional surfaces.",
    "avatar": "/avatar.png",
    "links": [
      { "label": "GitHub", "url": "https://example.com/github" }
    ]
  }
}
```

## 4. Field Reference

### Required

- `site_name` — display name for the site

### Optional (with defaults)

- `site_url` — canonical site URL (no default)
- `content_dir` — root directory to scan for content (default: `"."`)
- `output_dir` — build output directory (default: `"dist"`)
- `exclude` — directories to skip during recursive scan (default: `[".obsidian", "dist", ".git", "node_modules", ".trash", "templates", "Templates"]`)
- `route_style` — URL shape: `"pretty"` (trailing-slash directories) or `"direct"` (`.html` extension); default: `"pretty"`
- `text_encoding` — encoding declaration in emitted HTML (default: `"utf-8"`)
- `theme` — project-local theme directory name for Theme V2 bundles or legacy theme overrides (default: `"theme"`)
- `theme_config` — nested Theme V2 configuration data used for token overrides, declared slots, and homepage curation
- `author` — typed site-level author/profile metadata used by homepage presence, article author cards, and shared surface card labels
  - `name` — default displayed author name when a page does not override `author`
  - `bio` — shared profile copy for article pages and public author presence
  - `homepage_text` — homepage-facing intro copy when the built-in theme renders author presence
  - `avatar` — optional avatar or image reference
  - `links` — array of `{ label, url }` objects for public profile links

## 5. Route Style

- `pretty`: `guides/intro.md` → `/guides/intro/`; `index.md` → `/`
- `direct`: `guides/intro.md` → `/guides/intro.html`

## 6. Validation Rules

Validation catches:

- missing required fields (`site_name`);
- invalid or parent-traversal paths;
- malformed JSON;
- malformed `author` objects or `author.links` entries.

## 7. `theme_config.homepage`

MoonInk M2 adds a small typed homepage curation contract under `theme_config.homepage`.

- `hero_title` — optional homepage hero title override
- `hero_summary` — optional homepage hero summary override
- `featured_paths` — ordered array of source-relative content paths to pin into the featured module
- `recent_count` — positive integer cap for the generated "recent writing" module

`featured_paths` are validated during build against discovered source paths.
An unresolved entry is a blocking build error.

## 8. Obsidian Vault Compatibility

MoonInk now treats a typical Obsidian vault as a first-class content root:

- the default `exclude` list already skips `.obsidian`, `dist`, `.git`, `node_modules`, `.trash`, `templates`, and `Templates`;
- `content_dir: "."` means the vault root can be built directly;
- non-Markdown/non-HTML files discovered under the content tree are treated as passthrough assets and copied into the output tree;
- root `README.md` is promoted to the homepage when no root `index.*` file exists;
- note titles can be inferred from the first Markdown H1, so batch frontmatter migration is not required.
