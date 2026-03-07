<!-- markdownlint-disable-file MD036 -->
<!-- markdownlint-disable-file MD033 -->
<!-- markdownlint-disable MD024 -->

# CI & Workflow Naming Conventions

This document defines **naming rules for GitHub Actions workflows** in this repository.
The goal is clarity, safety, and long-term maintainability — not cleverness.

If you can understand what a workflow does **without opening the YAML**, the name is correct.

---

## Core Principle

> **Workflow names reflect purpose, not tools.**

Names should answer one question immediately:

> *What is the primary responsibility of this workflow?*

---

## Current Workflow Inventory

| File | Name | Purpose |
| --- | --- | --- |
| `ci.yml` | `CI` | Validate correctness — tests, quality, lint |
| `release.yml` | `Release` | Release lifecycle — Docker build, Helm lint, semantic-release, publish |
| `security.yml` | `Security` | CodeQL static security analysis |
| `changelog-guard.yml` | `Changelog Guard` | Prevent manual edits to `CHANGELOG.md` |
| `pr-helper.yml` | `PR Helper` | Post diagnostic comment on CI failure |
| `doctor.yml` | `Doctor` | Environment snapshot and validation |

---

## Naming Rules

### Validation workflows

Workflows whose primary job is validating correctness use short,
descriptive names without prefixes:

- `ci.yml` — the primary CI workflow (tests, formatting, static analysis)
- `security.yml` — security-focused static analysis
- `doctor.yml` — environment health check

These workflows:

- ✅ May run on every PR and branch push
- ✅ May fail safely without side effects
- ❌ Must not push images, cut releases, or mutate external systems

### Release lifecycle workflow

The `release.yml` workflow owns the full release lifecycle:

- Docker image build (validation, no push) — `docker-build` job
- Helm chart lint — `helm-lint` job
- Semantic-release (version bump, changelog, tag) — `release` job
- Docker + Helm publish to GHCR — `publish` job

Consolidating these into one file makes the trigger and permission model
explicit: each job declares only the permissions it needs.

### Guard / utility workflows

Short noun-phrase names that describe what they protect or provide:

- `changelog-guard.yml` — guards `CHANGELOG.md` from manual edits
- `pr-helper.yml` — posts helper comments on PR CI failures

---

## Rules for New Workflows

Ask yourself:

1. **Validate code or environment?** → short noun or adjective (`ci`, `security`, `doctor`)
2. **Release or publish artifacts?** → add a job to `release.yml` if it belongs to the
   release lifecycle; otherwise a new purpose-named file
3. **Protect a resource or pattern?** → `*-guard.yml`
4. **Assist developers with information?** → `*-helper.yml`
5. **Deploy to a live environment?** → `deploy-<environment>.yml` (future pattern)

If the name doesn't answer the question clearly, rename it.

---

## Why Flat Semantic Names

The previous `ci-fast` / `ci-quality` / `ci-test` / `image-build` / `image-publish`
naming used prefixes to group related workflows. This was replaced because:

- Three separate CI workflows (`ci-fast`, `ci-quality`, `ci-test`) ran overlapping
  `./gradlew test` steps — wasting runner capacity on every PR
- `image-build` and `image-publish` as separate files created duplicate Docker publish
  runs on every semantic-release tag
- The `ci-failure-comment` workflow watched for a workflow named `"CI"` — no workflow
  had that name, so PR helper comments never fired

A single `ci.yml` named `"CI"` eliminates all three problems.

---

**Naming is architecture. Treat it accordingly.**
