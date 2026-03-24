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

## 5. Future Evolution

This subsystem should later support backlinks and graph-oriented metadata without changing the core page identity model.
