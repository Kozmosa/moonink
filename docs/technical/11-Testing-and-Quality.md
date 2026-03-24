# 11 Testing And Quality

## 1. V1 Quality Baseline

MoonInk V1 adopts unit testing as the minimum formal quality bar.

## 2. Priority Test Targets

- configuration parsing and validation
- frontmatter parsing
- Markdown parsing boundaries
- route generation
- navigation generation
- internal link validation
- WikiLink resolution
- search index generation

## 3. Recommended Fixture Strategy

In addition to unit tests, the project should keep a small set of fixture sites for regression checks, even if formal end-to-end testing arrives later.

## 4. Diagnostics Quality

Good error messages are part of product quality. Errors should identify the file, the failing rule, and the likely remediation path whenever possible.

## 5. Future Quality Expansion

Later phases should add snapshot-style output verification, integration tests, and larger fixture builds.
