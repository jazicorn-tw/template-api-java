<!--
created_by:   jazicorn-tw
created_date: 2026-03-05
updated_by:   jazicorn-tw
updated_date: 2026-03-09
status:       active
tags:         [env]
description:  "ENV Spec — Remote Environments (CI / Hosted Platforms)"
-->
<!-- markdownlint-disable-file MD036 -->

# 🌐 ENV Spec — Remote Environments (CI / Hosted Platforms)

This document defines **environment variables and behavior that apply only to
_remote_ environments**, such as:

- GitHub Actions (CI)
- Render (managed hosting)
- AWS / cloud platforms
- Future Kubernetes deployments

It intentionally **excludes local-only configuration** (Docker Desktop, Colima,
`.env` files, etc.).

> **Authoritative scope**
> This document is a **normative extension of `ENV_SPEC.md`**.
> If a variable appears here, it is assumed to be set by a platform,
> not by a developer’s local machine.

---

## 🧭 Design principles

- Remote environments are **non-interactive**
- Configuration is **injected, not discovered**
- Secrets are **always platform-managed**
- Defaults are **fail-closed**
- CI is **stricter than local development**
- CI must be able to explain _why_ an action did or did not occur

---

## 🔀 CI & Platform Feature Flags

These variables control **whether CI performs irreversible actions** such as
publishing artifacts, cutting releases, or deploying infrastructure.

```text
# Release control (disabled by default — must opt in)
ENABLE_SEMANTIC_RELEASE   # true|false — allow semantic-release execution on main
                          # (manual workflow_dispatch may override per run)

# Artifact publishing (disabled by default — must opt in)
PUBLISH_DOCKER_IMAGE      # true|false — allow Docker image publishing
PUBLISH_HELM_CHART        # true|false — allow Helm chart publishing

# Safety / scope
CANONICAL_REPOSITORY      # <owner>/<repo> — only repo allowed to publish artifacts

# Release artifact guard (enabled by default — set to 'false' to disable)
GUARD_RELEASE_ARTIFACTS   # true|false — enforce CHANGELOG.md authorship rules

# CI job/step feature flags (enabled by default — set to 'false' to skip)
ENABLE_STATIC_ANALYSIS    # false — skip Checkstyle/PMD/SpotBugs in CI Quality
ENABLE_SONAR              # false — skip Sonar cache + analysis in CI Quality
ENABLE_MD_LINT            # false — skip markdown-lint job in CI Quality
ENABLE_DOCTOR_SNAPSHOT    # false — skip doctor snapshot job

# Deployment (future)
DEPLOY_ENABLED            # true|false — global deployment kill switch
```

### Rules

- **Release and publishing flags** are disabled by default — must be explicitly set to `true`
- **CI job/step flags** are enabled by default — set to `false` to opt out
- Artifact publishing is **never allowed** from non-canonical repositories
- Forks may run CI safely but can never publish

---

## 🧠 CI Gating Semantics (Important)

### Release gating

The release workflow evaluates release intent explicitly:

A release job may run **only if**:

- `ENABLE_SEMANTIC_RELEASE=true`, **or**
- a manual `workflow_dispatch` run sets `enable_release=true`

If neither is true, the release job is skipped with an explanatory summary.

### Publishing gating (job-level)

Publishing occurs in a **separate CI job** and requires **all** of the following:

1. A release version (`vX.Y.Z`) was actually published
2. The workflow is running in the canonical repository
3. The relevant publish flag is enabled

```yaml
github.repository == vars.CANONICAL_REPOSITORY
```

If any condition fails:

- publishing is skipped
- a **warning summary** is emitted explaining why

---

## 🧾 CI Job Summaries (Observability)

Release-related workflows emit **human-readable Job Summaries** in GitHub Actions.

### Release job summary includes

- Trigger (push vs manual)
- Branch and repository
- Release gate values
- **Dry-run version preview**
- Final outcome (published / skipped)

### Publish job summary includes

- Canonical repository check (pass/fail)
- Published version (if any)
- Docker / Helm enablement
- Explicit explanation when publishing is skipped

These summaries are the **primary debugging surface** for CI behavior.

---

## 🧪 CI Runtime (GitHub Actions)

These variables are expected to exist **only in CI**.

```text
CI                      # true — set automatically by CI runners
GITHUB_ACTIONS          # true — GitHub Actions environment
GITHUB_REF              # branch or tag ref
GITHUB_REF_NAME         # short ref name
GITHUB_SHA              # commit SHA
GITHUB_REPOSITORY       # owner/repo
```

Notes:

- These values must **never** be relied on in application runtime code
- They are valid **only during workflow execution**
- Application logic must not branch on CI-specific variables

---

## ☁️ Hosted Runtime Platforms (Render / AWS / Cloud)

Variables typically injected by managed hosting platforms.

```text
PORT                    # platform-provided port (Render)
RENDER                  # true — Render environment indicator
AWS_REGION              # AWS region (if applicable)
```

Rules:

- Platform-provided ports **must be respected**
- Applications must not assume fixed ports in production
- Presence-based flags (`RENDER=true`) are acceptable **for diagnostics only**

---

## 🗄️ Managed Databases (Remote)

Remote databases are **always external** to the application process.

```text
SPRING_DATASOURCE_URL        # JDBC URL (often includes SSL)
SPRING_DATASOURCE_USERNAME  # DB user
SPRING_DATASOURCE_PASSWORD  # DB password (secret)
```

### SSL expectations

- Remote databases **usually require SSL**
- SSL configuration should be embedded in the JDBC URL
- Do not rely on local trust stores or filesystem certs

---

## 🔐 Secrets (Remote-only)

All secrets in remote environments must be:

- injected via platform secret managers
- non-printable and non-loggable
- rotated without code changes

Common examples:

```text
JWT_SECRET
DATABASE_PASSWORD
GH_APP_PRIVATE_KEY
GHCR_TOKEN
```

Rules:

- Secrets must never appear in logs or summaries
- CI summaries must redact or avoid secret-derived values

---

## 🩺 Health & Probes (Remote)

Remote platforms depend on **explicit health signals**.

```text
MANAGEMENT_ENDPOINT_HEALTH_PROBES_ENABLED  # true in orchestrated envs
MANAGEMENT_ENDPOINTS_WEB_EXPOSURE_INCLUDE  # usually health,info
```

Rules:

- Health endpoints must be reachable without auth (platform-scoped)
- Failure to report health should prevent traffic routing
- Health misconfiguration is considered a deployment failure

---

## 🚫 Explicitly not allowed

The following must **never** be required in remote environments:

- `.env` files
- interactive prompts
- host-specific paths
- Docker Desktop / Colima assumptions
- local filesystem secrets

---

## 🔗 Related documents

- `ENV_SPEC.md` — Authoritative variable specification
- `ENV_QUICK_REFERENCE.md` — High-level index
- `CI_FEATURE_FLAGS.md` — Detailed CI gating behavior
- `ENV_SPEC.md` — Full variable matrix (local + remote)
- `PLATFORM_NOTES.md` — Platform-specific nuances

---

## Summary

- This spec governs **remote, non-local environments**
- CI and hosted platforms inject configuration
- Releasing, publishing, and deployment are always **opt-in**
- Canonical-repo enforcement prevents unsafe publishing
- CI always explains _why_ an action did or did not occur
