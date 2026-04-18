# 07 Linking And WikiLink

## 1. Motivation

Knowledge-oriented publishing needs stronger internal linking than plain Markdown path references alone.

## 2. Supported Link Forms

- relative Markdown links;
- anchor links;
- `[[WikiLink]]` note syntax;
- resource-style WikiLinks such as `[[Attachments/diagram.png]]`;
- Obsidian-style embeds such as `![[diagram.png]]`.

## 3. Validation Goals

MoonInk V1 should validate:

- missing internal targets;
- invalid relative paths;
- unresolved WikiLinks;
- invalid anchor references when possible.

## 4. WikiLink Resolution Strategy

MoonInk resolves note links from the discovered page inventory using exact source paths, extensionless paths, basenames, and index aliases. If note resolution fails, the linker falls back to discovered static assets from the content tree.

- ambiguous note targets warn with the candidate page URLs;
- ambiguous resource targets warn with the candidate asset URLs;
- unresolved note and resource targets remain in source form and emit diagnostics;
- backlinks are still computed only from resolved note-to-note links.

## 5. Current Output Support

MoonInk now resolves supported WikiLinks during build and exposes backlinks in template context as `backlinks_html`.

- built-in/default theme output renders a backlinks block only when backlinks exist;
- the backlinks block lists pages or articles that linked to the current page;
- the minimal fixture renders a backlink on the generated hello page pointing back to Home.
- resource-style WikiLinks rewrite to ordinary Markdown links;
- image embeds rewrite to Markdown image syntax so the final renderer emits `<img>` output;
- non-image embeds degrade to ordinary links that preserve the resolved asset URL.

## 6. Future Evolution

This subsystem can still expand toward richer graph-oriented metadata without changing the core page identity model.
