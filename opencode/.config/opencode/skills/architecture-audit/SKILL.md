---
name: architecture-audit
description: Perform deep best-practices audits for any software project (frontend, backend, APIs, mobile, data/ML, infra). Use when users ask to audit architecture, code quality, scalability, maintainability, reliability, security posture, or "what should be improved" across a codebase.
author: DevTrev
license: MIT
---

# Architecture Audit

Perform a structured, evidence-based audit of a codebase. Focus on architecture quality, engineering rigor, operational readiness, and long-term maintainability.

## Core Principles

- Audit first, change later. Do not modify code unless explicitly requested.
- Ground every finding in evidence (file paths, behavior, test output, or config).
- Prefer risk-based prioritization over long unranked lists.
- Distinguish "works today" from "scales safely".
- Be architecture-aware: evaluate against the stack actually used, not generic ideals.

## Output Contract

Return findings grouped by severity:

1. Critical (production/security/data-loss risk)
2. High (major scalability/reliability/maintainability risk)
3. Medium (important quality gaps)
4. Low (nice-to-have hardening)

For each finding, include:

- What is wrong
- Why it matters (impact)
- Evidence (file refs, behavior, commands)
- Recommended fix pattern (short and actionable)

Conclude with:

- Overall quality level by area (architecture, code quality, testing, operations)
- Top 3 next actions in priority order

## Audit Workflow

1. Identify project shape
   - Detect stacks/frameworks/languages/package managers.
   - Identify major runtime boundaries (client, API, workers, data stores, infra).
2. Inspect architecture and layering
   - Validate separation of concerns and module boundaries.
   - Check that state, routing, IO, domain logic, and side effects live in appropriate layers.
3. Inspect implementation quality
   - Error handling, input validation, typing, logging, retries/timeouts, resource cleanup.
4. Inspect reliability + security
   - Authn/authz, secret handling, unsafe defaults, data handling, dependency risk signals.
5. Inspect testing + delivery quality
   - Test coverage shape, edge-case tests, CI readiness, build/lint/type checks.
6. Produce prioritized recommendations
   - Make recommendations incremental, not rewrite-oriented.

## Universal Checklist (Any Software)

- Architecture
  - Clear boundaries between transport/UI, domain logic, and persistence/integration.
  - Avoid monolith files/modules with mixed concerns.
  - Shared primitives extracted; no duplicated business rules.
- Correctness
  - Input validation close to boundaries.
  - Typed contracts or schemas between layers.
  - Explicit handling of error/empty/timeout states.
- Reliability
  - Retries and backoff for transient failures.
  - Idempotency or duplicate protection where needed.
  - Safe cleanup of resources/files/handles/streams.
- Security
  - No secrets in code/history.
  - Strong auth/session/token practices.
  - Secure defaults in config and environment handling.
- Operability
  - Health checks and diagnosable logs.
  - Clear startup/dev/build/test commands.
  - Reasonable observability hooks (metrics/log context where appropriate).
- Maintainability
  - Naming clarity, cohesive modules, low coupling.
  - Predictable project structure.
  - Documentation reflects actual architecture.

## Frontend-Specific Checklist

- Routing
  - Dedicated router used for navigation/deep-linking, not ad-hoc state switching for app-level flows.
  - Route boundaries aligned to features/screens.
- State Management
  - Server state handled by a data-fetching/cache layer (queries/mutations/invalidation).
  - Local UI state kept local; global state introduced only when justified.
- Data + Forms
  - API calls centralized in clients/services.
  - Forms use schema validation and structured form state for non-trivial flows.
- UI Architecture
  - Components are presentational where possible; side effects moved to hooks/services.
  - Accessibility basics covered (keyboard, labels, semantics, focus behavior).
- Performance
  - Avoid unnecessary rerenders and heavyweight state coupling.
  - Route/data loading strategy scales with app growth.

## Backend/API-Specific Checklist

- API Design
  - Clear route responsibilities; avoid large handler functions with mixed concerns.
  - Proper status codes and consistent error envelope.
- Domain + Persistence
  - Business logic separated from transport layer.
  - Repository/service patterns where complexity warrants.
  - Transactions and concurrency behavior are explicit.
- Validation + Security
  - Strong request schema validation.
  - Authn/authz checks enforced at boundaries.
  - Sensitive defaults rejected (weak secrets, permissive CORS, insecure cookies in prod).
- Reliability
  - Timeout/retry strategy for external calls.
  - File/stream handling avoids blocking critical paths when async model is expected.
- Config
  - Environment variables validated; startup fails fast on invalid config.

## Data / ML / Analytics Checklist

- Data quality checks at ingestion boundaries.
- Reproducible pipeline steps and deterministic transforms where expected.
- Schema/version management for datasets/features/models.
- Clear offline vs online parity assumptions.
- Monitoring for drift, freshness, and failure alerts.

## Mobile/Desktop Client Checklist

- Navigation stack organized by features.
- Offline/cache behavior explicit.
- Platform permissions and secure storage handled correctly.
- Background task lifecycle and resource/battery impact considered.

## Distributed / Microservices Checklist

- Service boundaries and ownership are clear.
- Contract compatibility/versioning strategy exists.
- Resilience patterns in place (timeouts, retries, circuit breaking, backpressure).
- Traceability across services (request IDs, correlated logs).

## Infra / DevOps Checklist

- Build reproducibility and dependency pinning strategy are coherent.
- CI runs tests/lint/type/build gates.
- Environment promotion strategy is explicit.
- Least-privilege and secret management practices are defined.

## Evidence Standards

- Always cite concrete paths for findings.
- If tests/checks are run, report pass/fail plus key failing signals.
- If a likely issue is inferred (not proven), label it as "potential" and state how to verify.

## Severity Rubric

- Critical: exploitable security issue, data corruption/loss, or production outage likelihood.
- High: major architectural debt blocking scale or likely causing incidents.
- Medium: quality gaps that increase maintenance cost or bug likelihood.
- Low: polish and consistency improvements.

## Recommendation Style

- Prefer incremental migration plans over broad rewrites.
- Recommend the smallest high-leverage fix first.
- Tie each recommendation to a clear outcome (reliability, scalability, security, speed).
