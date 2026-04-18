# MoonInk Obsidian Direct Output Design

_Date_: 2026-04-18

## Context

MoonInk already positions itself as a static site generator that runs inside an existing Markdown folder, ideally an Obsidian vault. The current `build` pipeline can discover Markdown and HTML content, rewrite supported WikiLinks, render pages through templates/themes, and copy project-root `public/` assets into the output directory. Theme System V2 has now made the rendering side more capable, but the content-ingestion side is still tuned more like a general Markdown tree than a realistic Obsidian vault.

That gap matters because the product promise is already very close to “point MoonInk at your vault and publish it.” In practice, typical vaults contain `.obsidian/`, template folders, attachments, and notes with little or no frontmatter. A user should not need to reorganize the vault or batch-edit notes before the first successful build.

Quartz is useful as a reference point for product assumptions, not as an implementation template. Quartz also assumes Obsidian-authored content as the input source, but MoonInk should keep its own simpler configuration and pipeline model rather than introducing a separate import subsystem for this first compatibility pass.

## Goal

Enable a typical Obsidian vault to build directly into a usable static site with little or no configuration change and without requiring users to add frontmatter to existing notes.

For this first slice, MoonInk should:

- treat the vault root as the default content root;
- ignore obvious Obsidian and local-tooling helper directories by default;
- keep Markdown notes buildable even when they have no frontmatter;
- preserve and publish vault asset files without forcing users to move them into `public/`;
- distinguish note WikiLinks from resource WikiLinks well enough to support common attachment references;
- provide predictable home-page behavior even in loosely structured vaults.

## Non-goals

This design intentionally does **not** include:

- a Quartz-style import wizard or migration flow;
- a new `import` command;
- full semantic compatibility with Obsidian plugins such as Dataview, Canvas, or Excalidraw;
- full media embed semantics for arbitrary file types;
- folder-note magic beyond explicit `index.md` and root-level `README.md` rules;
- a new exposed config mode like `vault_mode: "obsidian"`;
- broad reinterpretation of MoonInk’s content model or routing model.

## Recommended approach

Extend the existing MoonInk pipeline with Obsidian-aware defaults rather than adding a separate Obsidian-specific execution path.

This is the recommended approach because the product already assumes “run inside an existing Markdown folder or vault.” The missing piece is not a second pipeline; it is making the current discovery, copying, and link-resolution behavior robust against realistic vault structure. Reusing the current `config -> discovery -> docflow -> render` flow keeps the feature small, understandable, and aligned with the codebase.

A dedicated compatibility mode in config was considered, but deferred. It would make behavior easier to isolate, yet it would also add user-facing configuration surface before we know whether the default behavior can simply become good enough for most vaults.

A separate import command was also considered, but rejected for this milestone. That would move the feature toward migration tooling and a larger product flow, while the current need is more basic: direct build compatibility.

## Design

### 1. Keep the current pipeline, but make defaults vault-aware

`moonink build`, `moonink check`, and `moonink serve` should continue to run through the existing pipeline. There should be no second “Obsidian build” mode.

The compatibility improvements should land in the existing layers:

- `src/core/config.mbt`
- `src/runtime/content_discovery.mbt`
- build-time asset-copy logic in the build/runtime path
- WikiLink/embed resolution in `src/docflow/`
- CLI defaults in `src/cli/cmd_onboard.mbt`

This keeps the feature as a strengthening of the default MoonInk contract rather than a sidecar subsystem.

### 2. Expand default helper-directory exclusions for realistic vault roots

The default `exclude` baseline should be expanded so a typical vault root can be scanned safely without pulling in obvious non-content directories.

Recommended default exclude set:

- `.obsidian`
- `.git`
- `dist`
- `node_modules`
- `.trash`
- `templates`
- `Templates`

This should affect default config generation and default config parsing behavior when `exclude` is omitted. User-provided `exclude` values should still remain authoritative.

The purpose is not to guess every possible personal folder name. It is to exclude the most obvious tooling and template roots that would otherwise create noise or accidental content ingestion.

### 3. Keep content classification strict and conservative

Content discovery should continue to treat only `.md` and `.html` files as site content.

All other files under the content root should be treated as non-content artifacts. They are not pages, are not frontmatter-parsed, and should not appear in content inventories as content records.

This is important because Obsidian vaults commonly mix notes with images, PDFs, binaries, and exported media. The first compatibility step is not to reinterpret those as pages, but to stop misclassifying them.

### 4. Add vault-resource copying from the content tree

MoonInk should copy non-content files that live under the content tree into the output directory, preserving relative paths, as long as they are not inside excluded helper directories.

That means vault directories such as:

- `Attachments/`
- `assets/`
- `images/`
- other user-created resource folders

should work without requiring the user to move files into project-root `public/`.

This new copying rule should coexist with the existing `public/` asset behavior. `public/` remains a separate explicit asset root. The added vault-resource copy path exists to support the common Obsidian case where resources live alongside notes.

If a copied resource path would collide with a generated content output path, the build should fail with a clear error rather than silently overwriting either side.

### 5. Distinguish note links from resource links during WikiLink resolution

WikiLink resolution needs one more branch for vault compatibility.

Behavior should be:

- `[[Note]]` continues through the existing page-target resolution path.
- `[[file.png]]` and `![[file.png]]` should first be checked as resource targets when they do not resolve as pages.
- If the target is a copied vault resource, resolve the link to the emitted resource URL.
- If the resource target cannot be found, report a warning-level unresolved-resource diagnostic.

For embed rendering in this milestone:

- image-like embeds should render as inline images;
- non-image embeds should degrade to ordinary links to the resource;
- no advanced media-player or file-preview behavior is required.

This keeps the feature useful for common Obsidian image embeds without overcommitting to plugin-like rendering semantics.

### 6. Make homepage inference predictable and minimal

Home-page inference should stay explicit and small.

Rules:

- If root `index.md` exists, it maps to `/`.
- Else if root `README.md` exists, it maps to `/`.
- Else build still succeeds, but `check` reports a warning that the vault has no homepage note.
- If both `index.md` and root `README.md` exist, `index.md` wins and `README.md` is treated as a normal page.

This intentionally avoids more magical folder-note or “best guess” behavior. The goal is to support common loose vaults while keeping the output model deterministic.

### 7. Preserve frontmatter-free notes as a first-class happy path

Users should not need to batch-add frontmatter before they can publish.

This design therefore depends on fallback behavior rather than frontmatter requirements:

- content kind continues to derive from existing file-format rules unless explicit frontmatter overrides apply;
- title fallback should prefer the first H1 when available, then fall back to the filename stem;
- navigation should derive from filesystem structure rather than assuming nav frontmatter exists.

This is a compatibility requirement, not a convenience extra. Obsidian vaults commonly contain many notes with no YAML block at all.

### 8. Use filesystem-driven navigation as the default vault fallback

When frontmatter is absent, navigation should still remain stable and predictable.

Default ordering should be:

- site homepage first;
- within a directory, `index.md` or `README.md` first if present;
- all remaining siblings in stable filename order.

The point is not to produce a perfect information architecture automatically. The point is to give direct vault builds a usable default structure without requiring authors to add metadata before first publish.

## Diagnostics

`check` should grow three vault-oriented diagnostics:

- warn when no homepage note is detected at the vault root;
- warn when a resource-style WikiLink or embed target cannot be resolved;
- avoid emitting diagnostics for content that lives entirely inside excluded helper directories.

These diagnostics should stay actionable and low-noise. The compatibility pass should reduce false positives from vault tooling directories, not add more diagnostic clutter.

## Files to modify

Primary files:

- `src/core/config.mbt`
- `src/core/core_test.mbt`
- `src/runtime/content_discovery.mbt`
- `src/runtime/runtime_test.mbt`
- `src/docflow/wikilinker.mbt`
- `src/docflow/pipeline.mbt`
- `src/docflow/docflow_test.mbt`
- `src/cli/cmd_build.mbt`
- `src/cli/cmd_onboard.mbt`
- `src/cli/cli_test.mbt`
- `docs/technical/03-Configuration-Design.md`
- `docs/technical/07-Linking-and-WikiLink.md`
- `docs/technical/10-CLI-and-Dev-Server.md`
- `docs/agent-working/MoonInkCliArch.md`
- `docs/agent-working/worklog/20260418.md` or the worklog file for the actual implementation date

New fixtures likely needed:

- a minimal direct-build Obsidian vault fixture;
- a fixture with excluded helper directories and template folders;
- a fixture with attachments and image embeds;
- a fixture covering homepage inference (`index.md`, `README.md`, and both).

## Testing strategy

### 1. Add fixture-backed coverage for direct vault build

Add an integration fixture representing a typical small Obsidian vault with:

- notes with no frontmatter;
- `.obsidian/` present;
- at least one attachment directory;
- at least one WikiLink between notes.

Verify that `build` succeeds without requiring content edits.

### 2. Verify helper-directory exclusion behavior

Add tests showing that `.obsidian`, `templates`, and `Templates` do not leak into content discovery when `exclude` is omitted.

Also verify that normal user content outside those directories still appears in discovery.

### 3. Verify vault-resource copying and collision handling

Add coverage for:

- copied resource files preserving relative paths into output;
- image embeds resolving to emitted resource paths;
- non-image embeds degrading to ordinary links;
- resource/content path conflicts failing the build.

### 4. Verify homepage inference rules

Add separate tests for:

- root `index.md` becoming `/`;
- root `README.md` becoming `/` when `index.md` is absent;
- warning when neither exists;
- deterministic precedence when both exist.

### 5. Verify frontmatter-free fallback behavior

Add tests confirming that notes with no frontmatter still receive stable title and navigation behavior.

That includes:

- first H1 preferred as title;
- filename stem fallback when no H1 exists;
- filesystem-driven nav ordering.

## Trade-offs

### Why not expose `vault_mode: "obsidian"` now?

Because the current milestone is about making the default product path better, not about asking users to learn another switch. If the default behavior can be made robust enough, a separate mode is unnecessary complexity.

### Why copy non-content vault resources instead of forcing `public/`?

Because forcing users to relocate attachments would violate the “direct vault build” goal. Obsidian users typically organize attachments inside the vault itself, and that structure should work with minimal friction.

### Why keep homepage inference minimal?

Because this is where publishing tools become unpredictable very quickly. Supporting `index.md` and root `README.md` captures the common low-effort cases without creating a maze of path heuristics that users cannot reason about.

### Why not support all embed types now?

Because the first useful compatibility step is note links plus image resources. Broader embed semantics are real future work, but they should be introduced deliberately rather than bundled into the minimum viable vault path.

## Success criteria

This feature is complete when:

1. A typical Obsidian vault can build successfully with little or no config changes.
2. Users do not need to add frontmatter to existing notes before first publish.
3. Default exclusions suppress common Obsidian/tooling directories without hiding normal content.
4. Vault resources under the content tree are copied into output and can be linked from notes.
5. Resource-style WikiLinks and embeds behave predictably for the supported cases.
6. Homepage inference follows the explicit `index.md` / root `README.md` rules.
7. `check` surfaces missing-homepage and unresolved-resource warnings without adding helper-directory noise.

## Verification

Planned verification commands:

- `moon test`
- `moon check`
- `moon info && moon fmt`

Targeted behavior to verify:

- direct vault build succeeds with frontmatter-free notes;
- helper directories are excluded by default;
- vault resources are copied and linked correctly;
- homepage inference matches the defined precedence;
- output/resource collisions fail clearly;
- `check` warnings match the supported vault diagnostics.
