<!--
created_by:   jazicorn-tw
created_date: 2026-03-05
updated_by:   jazicorn-tw
updated_date: 2026-03-09
status:       active
tags:         [env]
description:  "`act` — Environment Variables Reference"
-->
<!-- markdownlint-disable-file MD036 -->

# 🧪 `act` — Environment Variables Reference

This document lists all environment variables commonly used when running
GitHub Actions locally via **`act`**.

---

## ❓ What is `act`?

`act` runs GitHub Actions workflows locally using Docker, enabling fast feedback
before pushing to CI.

This repo treats `act` as a **first-class CI simulator**.

---

## 📍 Sources of Environment Variables

`act` environment variables may come from:

1. `.env` (application runtime)
2. `.secrets` (GitHub Secrets simulation)
3. `.vars` (GitHub Variables simulation)
4. `.actrc` (act configuration)
5. CLI `-e` or `--env` flags

---

## 🔐 Secrets (GitHub Secrets)

Loaded from `.secrets` and mapped to `secrets.*`.

Examples:

```text
GH_APP_ID
GH_APP_PRIVATE_KEY
GITHUB_TOKEN
```

Usage in workflows:

```yaml
secrets.GH_APP_ID
```

---

## 🔧 Variables (GitHub Variables)

Loaded from `.vars` and mapped to `vars.*`.

Examples:

```text
ENABLE_SEMANTIC_RELEASE
PUBLISH_DOCKER_IMAGE
```

Usage in workflows:

```yaml
vars.ENABLE_SEMANTIC_RELEASE
```

---

## ⚙️ Built-in `act` Environment Variables

| Variable            | Description                          |
| ------------------- | ------------------------------------ |
| `ACT`               | Always `true` when running under act |
| `GITHUB_ACTIONS`    | `true` (CI parity)                   |
| `CI`                | `true`                               |
| `RUNNER_OS`         | Typically `Linux`                    |
| `RUNNER_ARCH`       | `X64`                                |
| `GITHUB_EVENT_NAME` | Event triggering the workflow        |
| `GITHUB_REF_NAME`   | Branch or tag name                   |
| `GITHUB_SHA`        | Commit SHA                           |

---

## 🧪 Recommended `.actrc`

```text
-P ubuntu-latest=catthehacker/ubuntu:full-latest
--platform linux/amd64
--container-options "--user 0:0"
```

---

## ✅ Best Practices

- Keep `.actrc` **machine-specific**
- Keep `.vars` **non-secret**
- Keep `.secrets` **gitignored**
- Treat GitHub CI as the source of truth

---

## 🚦 Sanity Check

```bash
act -l
act pull_request
```

If it works in `act`, it should work in CI.
