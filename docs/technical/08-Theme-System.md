# 08 Theme System

## 1. V1 Theme Position

MoonInk V1 ships with one official built-in theme.

## 2. Design Goals

- complete enough for real use;
- visually aligned with MoonInk brand language;
- internally modular enough for future theming expansion.

## 3. Theme Responsibilities

The official theme should provide:

- home page and landing layout;
- documentation page template;
- article page template;
- navigation components;
- search UI;
- typography and asset styles.

## 4. Brand Alignment

The theme should follow the palette and tone defined in `docs/Brand_Design.md`, especially restraint, negative space, paper-like warmth, and quiet precision.

## 5. Layout Resolution Order

Current build-time precedence is:

1. project-local Theme V2 bundle at `<theme>/theme.json`
2. project-local legacy `<theme>/layout.html` when no Theme V2 bundle exists
3. configured legacy `template_file` when no project theme override exists
4. repository-owned built-in Theme V2 bundle

When the selected theme exposes an assets directory, build copies those assets into `dist/assets/`.

## 6. Current V1 Scope

The currently shipped built-in theme slice covers:

- Theme V2 manifest-driven layout selection;
- basic typography and asset styles;
- page/article-aware content shells in the repository-owned default theme;
- dedicated generated-surface layouts for `search`, `collection`, and `archive`;
- reuse of existing `navigation_html`, `current_section_*`, and `page_header_html` template context fields.

The Theme V2 layout map currently recognizes:

- `index`
- `page`
- `article`
- `search`
- `collection`
- `archive`

Compatibility rule:

- if a custom Theme V2 bundle omits `search`, `collection`, or `archive`, MoonInk falls back to the bundle's `page` layout for those generated surfaces.

It does **not** yet provide multi-theme layering, inheritance, or a stable public theme plugin API.

## 7. Public API Position

The V1 theme system should be implemented as replaceable internally, but not yet declared stable as a public extension API.
