# 06 Markdown And Frontmatter

## 1. Input Model

MoonInk V1 accepts markup-oriented article sources and HTML-oriented page sources.

For the current implementation track:

- Markdown is the first real article source format;
- Typst is a planned future article source format;
- raw HTML remains acceptable as page-oriented input;
- inline HTML inside Markdown is acceptable when supported by the Markdown backend.

## 2. Frontmatter Role

Frontmatter supplies page metadata used in rendering, routing, navigation, and search.

Frontmatter parsing should stay independent from content parser backends. Its job is to:

- extract metadata;
- extract body content;
- assign or preserve source identity such as UUID;
- produce the clean parser-facing input object.

## 3. Supported Metadata In V1

- `title`
- `id`
- `author`
- `tags`
- `date`

## 4. Parsing Responsibilities

MoonInk should separate the following responsibilities explicitly:

- frontmatter extraction;
- body extraction;
- parser backend selection;
- article parsing through `ParserAdapter`;
- post-parse semantic processing through `WikiLinker`;
- HTML generation through `RenderAdapter`;
- derived fields such as excerpt or reading metadata if later added.

This separation is more important than treating Markdown parsing as a single monolithic step.

## 5. ParserAdapter Strategy

The adapter layer should accept a parser-facing object with:

- `path`
- `format`
- `content`
- `uuid`

The output should be a thin `ParsedDocument` carrying:

- backend identity;
- source format;
- diagnostics;
- backend-native payload.

The adapter should not force a universal AST for Markdown and Typst in V1.

## 6. Markdown Backend Strategy

The first integrated Markdown backend should be `mizchi/markdown` because it offers the shortest path to a working parse-and-render closure for the MVP.

However, MoonInk should still keep Markdown parsing behind `ParserAdapter` and HTML generation behind `RenderAdapter` so that future backend replacement remains possible.

## 7. Parser Constraints

V1 should prefer a deterministic, testable content feature set and avoid overcommitting to cross-format abstractions too early.

The initial strategy is therefore:

- preserve backend-native payloads rather than forcing a shared AST;
- expose diagnostics and pipeline boundaries clearly;
- add richer normalized queries only after real build needs justify them.

## 8. Error Handling

Malformed frontmatter should produce actionable diagnostics with file path context.

Parser backends should follow a two-level policy:

- best-effort diagnostics when useful output can still be produced;
- fatal parser errors only when a meaningful parsed document cannot be returned.

Diagnostics should be stored as structured data and later formatted into user-facing messages.
