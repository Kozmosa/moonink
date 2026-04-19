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

1. project-local `theme/layout.html`
2. configured `template_file`
3. repository-owned built-in default theme

When the selected theme exposes an assets directory, build copies those assets into `dist/assets/`.

## 6. Current V1 Scope

The currently shipped built-in theme slice covers:

- one repository-owned built-in Theme V2 bundle plus legacy fallback layout;
- basic typography and asset styles;
- page/article-aware content shells in the repository-owned default theme;
- article-local relationship navigation through structured `collections.relationships`;
- reuse of `navigation_html`, `current_section_*`, `page_header_html`, and preview-time `slots.scripts` injection.

It does **not** yet provide a stable manifest format, partial/include system, multi-theme support, or a public theme plugin API.

## 7. Public API Position

The V1 theme system should be implemented as replaceable internally, but not yet declared stable as a public extension API.
