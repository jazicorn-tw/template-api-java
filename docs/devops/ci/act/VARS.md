<!--
created_by:   jazicorn-tw
created_date: 2026-03-05
updated_by:   jazicorn-tw
updated_date: 2026-03-09
status:       active
tags:         [devops, ci, act]
description:  "`.vars` — Repository Variables"
-->
# 🔧 `.vars` — Repository Variables

This document explains the purpose and usage of the `.vars` file in this repository.

---

## 📄 What is `.vars`?

`.vars` is a **local configuration file** used to define **non-secret, repository-scoped variables**
that influence CI/CD behavior, release gates, and feature toggles.

It is designed to mirror **GitHub Repository Variables** (`Settings → Variables`) so that:

- Local runs behave like CI
- Feature flags are explicit and documented
- No secrets are stored in source control

---

## 🧭 Design Principles

- **Non-secret only** (booleans, names, toggles)
- **Explicit defaults**
- **CI-parity** with GitHub Actions `vars.*`
- Safe to commit **only as `.vars.example`**

---

## 📂 Files

| File            | Purpose                                      |
| --------------- | -------------------------------------------- |
| `.vars.example` | Template documenting all supported variables |
| `.vars`         | Local developer override (gitignored)        |

---

## 🧪 How it’s used

The Makefile and CI scripts load `.vars` to simulate GitHub Actions behavior locally.

Example:

```bash
ENABLE_SEMANTIC_RELEASE=false
PUBLISH_DOCKER_IMAGE=true
```

In GitHub Actions, these map to:

```yaml
vars.ENABLE_SEMANTIC_RELEASE
vars.PUBLISH_DOCKER_IMAGE
```

---

## 🔀 Common Variables

### Release & publishing (disabled by default — must opt in)

| Variable                  | Default   | Description                               |
| ------------------------- | --------- | ----------------------------------------- |
| `ENABLE_SEMANTIC_RELEASE` | `false`   | Gate semantic-release execution           |
| `PUBLISH_DOCKER_IMAGE`    | `false`   | Allow Docker image publishing             |
| `PUBLISH_HELM_CHART`      | `false`   | Allow Helm chart publishing               |
| `CANONICAL_REPOSITORY`    | _(unset)_ | `owner/repo` allowed to publish artifacts |

### Release artifact guard (enabled by default — opt out with `false`)

| Variable                  | Default | Description                                         |
| ------------------------- | ------- | --------------------------------------------------- |
| `GUARD_RELEASE_ARTIFACTS` | `true`  | Enforce release artifact rules (CHANGELOG.md guard) |

### CI job/step feature flags (enabled by default — opt out with `false`)

| Variable                 | Default | Description                                |
| ------------------------ | ------- | ------------------------------------------ |
| `ENABLE_STATIC_ANALYSIS` | enabled | Checkstyle/PMD/SpotBugs step in CI Quality |
| `ENABLE_SONAR`           | enabled | Sonar cache + analysis steps in CI Quality |
| `ENABLE_MD_LINT`         | enabled | Markdown-lint job in CI Quality            |
| `ENABLE_DOCTOR_SNAPSHOT` | enabled | Doctor snapshot job                        |

### Future / reserved

| Variable         | Default | Description               |
| ---------------- | ------- | ------------------------- |
| `DEPLOY_ENABLED` | `false` | Global deploy kill-switch |

---

## ⚠️ Important Notes

- `.vars` **must not contain secrets**
- Secrets belong in `.secrets` / GitHub Secrets
- CI remains authoritative — `.vars` is for **local parity only**

---

## ✅ Recommended Workflow

```bash
cp .vars.example .vars
$EDITOR .vars
make run-ci
```

This ensures your local checks behave exactly like GitHub Actions.
