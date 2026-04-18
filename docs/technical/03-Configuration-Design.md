# 03 Configuration Design

## 1. Format Choice

MoonInk uses JSON as its project configuration format (`moonink.json`).

## 2. Design Principles

- easy to read and edit manually;
- deterministic to parse using MoonBit's built-in `@json.parse()`;
- explicit over magical defaults;
- small schema focused on V1 needs.

## 3. Configuration Schema

```json
{
  "site_name": "My Site",
  "site_url": "https://example.com",
  "content_dir": ".",
  "output_dir": "dist",
  "exclude": [".obsidian", "dist", ".git", "node_modules", ".trash", "templates", "Templates"],
  "route_style": "pretty",
  "text_encoding": "utf-8"
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

## 5. Route Style

- `pretty`: `guides/intro.md` → `/guides/intro/`; `index.md` → `/`
- `direct`: `guides/intro.md` → `/guides/intro.html`

## 6. Validation Rules

Validation catches:

- missing required fields (`site_name`);
- invalid or parent-traversal paths;
- malformed JSON.

## 7. Obsidian Vault Compatibility

MoonInk now treats a typical Obsidian vault as a first-class content root:

- the default `exclude` list already skips `.obsidian`, `dist`, `.git`, `node_modules`, `.trash`, `templates`, and `Templates`;
- `content_dir: "."` means the vault root can be built directly;
- non-Markdown/non-HTML files discovered under the content tree are treated as passthrough assets and copied into the output tree;
- root `README.md` is promoted to the homepage when no root `index.*` file exists;
- note titles can be inferred from the first Markdown H1, so batch frontmatter migration is not required.
