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
  "exclude": [".obsidian", "templates", "dist", "node_modules"],
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
- `exclude` — directories to skip during recursive scan (default: `[".obsidian", ".git", "node_modules", "dist"]`)
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

When MoonInk runs inside an Obsidian vault, add `.obsidian` to `exclude`. The `content_dir: "."` default means MoonInk scans the current directory, which is the vault root. Frontmatter fields in Obsidian notes are compatible with MoonInk's frontmatter schema.
