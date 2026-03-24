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

### 4.5 Exit Criteria

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

## 8. Cross-Phase Technical Priorities

### 8.1 Documentation

Every phase should keep implementation documents aligned with actual code behavior. Documentation drift is a major long-term risk for a tool meant to demonstrate engineering clarity.

### 8.2 Testing

Testing starts with unit coverage in Phase 1 and expands toward fixture-based and integration checks in later phases.

### 8.3 Brand Consistency

The official theme, CLI messaging, and sample project should all reflect the brand direction of MoonInk: restrained, precise, and quietly modern.

## 9. Risks Across The Roadmap

- MoonBit library support may constrain parser or template implementation choices.
- Search and dev server features can grow quickly in complexity.
- Knowledge-base expectations can push the product outside the intended first-release boundary.
- Multilingual support may require revisiting route and content identity assumptions.

## 10. Success Metrics

The roadmap should be considered effective if it leads to:

- a working MoonBit-based static site generator MVP;
- a technically credible architecture suitable for proposal defense;
- documentation good enough to guide implementation and future contributors;
- a clear upgrade path from MVP to extensible ecosystem.

## 11. Immediate Next Actions

- finish the technical documentation set;
- break Phase 1 into implementation tasks;
- prepare a sample MoonInk project layout;
- convert RFC and roadmap into proposal language when ready.
