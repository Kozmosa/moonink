# 07 Linking And WikiLink

## 1. Motivation

Knowledge-oriented publishing needs stronger internal linking than plain Markdown path references alone.

## 2. Supported Link Forms

- relative Markdown links;
- anchor links;
- `[[WikiLink]]` syntax.

## 3. Validation Goals

MoonInk V1 should validate:

- missing internal targets;
- invalid relative paths;
- unresolved WikiLinks;
- invalid anchor references when possible.

## 4. WikiLink Resolution Strategy

WikiLinks should resolve through page identity rules in this priority order:

1. exact `id`
2. exact title match
3. canonical slug match

If resolution remains ambiguous, the build should report a clear diagnostic.

## 5. Current Output Support

MoonInk now resolves supported WikiLinks during build and exposes backlinks in template context as `backlinks_html`.

- built-in/default theme output renders a backlinks block only when backlinks exist;
- the backlinks block lists pages or articles that linked to the current page;
- the minimal fixture renders a backlink on the generated hello page pointing back to Home.

## 6. Future Evolution

This subsystem can still expand toward richer graph-oriented metadata without changing the core page identity model.
