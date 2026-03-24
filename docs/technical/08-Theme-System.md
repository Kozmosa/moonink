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

## 5. Public API Position

The V1 theme system should be implemented as replaceable internally, but not yet declared stable as a public extension API.
