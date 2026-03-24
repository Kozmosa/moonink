# 04 Build Pipeline

## 1. Pipeline Stages

MoonInk V1 build flow is intentionally explicit.

1. load configuration
2. validate configuration
3. discover files
4. parse frontmatter
5. parse Markdown
6. normalize routes and identifiers
7. resolve links and WikiLinks
8. build navigation and site model
9. render pages
10. emit static assets and search index

## 2. Why Staged Processing Matters

This staging gives three benefits:

- easier debugging;
- narrower test responsibilities;
- future extensibility through hook points.

## 3. Intermediate Outputs

Each stage should produce an explicit internal data structure rather than mutating shared global state.

## 4. Failure Strategy

The build should stop on structural failures such as invalid config or unrecoverable route conflicts. Content diagnostics such as broken links may be configurable later, but V1 should at least report them clearly.
