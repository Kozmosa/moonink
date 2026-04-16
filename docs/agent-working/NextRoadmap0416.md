# Next Roadmap 0416

## Goal

Define a near-term roadmap slice with at least three new feats that can be developed in parallel on top of the current MoonInk architecture, while keeping ownership boundaries clear and minimizing file-level conflicts.

## Current Project Snapshot

The current codebase already has these foundations in place:

- a stable CLI surface for `build`, `check`, `serve`, and `onboard`;
- a layered architecture of `cli -> runtime -> core`, with `docflow` handling parser / wikilink / render stages;
- frontmatter parsing for title, description, date, tags, draft, and extra fields;
- emitted search-index infrastructure already landed as a build artifact milestone;
- backlinks integrated through template context;
- theme/template loading and fixture-backed build coverage;
- placeholder site-assembly and navigation models still present in `src/core/model.mbt`.

This makes the project well suited for parallel roadmap work, provided each feat is scoped to one primary layer.

## Recommended Parallel Feats

### Feat A — Frontmatter-Driven Content Behavior

**Objective**

Turn existing parsed frontmatter into stronger build-time behavior, especially for:

- `draft` exclusion from normal output;
- `date`-driven ordering;
- `tags` propagation into page metadata and template context;
- `title` / `description` precedence rules when deriving page metadata.

**Why now**

`src/core/frontmatter.mbt` already parses these fields, but the build pipeline currently uses only part of that information. This feat upgrades frontmatter from parsed metadata to actual site behavior.

**Primary ownership boundary**

- `src/core/frontmatter.mbt`
- `src/core/page_meta.mbt`
- `src/core/model.mbt`
- `src/runtime/content_discovery.mbt`

**Expected deliverables**

- draft documents omitted from standard build output;
- deterministic article/page ordering contract using frontmatter date where present;
- tags and descriptions exposed in stable metadata fields;
- fixture-backed tests for mixed frontmatter cases.

**Parallelization note**

This work stays mostly in metadata and discovery logic. It should have low overlap with theme asset work and only light overlap with search-index consumption.

---

### Feat B — Theme / Template Asset Pipeline Completion

**Objective**

Complete the output-side theme contract so projects can rely on theme assets and template overrides without ad hoc wiring.

Proposed scope:

- copy theme static assets into the build output;
- formalize project-template-over-theme precedence;
- keep `build` and `serve` behavior consistent for theme resolution;
- document the supported theme asset root / template variables contract.

**Why now**

Theme loading has already been strengthened in `check` and `serve`, but the asset side is the natural next step for making themes production-ready.

**Primary ownership boundary**

- `src/runtime/config_loader.mbt`
- `src/runtime/io.mbt`
- `src/core/config.mbt`
- `src/cli/cmd_build.mbt`
- built-in theme files and related fixtures

**Expected deliverables**

- deterministic asset copy behavior into output directories;
- explicit precedence for built-in theme, project theme, and explicit template file;
- fixture coverage for asset presence and override behavior;
- implementation note documenting the theme contract.

**Parallelization note**

This feat is largely isolated to runtime/build output handling and should not materially conflict with frontmatter behavior or format-backend extension work.

---

### Feat C — Typst Source Backend Support

**Objective**

Add a real Typst content backend through the existing docflow adapter registry so MoonInk supports a second first-class authoring format beyond Markdown and HTML.

Proposed scope:

- recognize Typst files during discovery;
- register parser/render adapters for Typst;
- define the first supported output contract for Typst documents;
- add fixtures and tests for backend lookup and rendered output behavior.

**Why now**

`src/docflow/adapters.mbt` already exposes parser/render registry slots for Typst, which strongly suggests this extension point was intended from the beginning.

**Primary ownership boundary**

- `src/docflow/adapters.mbt`
- `src/docflow/parser.mbt`
- `src/core/content.mbt`
- `src/runtime/content_discovery.mbt`
- Typst-specific fixtures/tests

**Expected deliverables**

- initial Typst discovery and adapter registration;
- a defined success/failure contract for unsupported Typst cases;
- fixture-backed tests for content classification and adapter behavior.

**Parallelization note**

This is a backend-extension slice centered in `docflow`. It overlaps less with theme/output work and can proceed in parallel with frontmatter and theme tasks if `content_discovery.mbt` edits are coordinated.

---

### Feat D — Search Index Consumption Contract

**Objective**

Build on the completed `search-index.json` emission milestone by defining how themes or pages consume the artifact.

Proposed scope:

- expose a documented built-in search artifact contract to themes;
- add a minimal built-in search page or search-loader template hook;
- decide whether frontmatter should allow future search include/exclude behavior;
- add fixture coverage that validates theme-side consumption assumptions.

**Why now**

The project already emits the artifact, but the user-facing search experience remains incomplete. This feat converts infrastructure into usable product behavior.

**Primary ownership boundary**

- `src/core/search_index.mbt`
- `src/cli/cmd_build.mbt`
- built-in theme/template files
- relevant fixtures under `fixtures/v2/`

**Expected deliverables**

- documented consumer contract for `search-index.json`;
- at least one built-in search integration path;
- tests that protect artifact shape and theme expectations together.

**Parallelization note**

This can run beside Feat B if responsibilities are split carefully: Feat B owns generic asset/template pipeline behavior, while Feat D owns search-specific consumer behavior.

## Recommended Parallel Development Grouping

For the cleanest 3-lane execution, use:

1. **Lane 1 — Frontmatter behavior**
   - Feat A
2. **Lane 2 — Theme/template asset pipeline**
   - Feat B
3. **Lane 3 — Typst backend**
   - Feat C

Then treat **Feat D** as an optional fourth lane or as a follow-on after Feat B stabilizes the output contract.

## Dependency And Conflict Assessment

### Lowest-conflict combination

- Feat A: metadata/discovery behavior
- Feat B: output/theme asset behavior
- Feat C: parser/render backend extension

This combination minimizes shared ownership and reduces merge pressure.

### Shared hotspots to watch

- `src/runtime/content_discovery.mbt` may be touched by both Feat A and Feat C;
- `src/cli/cmd_build.mbt` may be touched by both Feat B and Feat D;
- built-in theme files may be touched by both Feat B and Feat D.

To reduce conflicts:

- keep Feat A focused on metadata and filtering contracts, not rendering;
- keep Feat B focused on generic theme/template transport, not search UI;
- keep Feat D limited to search-specific integration points.

## Proposed Acceptance Criteria

### Feat A

- `draft: true` content is omitted from normal build output;
- date-based ordering behavior is defined and tested;
- tags/title/description are reflected in stable page metadata;
- fixtures cover mixed valid/invalid frontmatter combinations.

### Feat B

- theme assets appear in output deterministically;
- template precedence is documented and tested;
- `build`, `serve`, and `check` use the same theme-resolution expectations;
- fixture outputs remain isolated from source fixtures.

### Feat C

- Typst files are discovered or rejected through a deliberate contract, not by accident;
- adapter lookup covers the Typst path;
- rendered output or clear unsupported diagnostics are test-covered.

### Feat D

- `search-index.json` has at least one documented built-in consumer path;
- theme-side integration remains compatible with current search artifact version;
- tests validate both artifact existence and consumer expectations.

## Suggested Execution Order

1. Start **Feat A**, **Feat B**, and **Feat C** in parallel.
2. Freeze shared contracts in `content_discovery` and theme/template interfaces early.
3. Start **Feat D** once Feat B defines the stable theme-side integration surface.

## Notes For Implementation Docs

When each feat completes, it should produce:

- one dated worklog entry in `docs/agent-working/worklog/YYYYMMDD.md`;
- one task-specific implementation note under `docs/agent-working/` if the feat lands as a substantial milestone;
- any required updates to long-lived architecture docs if the global build/theme/content model changes.
