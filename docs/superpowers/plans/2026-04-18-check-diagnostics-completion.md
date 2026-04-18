# MoonInk Check Diagnostics Completion Plan

## Goal Description

Complete the remaining gaps between `docs/superpowers/specs/2026-04-15-check-diagnostics-design.md`
and the current `origin/main` implementation so `moonink check` fully matches the approved
first-version diagnostics contract.

On the latest main line, the blocking-vs-warning policy, theme/template preflight, final-route
conflict detection, narrow frontmatter validation, and non-emitting behavior are already present.
The remaining work is to finish the user-facing report contract:

- rename the current user-facing `document` category to `wikilinks`;
- render grouped output by category in the fixed spec order instead of printing entries in raw
  accumulation order;
- keep summary and exit-code behavior stable while making pass/fail wording explicit and predictable;
- update regression coverage and maintained documentation so the implemented contract is durable.

## Acceptance Criteria

- AC-1: `moonink check` reports diagnostics under the exact user-facing groups
  `theme/template`, `frontmatter`, `routes`, and `wikilinks`.
  - Positive Tests (expected to PASS):
    - Warning-only wikilink fixtures print `[check] wikilinks`.
    - Mixed-result fixtures print both a blocking group and `wikilinks`.
    - Theme/template and route/frontmatter fixtures keep their existing group labels.
  - Negative Tests (expected to FAIL before implementation, then PASS after fix):
    - Assertions expecting `[check] wikilinks` fail while the implementation still prints
      `[check] document`.
    - Assertions expecting `[check] document` to be absent fail while the old label remains.

- AC-2: Grouped CLI output is rendered in the fixed category order from the spec and prints only
  non-empty groups.
  - Positive Tests (expected to PASS):
    - Mixed diagnostics output shows `theme/template`, then `frontmatter`, then `routes`, then
      `wikilinks` whenever those groups are present.
    - Warning-only output prints only the `wikilinks` group plus summary.
    - Blocking-only output prints only the groups that actually contain errors.
  - Negative Tests (expected to FAIL before implementation, then PASS after fix):
    - A mixed-result test that checks category order fails while formatting still follows raw entry
      append order.
    - A test that ensures empty groups are omitted fails if the formatter prints placeholders for
      missing categories.

- AC-3: Summary and exit semantics remain aligned with the approved first-version check contract.
  - Positive Tests (expected to PASS):
    - Warning-only runs return exit code `0` and end with a stable summary plus pass wording.
    - Blocking runs return exit code `1` and end with a stable summary plus failure wording.
    - Mixed-result runs still count both errors and warnings correctly.
  - Negative Tests (expected to FAIL before implementation, then PASS after fix):
    - A warning-only test expecting explicit pass wording fails while success output still ends
      with the older `completed` wording.
    - A mixed-result summary-count assertion fails if regrouping changes counts incorrectly.

- AC-4: `check` remains non-emitting and all project-required records are updated for the completed
  change set.
  - Positive Tests (expected to PASS):
    - Existing no-output assertions for `check` fixtures continue to pass on both warning-only and
      blocking scenarios.
    - The implementation note and maintained CLI architecture document both reflect the finalized
      `wikilinks` grouping and grouped-output behavior.
    - A dated worklog line is appended for this prompt-level completion.
  - Negative Tests (expected to FAIL before implementation, then PASS after fix):
    - Documentation review fails if maintained docs still describe the old `document` label.
    - Completion is considered invalid if the worklog entry is missing.

## Path Boundaries

### Upper Bound (Maximum Scope)

Acceptable implementation may refactor the check formatter/report helpers inside
`src/cli/cmd_build.mbt` so category grouping is explicit and easy to extend, as long as:

- the feature remains inside the existing CLI-layer report model;
- no new diagnostics framework or command is introduced;
- blocking policy remains limited to the already approved first-version checks.

### Lower Bound (Minimum Scope)

The minimum acceptable implementation is:

- rename the user-facing `document` category to `wikilinks`;
- add deterministic category-ordered rendering for existing report entries;
- update/extend CLI tests to lock the final output contract;
- update required implementation and maintained docs plus the dated worklog.

### Allowed Choices

- Can use: small helper functions for per-category filtering, explicit category-order arrays,
  focused CLI fixture assertions, documentation updates required by `ProjectBasis.md`.
- Cannot use: a new `doctor` command, new configurable severities, anchor validation, broader
  frontmatter schema work, or a large build/check architecture rewrite.

## Dependencies and Sequence

### Milestones

1. Milestone 1: Freeze the completion scope against current main
   - Reconfirm the current output behavior on the warning-only and mixed-result fixtures.
   - Keep the implementation limited to the remaining spec drift instead of reopening already
     completed diagnostics behavior.

2. Milestone 2: Finish the report formatter contract
   - Update the category label and any related helpers from `document` to `wikilinks`.
   - Change report rendering so output is grouped and emitted in fixed category order.
   - Make success/failure summary wording explicit and stable.

3. Milestone 3: Lock behavior with regression coverage
   - Extend `src/cli/cli_test.mbt` to assert the new category name, ordered grouping, summary
     wording, and non-emitting behavior.
   - Re-run focused CLI tests before full verification.

4. Milestone 4: Finalize repository records and validation
   - Update `docs/agent-working/CheckDiagnosticsImpl0415.md`.
   - Update `docs/agent-working/MoonInkCliArch.md`.
   - Append one dated line to `docs/agent-working/worklog/20260418.md`.
   - Run `moon test src/cli`, `moon check`, `moon info`, and `moon fmt`.

## Implementation Notes

- Keep changes package-local to `src/cli/`.
- Prefer formatter/report helper edits over touching parsing, runtime discovery, or docflow logic.
- Do not add plan terminology to the shipped code.
- Review `.mbti` diffs after `moon info`; public API changes are not expected for this slice.
