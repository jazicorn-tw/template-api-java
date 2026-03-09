<!--
created_by:   jazicorn-tw
created_date: 2026-03-05
updated_by:   jazicorn-tw
updated_date: 2026-03-09
status:       active
tags:         [env, ci]
description:  "CI Feature Flags (GitHub Actions)"
-->
# 🔀 CI Feature Flags (GitHub Actions)

These variables control **when CI publishes artifacts or performs deployments**.

They allow emergency shutdowns and prevent accidental publishing from forks or non-canonical repos.

---

## ✅ Variables

```text
# Release gating
ENABLE_SEMANTIC_RELEASE   # true|false — allow push-based semantic-release from main
                          # (workflow_dispatch can override per-run)

# Docker image publishing (GHCR)
PUBLISH_DOCKER_IMAGE      # true|false — enable Docker publishing step (called after a release run)

# Helm chart publishing (OCI/GHCR or other)
PUBLISH_HELM_CHART        # true|false — enable Helm publishing step (called after a release run)

# Canonical publishing guard
CANONICAL_REPOSITORY      # <owner>/<repo> — only repo allowed to publish artifacts

# CI job/step feature flags (enabled when unset; set to 'false' to disable)
ENABLE_STATIC_ANALYSIS    # false — skip Checkstyle/PMD/SpotBugs step in CI Quality
ENABLE_SONAR              # false — skip Sonar cache + analysis steps in CI Quality
ENABLE_MD_LINT            # false — skip the entire markdown-lint job in CI Quality
ENABLE_DOCTOR_SNAPSHOT    # false — skip the entire doctor job in Doctor Snapshot
ENABLE_CODEQL             # false — skip the entire CodeQL analysis job

# Future / reserved
DEPLOY_ENABLED            # true|false — global deploy kill switch (future)
```

---

## 🧠 How CI feature flags work (enabled-by-default)

The five `ENABLE_*` CI flags above use an **enabled-by-default** pattern:

- **Unset** (no variable configured) → step/job **runs**
- **Set to `false`** → step/job is **skipped**
- **Set to any other value** (`true`, `1`, etc.) → step/job **runs**

This means a fresh repo with no variables configured behaves identically to one with all flags explicitly set to
`true`. Set a flag to `false` only when you want to opt out of that check (e.g., Sonar not yet configured, or
doctor too slow for a temporary branch).

---

## 🧠 How release gating works

The Release workflow runs on:

- `push` to `main` or `canary`
- manual `workflow_dispatch`

But the **release job only executes** when **either** condition is true:

- Manual run input: `enable_release == "true"`, **or**
- Repo variable: `ENABLE_SEMANTIC_RELEASE == "true"`

This ensures push-based releases are **opt-in**, while still enabling one-off manual runs.

---

## 📦 Publishing rules

Artifact publishing (Docker/Helm) is executed **only if all conditions are met**:

### 1) A release run is allowed

The release job must be allowed by the release gate above.

### 2) Feature flag is enabled

- Docker: `PUBLISH_DOCKER_IMAGE == "true"`
- Helm: `PUBLISH_HELM_CHART == "true"`

### 3) The repository is canonical

The workflow must run in the canonical repository (not a fork) where:

- `${{ github.repository }}` equals `CANONICAL_REPOSITORY`

> Why: forks can run workflows, but they must never publish official artifacts.

### 4) A release version is actually published

The publish steps should run **only when semantic-release publishes a version** (i.e., a new `vX.Y.Z` is created).

> Note: semantic-release may run and still publish nothing if there are **no releasable commits**.
> In that case, artifact publishing should be skipped.

---

## ✅ Recommended defaults

For most repos:

- `ENABLE_SEMANTIC_RELEASE=false` (enable only when ready)
- `PUBLISH_DOCKER_IMAGE=false` (set to `true` once `CANONICAL_REPOSITORY` is configured — publishing is wired)
- `PUBLISH_HELM_CHART=false` (set to `true` once `CANONICAL_REPOSITORY` is configured — publishing is wired)
- `CANONICAL_REPOSITORY=<owner>/<repo>` (always set)

---

## 🎯 Rationale

- Prevents accidental releases
- Allows instant shutdown without code changes
- Keeps release versioning decoupled from delivery
- Blocks artifact publishing from forks/non-canonical repos
