# 12 Risks And Evolution

## 1. Main Risks

### Ecosystem Maturity

MoonBit may require more self-implemented infrastructure than ecosystems with mature parser and template libraries.

### Scope Expansion

Knowledge-base products tend to attract feature requests such as backlinks, graph views, and advanced references very early.

### Rendering Complexity

Themes and local search can grow complexity quickly if not constrained.

### Multilingual Rework

If page identity is path-only, later multilingual support becomes difficult.

## 2. Mitigation Principles

- keep V1 scope narrow;
- prefer explicit intermediate models;
- preserve stable content identity;
- delay ecosystem APIs until internal patterns are proven.

## 3. Evolution Priorities

The most important post-V1 evolutions are:

- incremental build;
- multilingual support;
- deployment integration;
- formal plugin and theme extension points.

## 4. Architectural Guardrails

To support evolution safely, MoonInk should avoid coupling parsing, routing, rendering, and search into a single shared state machine. Boundaries defined in `docs/technical/00-Architecture.md` should remain stable.
