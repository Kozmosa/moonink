# MoonInk Docs Publish Workflow Implementation 0420

## Goal And Scope

This task adds repository-managed automation for publishing the standalone
`docs/moonink/` vault to the `gh-pages` branch whenever new commits land on
`main`.

Delivered scope:

- a GitHub Actions workflow that runs on `push` to `main` and on
  `workflow_dispatch`;
- CI setup for MoonBit plus repository checkout with push permissions;
- reuse of the existing `scripts/publish-moonink-docs.sh` deployment script
  instead of duplicating publish logic in YAML.

Out of scope:

- deployment previews for pull requests;
- multi-environment docs deployment;
- branch-specific docs versions.

## Files Changed

- `.github/workflows/publish-moonink-docs.yml`
- `docs/agent-working/MooninkDocsPublishWorkflowImpl0420.md`
- `docs/agent-working/worklog/20260420.md`

## Design Decisions And Trade-Offs

- The workflow only runs for `main` pushes. Publishing on every branch would
  either overwrite `gh-pages` from feature branches or require a versioned docs
  strategy that the repository does not currently have.
- The workflow reuses `scripts/publish-moonink-docs.sh` rather than copying its
  logic into the workflow. This keeps the docs build, base-path rewrite, and
  `gh-pages` commit flow in one place.
- The job uses `contents: write` and configures a bot identity up front because
  the publish script creates a commit in a temporary worktree and pushes it to
  `gh-pages`.
- The MoonBit installation path follows the same repository-local setup already
  used in the Copilot setup workflow, reducing divergence between local and CI
  environment bootstrap.

## Validation

Local validation for the underlying publish flow was already completed through:

- `bash -n scripts/publish-moonink-docs.sh`
- `DRY_RUN=1 scripts/publish-moonink-docs.sh`

The workflow itself is a thin wrapper around that script, so the main
functional validation point is the publish script rather than separate YAML
business logic.

## Current Limitations / Follow-Up

- The workflow publishes only from `main`.
- If future repository policy wants path-based filtering to avoid rebuilding the
  docs on unrelated pushes, the trigger can be narrowed later.
- The workflow assumes the default `GITHUB_TOKEN` can push to `gh-pages`; if
  branch protection changes, the job may need a dedicated deployment token.
