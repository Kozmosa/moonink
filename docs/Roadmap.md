# MoonInk Roadmap

## 1. Roadmap Positioning

This roadmap translates the MoonInk RFC into an executable engineering plan. It is designed to support both project implementation and later proposal writing, so each phase contains product scope, technical output, risks, and completion signals.

## 2. Overall Development Principle

- prioritize a complete vertical slice over feature breadth;
- stabilize the core model before opening extensibility;
- keep module boundaries explicit from the beginning;
- ensure each phase leaves behind usable documents and testable artifacts.

## 3. Phase 0 - Foundation And Design Freeze

### 3.1 Objective

Turn the current concept into a stable implementation baseline.

### 3.2 Deliverables

- RFC document finalized;
- roadmap document finalized;
- full technical document set under `docs/technical/`;
- reference analysis summary from MkDocs and MoonBit docs;
- first sample site information architecture.

### 3.3 Engineering Focus

- define module boundaries;
- define content model;
- define route and navigation rules;
- define configuration schema and CLI contract.

### 3.4 Exit Criteria

- no unresolved first-release scope questions;
- architecture diagrams and module responsibilities are documented;
- implementation order is clear enough to start coding without redesign.

## 4. Phase 1 - MVP Core Generator

### 4.1 Objective

Deliver a usable static site generator with the minimum coherent feature set.

### 4.2 User-Facing Scope

- `moonink new` initializes a starter project;
- `moonink build` produces a static site;
- `moonink serve` previews the site locally;
- Markdown content with frontmatter is supported;
- dual-track content structure is supported;
- default navigation is generated and can be manually adjusted;
- the official theme renders pages consistently;
- static search works for generated sites.

### 4.3 Core Engineering Tasks

- implement TOML config loader and validator;
- implement content discovery and file classification;
- implement frontmatter parser;
- implement Markdown parsing pipeline;
- implement route generation and page identity normalization;
- implement internal link validation and WikiLink resolution;
- implement site model builder;
- implement renderer and official theme assets;
- implement search index emitter;
- implement CLI and local dev server.

### 4.4 Suggested Milestones

- M1: config + file discovery + starter project template;
- M2: Markdown + frontmatter parsing;
- M3: navigation, route generation, and page model;
- M4: renderer + official theme;
- M5: search index + serve command + test stabilization.

### 4.5 Immediate Parsing Track Under M2

M2 now includes a dedicated parser implementation track centered on explicit document-flow boundaries.

The near-term target flow is:

```text
FrontMatterParser
  -> ParserAdapter
  -> WikiLinker
  -> RenderAdapter
  -> Templater
  -> SiteConstructor
```

The first backend plan is:

- use `mizchi/markdown` as the initial Markdown parser and HTML render backend;
- keep parsing and rendering separated behind adapter boundaries;
- add a `Typst` stub backend early to validate future format extensibility;
- add an HTML passthrough adapter for page-oriented HTML input;
- connect article/page branching into the build pipeline.

This track is documented in `docs/technical/14-Doc-Flow-Parser-Impl-Plan.md` and should be executed as an atomic TDD-oriented commit sequence.

### 4.6 Exit Criteria

- sample site can build successfully;
- generated site contains docs pages and article pages;
- link validation reports errors clearly;
- WikiLink resolution works on known fixtures;
- unit tests cover critical modules.

## 5. Phase 2 - Quality And Productivity Enhancements

### 5.1 Objective

Improve performance, authoring quality, and operational completeness without destabilizing the MVP model.

### 5.2 Priority Enhancements

- incremental build;
- stronger `check` capability or pre-build validation pipeline;
- better local preview feedback;
- refined search indexing and ranking;
- deployment integration targets.

### 5.3 Secondary Enhancements

- richer metadata fields;
- article listing and tag aggregation improvements;
- stronger route conflict diagnostics;
- more sample templates.

### 5.4 Exit Criteria

- large fixture sites rebuild faster than full clean builds;
- diagnostics are actionable enough for content authors;
- deployment workflow is documented and partly automated.

## 6. Phase 3 - Internationalization And Publishing Expansion

### 6.1 Objective

Extend MoonInk beyond single-language publishing and prepare it for broader usage scenarios.

### 6.2 Planned Scope

- multi-language content directories or language prefixes;
- localized navigation and metadata handling;
- route and asset strategy for multiple languages;
- more formal deployment integration.

### 6.3 Risks

- route complexity increases significantly;
- content synchronization rules become harder;
- theme assumptions may need to be generalized.

### 6.4 Exit Criteria

- language-specific builds are deterministic;
- the official theme works with localized navigation;
- project structure for multilingual sites is documented.

## 7. Phase 4 - Extensibility And Ecosystem

### 7.1 Objective

Open carefully designed extension points after the core architecture has proven stable.

### 7.2 Planned Scope

- internal lifecycle hooks formalized into a plugin model;
- theme override or theme package mechanism;
- selected official extensions such as search refinements, sitemap, or RSS;
- knowledge-base enhancements such as backlinks or graph-oriented metadata.

### 7.3 Exit Criteria

- extension APIs have versioning rules;
- at least one non-core extension proves the architecture;
- extension failure modes are diagnosable and bounded.

## 8. Immediate Engineering Track - IO Runtime And Async Refactor

### 8.1 Positioning

MoonInk now has a concrete near-term engineering track for filesystem and runtime evolution:

- use `moonbitlang/x/fs` as the current filesystem capability source;
- treat `native` as the required first-class target;
- refactor IO toward an async runtime boundary;
- keep parsing, routing, modeling, and rendering logic synchronous where practical.

This track is a delivery prerequisite for later `build` and `serve` maturity, not a detached side effort.

### 8.2 Why This Track Exists Now

Current real features already touch the filesystem in multiple places:

- starter project emission in `new`;
- configuration loading from `moonink.toml`;
- recursive content discovery under `docs/` and `articles/`.

Without a dedicated runtime IO boundary, these call sites would continue to spread raw filesystem access across feature modules.

`IO-P1` has now been executed and the current code-facing inventory lives in `docs/technical/15-IO-Surface-Inventory.md`.
`IO-P2` has now introduced the first explicit runtime boundary in `io_runtime.mbt`, with `cli_exec` routed through that module before reaching side-effecting commands.
`IO-P3` has now introduced a shared `ProjectIOError` model in `io_error.mbt`, so runtime and feature layers report filesystem failures with normalized operation/path/detail context.
`IO-P4` has now introduced shared relative-path normalization and a UTF-8 text policy in `io_policy.mbt`, freezing the current path and text assumptions before facade work begins.
`IO-P5` has now introduced `runtime_io.mbt` as the project-owned sync facade over `x/fs`.
`IO-P6` has now introduced `runtime_async.mbt` with `RuntimeIOTask[T]` as the first async-capable runtime interface shape.
`IO-P7` has now moved configuration file reads onto the runtime task boundary, separating config source reading from synchronous parsing.
`IO-P8` has now added starter write planning and overwrite preflight validation before filesystem mutation begins.
`IO-P9` has now added explicit content discovery planning and workspace-root tasks before recursive traversal begins.
`IO-P10` has now introduced `runtime_native.mbt` so native-specific task execution and CLI runtime wiring are explicit below the generic runtime facade.
`IO-P11` has now removed direct synchronous feature entrypoints from the public surface in favor of result-oriented runtime APIs plus task/native adapter paths.

### 8.3 Atomic Commit Roadmap

- `IO-P0: Writing Plan` ✅
- `IO-P1: Inventory Existing IO Surface` ✅
- `IO-P2: Define IO Layer Boundaries` ✅
- `IO-P3: Introduce Unified IO Error Model` ✅
- `IO-P4: Introduce Path And Encoding Policy` ✅
- `IO-P5: Add Sync Facade Over x fs` ✅
- `IO-P6: Introduce Async IO Interface` ✅
- `IO-P7: Migrate Read Operations First` ✅
- `IO-P8: Migrate Write Operations With Safety Guarantees` ✅
- `IO-P9: Migrate Directory And Workspace Loading` ✅
- `IO-P10: Introduce Native Runtime Adaptation Layer` ✅
- `IO-P11: Remove Direct Synchronous IO Entrypoints` ✅
- `IO-P12: Add Tests For Async IO Contracts`
- `IO-P13: Add Concurrency And Cancellation Policy`
- `IO-P14: Documentation And Migration Closure`

### 8.4 IO Track Milestones

- IO-M1: `IO-P0` to `IO-P4` freeze constraints, boundaries, and error policy;
- IO-M2: `IO-P5` to `IO-P6` establish the runtime facade;
- IO-M3: `IO-P7` to `IO-P10` migrate the main read, write, and discovery flows;
- IO-M4: `IO-P11` to `IO-P14` remove legacy paths and stabilize the new model.

### 8.5 Completion Signals

The IO track should be considered effective when:

- new work stops adding raw filesystem calls directly inside feature modules;
- the native runtime has a project-owned IO boundary;
- the first real async execution path exists for build-related operations;
- the synchronous core remains modular and testable.

## 9. Cross-Phase Technical Priorities

### 9.1 Documentation

Every phase should keep implementation documents aligned with actual code behavior. Documentation drift is a major long-term risk for a tool meant to demonstrate engineering clarity.

### 9.2 Testing

Testing starts with unit coverage in Phase 1 and expands toward fixture-based and integration checks in later phases.

### 9.3 Brand Consistency

The official theme, CLI messaging, and sample project should all reflect the brand direction of MoonInk: restrained, precise, and quietly modern.

## 10. Risks Across The Roadmap

- MoonBit library support may constrain parser or template implementation choices.
- Search and dev server features can grow quickly in complexity.
- Knowledge-base expectations can push the product outside the intended first-release boundary.
- Multilingual support may require revisiting route and content identity assumptions.
- Runtime and async refactoring may spread through the codebase too broadly if the facade boundary is not enforced early.

## 11. Success Metrics

The roadmap should be considered effective if it leads to:

- a working MoonBit-based static site generator MVP;
- a technically credible architecture suitable for proposal defense;
- documentation good enough to guide implementation and future contributors;
- a clear upgrade path from MVP to extensible ecosystem.

## 12. Immediate Next Actions

- complete `IO-P0` and keep the IO technical plan current;
- treat `IO-P1` as completed and use its inventory output as the input to `IO-P2`;
- execute the parser implementation track documented in `docs/technical/14-Doc-Flow-Parser-Impl-Plan.md`;
- continue Phase 1 implementation through frontmatter, Markdown, and model stages;
- convert RFC and roadmap into proposal language when ready.
