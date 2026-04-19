# MoonInk README Refresh Design

_Date_: 2026-04-20

## Context

The repository README is currently a development-status note. It inventories implemented commands and recent runtime milestones, which is useful during active implementation but weak as a durable entry point for users, contributors, and repository visitors.

MoonInk now has a public documentation site at `https://kozmosa.github.io/moonink/`. That site is not only the official user documentation but also a live demo built with MoonInk itself. The README should route readers toward that site quickly while still giving enough immediate context and quickstart material to make the repository approachable.

The user wants the new README set to take visual cues from the Docusaurus README style and from `sol.mbt`'s directness:

- a centered, product-facing hero;
- a concise, easy-to-scan structure;
- enough substance to be useful, without turning the README into a full manual;
- English primary README plus a separate Chinese README.

## Goal

Replace the current status-style repository README with a pair of stable entry documents:

- `README.md` in English;
- `README-zh.md` in Chinese.

The new README pair should:

- present MoonInk as a product rather than a changelog;
- link prominently to the public documentation site;
- explicitly state that the public site is built with MoonInk itself;
- provide a short quickstart for both direct CLI use and source-run inside this repository;
- retain concise contributor-oriented repository guidance;
- cross-link the English and Chinese versions near the top.

## Confirmed Decisions

- `README.md` is English.
- `README-zh.md` is Chinese.
- Each file must link to the other language version inside the file itself.
- The public docs/demo URL to highlight is `https://kozmosa.github.io/moonink/`.
- The README should explicitly say that this site is a demo built with MoonInk.
- Quickstart should include both:
  - the shortest path for using MoonInk in an existing Markdown directory;
  - the source-run path from this repository.
- The top of the README should follow a Docusaurus-like centered hero.
- Badge count should stay minimal at `2-3`.
- The README should keep both product-facing features and contributor-facing repository guidance.
- The README should not be unnecessarily terse; it may spend some space where that improves readability.

## Non-goals

This refresh intentionally does not attempt to:

- turn the repository README into a complete CLI reference;
- duplicate detailed setup, migration, theme, or architecture docs already covered by the docs site;
- preserve the current milestone-by-milestone implementation inventory;
- place bilingual English and Chinese content inside one file.

## Recommended Approach

Adopt a `hero-first, quickstart-early, docs-forward` README structure.

This approach is recommended because it best matches the user intent:

- the hero provides the stronger product presentation requested by the user;
- the quickstart appears early enough to support action-oriented scanning;
- the docs/demo link gets prominent placement without forcing the README to carry too much reference detail;
- repository and contribution guidance remains present but secondary.

Two alternative structures were considered and rejected as the primary direction:

- `quickstart-first`: strong for immediate action, but weaker at establishing MoonInk's identity and docs/demo entry on first impression;
- `docs-hub-first`: strong as an index page, but less attractive and less product-facing than desired.

## Design

### 1. README set and language behavior

The repository should provide two top-level README files:

- `README.md` for English;
- `README-zh.md` for Chinese.

Each file should include a near-top language switch line pointing to the other file.

Recommended patterns:

- in `README.md`: `Read this in Chinese: [README-zh.md](./README-zh.md)`
- in `README-zh.md`: `中文版说明： [README.md](./README.md)`

The Chinese README should mirror the structure of the English file, but it should be written naturally in Chinese rather than as a literal sentence-by-sentence translation.

### 2. Hero section

The top section should use a centered hero inspired by Docusaurus-style project READMEs.

Required hero elements:

- centered project title `MoonInk`;
- one-sentence product tagline;
- `2-3` badges only;
- prominent links for the documentation site and the other-language README.

The hero should look polished without becoming noisy. The design should avoid a large badge wall or decorative clutter.

The public docs/demo link should be phrased to communicate both roles clearly, for example:

- official documentation;
- live demo site built with MoonInk itself.

### 3. Intro and positioning

Immediately below the hero, the README should include a short paragraph explaining what MoonInk is for.

That paragraph should focus on user-visible value:

- build a static site from an existing Markdown folder;
- work well with Obsidian-style vault conventions;
- avoid forcing a CMS-like content migration.

This intro should replace the current `implemented pieces` and `current status` tone.

### 4. Quickstart section

The first major content section should be Quickstart.

It should contain two clearly separated paths.

#### Path A: Use MoonInk in an existing Markdown directory

This is the primary quickstart and should appear first.

It should show the shortest meaningful flow:

1. `moonink onboard`
2. create a minimal `index.md`
3. `moonink check`
4. `moonink build`
5. `moonink serve`

The commands should remain compact, with one-line explanations only where needed to avoid confusion.

#### Path B: Run from source in this repository

This path should come second and should target contributors or evaluators working directly in the repo.

It should show the corresponding `moon run src/cmd/main -- ...` flow, including native-target preview use for `serve`.

The quickstart should optimize for `copy, run, understand quickly`, not for exhaustive CLI coverage.

### 5. Documentation and demo section

A dedicated section should point readers to `https://kozmosa.github.io/moonink/`.

This section should explicitly state that the site is both:

- the official user documentation;
- a MoonInk-built demo site that demonstrates the product in practice.

This section is important because the repository README should help users discover the docs quickly instead of re-explaining them in place.

### 6. Features section

The README should include a concise feature list focused on user-visible capabilities.

Recommended emphasis:

- existing Markdown-folder workflow;
- Obsidian-style vault compatibility;
- wikilinks and internal content linking;
- frontmatter-driven page/article behavior;
- theme support;
- static HTML output;
- native local preview.

This section should avoid internal milestone wording and implementation-history framing.

### 7. Repository guide section

The README should retain a compact contributor-oriented repository guide.

Recommended content:

- short package/layout summary;
- the core contributor commands already treated as standard in this repository:
  - `moon check`
  - `moon test`
  - `moon fmt`
  - `moon info`

This section should orient contributors without trying to duplicate internal architecture docs.

### 8. Contributing and license

The final sections should be lightweight:

- a short contributing paragraph that points people toward issues and pull requests;
- a license section pointing at `LICENSE`.

These sections should remain brief and conventional.

### 9. Writing style constraints

Both README files should follow these style rules:

- product-facing and confident;
- concise, but not starved of useful explanation;
- readable in a quick scan;
- visually clean;
- no changelog-style milestone inventory;
- no deep command reference tables unless they clearly improve readability.

The README should feel like a polished repository front door, not an engineering notebook.

## Likely Files Affected

Primary files:

- `README.md`
- `README-zh.md`

Project-policy follow-up files required after completion:

- `docs/agent-working/worklog/20260420.md`

## Acceptance Criteria

The design is complete when the implementation satisfies all of the following:

1. `README.md` is rewritten in English with a centered hero, minimal badges, early quickstart, docs/demo link, features, repository guide, contributing, and license sections.
2. `README-zh.md` exists in Chinese with the same overall structure and natural Chinese wording.
3. Both files link to the other language version near the top.
4. Both files prominently link to `https://kozmosa.github.io/moonink/`.
5. The README explicitly states that the docs site is built with MoonInk itself.
6. The new README content replaces the old implementation-status style with stable, product-facing copy.
7. The final repository update includes the required worklog entry for the completed change.
