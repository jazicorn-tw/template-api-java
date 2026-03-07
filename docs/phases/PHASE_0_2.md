# 🔰 Phase 0.2 — CI/CD, Release Automation & Container Publishing

> Part of [Phase 0](PHASE_0.md). Covers the delivery pipeline: GitHub Actions,
> semantic-release, Docker image publishing, and Helm.

---

## ✅ Purpose

Every commit pushed to `main` should be releasable without manual steps.
Phase 0.2 wires the full delivery pipeline before domain work begins:

* CI runs automatically on every push and pull request
* Releases are versioned, tagged, and published by automation — not humans
* The application ships as a Docker image and a Kubernetes Helm chart

---

## 🚀 CI/CD Pipelines

Six GitHub Actions workflows live in `.github/workflows/`:

| Workflow | Trigger | Purpose |
| -------- | ------- | ------- |
| `ci` | push / PR | Compile, tests, Spotless, static analysis, SonarCloud, markdown lint |
| `release` | push / PR / tag push | Docker build check, Helm lint, semantic-release, Docker + Helm publish |
| `security` | push / PR / weekly | CodeQL static security analysis |
| `changelog-guard` | push / PR | Prevent manual edits to `CHANGELOG.md` |
| `pr-helper` | after CI failure on PR | Post helper comment linking to smoke test checklist |
| `doctor` | push to `main` / PR | Environment snapshot and validation |

**Gradle caching** is handled by `gradle/actions/setup-gradle@v4`.
`act` is detected via `github.actor != 'nektos/act'` to skip caching steps when
running workflows locally.

---

## 📦 Release Automation (semantic-release)

Releases are fully automated via **semantic-release** (`.releaserc.cjs`).

**How it works:**

1. A `feat:` or `fix:` commit merges to `main`
2. The `release` workflow runs `npx semantic-release`
3. semantic-release determines the next version from Conventional Commits:
   * `fix:` → patch bump (e.g. `v1.2.1` → `v1.2.2`)
   * `feat:` → minor bump (e.g. `v1.2.1` → `v1.3.0`)
   * `feat!:` or `BREAKING CHANGE:` → major bump
4. `CHANGELOG.md` is updated automatically
5. A GitHub Release is created with formatted release notes
6. The commit is tagged (e.g. `v1.3.0`)
7. The `release` workflow's `publish` job is triggered by the new tag

**Commit format** is enforced by the `commit-msg` pre-commit hook and commitizen.
See `docs/tooling/CONVENTIONAL_COMMITS.md`.

**Preview a release without publishing:**

```bash
make release-dry-run
```

---

## 🐳 Docker Image Publishing

The `release` workflow's `publish` job builds and pushes a Docker image to GHCR on
every release tag:

```text
ghcr.io/<owner>/{{project-name}}:<version>
ghcr.io/<owner>/{{project-name}}:latest
```

The `Dockerfile` uses a multi-stage build:

* Stage 1: Gradle build (produces the fat JAR)
* Stage 2: Minimal JRE runtime image

The same `release` workflow also runs a Docker build check (no push) on every
PR and branch push to catch `Dockerfile` issues before a release tag is created.

---

## ☸️ Helm Chart (Kubernetes)

The `helm/` directory provides a production-ready Kubernetes deployment:

| Template | Purpose |
| -------- | ------- |
| `deployment.yaml` | `Deployment` with configurable replicas and resource limits |
| `service.yaml` | `ClusterIP` / `LoadBalancer` service |
| `hpa.yaml` | `HorizontalPodAutoscaler` |
| `serviceaccount.yaml` | `ServiceAccount` with RBAC annotations |

Liveness and readiness probes are wired to `/actuator/health`.

The chart is published to GHCR alongside the Docker image on every release.

---

## 🔜 Next

← Back to [Phase 0.1 — Skeleton](PHASE_0_1.md) |
Next: [Phase 0.3 — Quality Gates & Developer Tooling](PHASE_0_3.md)
