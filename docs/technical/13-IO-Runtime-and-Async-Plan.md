# 13 IO Runtime And Async Refactor Plan

## 1. Purpose

This document defines the near-term IO engineering direction for MoonInk.
It translates the current project decision into an executable refactor plan:

- filesystem access should use `moonbitlang/x/fs` as the current baseline API;
- `native` is the required first-class target;
- existing IO should be refactored gradually toward an async-oriented runtime model;
- core parsing, modeling, and rendering logic should remain as synchronous as practical.

## 2. Current Constraint Set

### 2.1 Confirmed Constraints

- MoonInk must support the `native` target.
- Filesystem operations should be built on top of `moonbitlang/x/fs`.
- IO refactoring should move toward async execution instead of expanding synchronous direct calls.

### 2.2 Architectural Implication

MoonInk should not let filesystem details leak across the whole codebase.
The project should adopt a split between:

- synchronous core logic for parsing, normalization, routing, and modeling;
- asynchronous runtime boundaries for filesystem and future external IO.

## 3. Design Principles

### 3.1 Native First, But Not Native Everywhere

The runtime implementation should optimize for `native` now, but avoid hard-coding native details into high-level build logic. Native-specific behavior should live in a dedicated runtime layer.

### 3.2 Use `x/fs` As The Source, Not As The Whole Architecture

`moonbitlang/x/fs` is the current filesystem capability provider, but MoonInk should still wrap it with its own IO facade so that the project can:

- normalize errors;
- normalize path and encoding policy;
- control async evolution;
- test upper layers without scattering raw filesystem calls.

### 3.3 Keep The Core Mostly Synchronous

The following areas should stay synchronous unless there is a strong reason otherwise:

- configuration parsing after source text is loaded;
- content classification and normalization logic;
- frontmatter and Markdown transformation;
- routing, navigation, and site model construction;
- rendering decisions that do not themselves require external IO.

### 3.4 Keep Waiting At The Edges

The following areas are the correct async boundary candidates:

- file reads and writes;
- directory enumeration;
- workspace and project-root discovery;
- future dev-server sockets or stream-based IO;
- external command or process integration if introduced later.

## 4. Target Layering

MoonInk should evolve toward the following execution structure:

1. CLI layer
2. runtime / IO facade layer
3. configuration and content ingestion layer
4. parsing and normalization layer
5. site model layer
6. rendering layer
7. output emission layer

The key change is that runtime IO becomes an explicit boundary instead of remaining embedded in feature modules.

## 5. Initial Refactor Scope

The first IO refactor wave should focus on the existing real filesystem touch points:

- starter project emission in `new`;
- `moonink.toml` loading;
- recursive content discovery under `docs/` and `articles/`.

These are already real, bounded operations and therefore provide the safest migration path.

## 6. Non-Goals For This Refactor Track

This roadmap does not attempt to do the following immediately:

- redesign the public CLI surface;
- make all internal functions async;
- add multi-target abstractions for every backend before `native` is stable;
- introduce plugin-oriented runtime hooks too early;
- solve dev-server concurrency in the same commit as basic filesystem refactoring.

## 7. Staged Atomic Commit Roadmap

### IO-P0: Writing Plan

Write and freeze the IO refactor plan, constraints, and migration guardrails.

Status: completed.

### IO-P1: Inventory Existing IO Surface

Catalog all filesystem and IO touch points, their callers, and their migration priority.

Status: completed via `docs/technical/15-IO-Surface-Inventory.md`.

Current inventory baseline:

- `config.mbt`: raw read of `moonink.toml`;
- `content.mbt`: recursive directory inspection and Markdown discovery;
- `starter.mbt`: starter-project directory creation and file writes.

### IO-P2: Define IO Layer Boundaries

Document and introduce a dedicated runtime or IO facade boundary so feature modules stop growing raw filesystem calls.

### IO-P3: Introduce Unified IO Error Model

Normalize filesystem-related errors into project-owned error types.

### IO-P4: Introduce Path And Encoding Policy

Fix path normalization and text encoding assumptions before wider async migration.

### IO-P5: Add Sync Facade Over `x/fs`

Wrap current `x/fs` calls with MoonInk-owned helper APIs without changing the whole call graph yet.

### IO-P6: Introduce Async IO Interface

Add the first async-capable facade surface for native runtime usage.

### IO-P7: Migrate Read Operations First

Move configuration loading and source-file reads to the async boundary first.

### IO-P8: Migrate Write Operations With Safety Guarantees

Move writes after reads are stable, including file creation and output emission safeguards.

### IO-P9: Migrate Directory And Workspace Loading

Move recursive discovery and project-root scanning into the runtime IO boundary.

### IO-P10: Introduce Native Runtime Adaptation Layer

Isolate native-specific runtime wiring and keep higher layers target-agnostic.

### IO-P11: Remove Direct Synchronous IO Entrypoints

Deprecate and remove remaining raw synchronous filesystem access from feature modules.

### IO-P12: Add Tests For Async IO Contracts

Cover success paths, missing-file behavior, traversal failures, and error mapping.

### IO-P13: Add Concurrency And Cancellation Policy

Define conflict handling, cancellation semantics, and future runtime scheduling rules.

### IO-P14: Documentation And Migration Closure

Update architecture, contributor guidance, and the long-lived docs so the new model becomes the default engineering path.

## 8. Milestones

### M1 - Decision And Boundary Freeze

Covers `IO-P0` to `IO-P4`.

Goal: freeze constraints, boundaries, error model, and policy before code churn increases.

### M2 - Facade Establishment

Covers `IO-P5` to `IO-P6`.

Goal: make the runtime IO boundary real before broader migration.

### M3 - Mainline Migration

Covers `IO-P7` to `IO-P10`.

Goal: move the current real read, write, and discovery flows to the new runtime model.

### M4 - Consolidation And Stabilization

Covers `IO-P11` to `IO-P14`.

Goal: remove legacy paths, add tests, and finalize contributor-facing guidance.

## 9. Exit Signals

The IO refactor track should be considered successful when:

- new feature work no longer adds raw `x/fs` calls directly in feature modules;
- runtime filesystem access has a single project-owned boundary;
- the first native async path is in place for real build operations;
- the synchronous core remains readable and testable;
- architecture and roadmap documents clearly describe the new execution model.
