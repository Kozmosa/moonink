# Project Basis

## Purpose

This document defines persistent project-level working conventions for MoonInk.
All contributors and agents must follow these rules unless the project owner
explicitly overrides them.

## Mandatory Change Logging

For every completed change set at the granularity of one prompt, one complete
requirement, or one commit / several closely related commits, append exactly one
summary line to:

- `docs/agent-working/worklog/YYYYMMDD.md`

Requirements for each line:

- include the local date and time;
- include a concise summary of what was changed or implemented;
- append the line instead of rewriting prior history.

Recommended format:

```text
HH:MM +ZZZZ - summary of the completed change set
```

## Mandatory Implementation Documentation For Large Tasks

After completing a large feature, milestone, or architecture-affecting task,
add or update implementation documentation under `docs/agent-working/`.

Examples:

- `docs/agent-working/CliImpl0324.md`
- `docs/agent-working/RenderImplXXXX.md`

Implementation documents should capture:

- goal and scope;
- files changed;
- design decisions and trade-offs;
- current limitations / placeholders;
- next implementation steps.

## Mandatory Maintenance Of Global Working Docs

When a change affects long-lived architecture, workflow, or project-wide design,
update the corresponding maintained document under `docs/agent-working/`.

Examples:

- `docs/agent-working/MoonInkCliArch.md`
- future global docs for rendering, content model, build pipeline, and workflow.

This means a large completed task may require both:

1. a task-specific implementation note; and
2. an update to one or more global maintained documents.

## Execution Order Requirements

For any non-trivial completed change:

1. finish the code / document change itself;
2. append the dated worklog line;
3. add or update implementation documentation if the task is large;
4. update any affected global maintained docs;
5. run the relevant validation commands.

## Agent Compliance

- `AGENTS.md` must reference this file.
- Agents working in this repository must treat this file as binding project
  policy.
- If a task completes without the required worklog or required maintained docs,
  it is considered incomplete.
