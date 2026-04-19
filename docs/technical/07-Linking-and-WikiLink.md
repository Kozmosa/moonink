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

MoonInk now resolves supported WikiLinks during build and exposes relationship
data in both legacy HTML helpers and Theme V2 structured collections.

- backlinks remain a build-time derived feature based on resolved note-to-note links;
- built-in article output now groups local discovery as:
  - `Mentioned here` from outbound resolved WikiLinks in the current article;
  - `Referenced by` from backlink entries with snippets;
  - `Keep reading` from the related-note heuristic;
- resource-style WikiLinks rewrite to ordinary Markdown links;
- image embeds rewrite to Markdown image syntax so the final renderer emits `<img>` output;
- non-image embeds degrade to ordinary links that preserve the resolved asset URL.

## 6. Future Evolution

This subsystem can still expand toward richer graph-oriented metadata without changing the core page identity model.
