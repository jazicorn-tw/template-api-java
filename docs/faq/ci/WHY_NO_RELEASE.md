<!--
created_by:   jazicorn-tw
created_date: 2026-03-07
updated_by:   jazicorn-tw
updated_date: 2026-03-09
status:       active
tags:         [faq, ci]
description:  "Why didn't my commit create a release?"
-->
# Why didn't my commit create a release?

This article explains why semantic-release may not produce a new version after
a merge to `main` or `canary`, and how to diagnose which condition is blocking it.

---

## The short answer

A release requires **all three** conditions to be true at the same time:

1. The release workflow **ran**
2. It found at least one **releasable commit type** (`feat:`, `fix:`, or `perf:`)
3. It ran in the **canonical repository** (not a fork)

If any one of these is false, no release is created. This is intentional.

---

## Condition 1 — Did the workflow run?

The release workflow is **gated off by default**. It will not run on every push
to `main` — you must explicitly enable it.

Check either:

```bash
# GitHub repo → Settings → Variables → ENABLE_SEMANTIC_RELEASE
ENABLE_SEMANTIC_RELEASE=true
```

or trigger it manually via workflow dispatch with `enable_release=true`.

> ⚠️ If `ENABLE_SEMANTIC_RELEASE` is unset or `false`, the workflow runs but
> the release job is skipped. Check the **Release Summary** step in the
> Actions output — it will say "Release skipped (gate disabled)".

---

## Condition 2 — Were there releasable commits?

semantic-release only bumps the version for specific commit types.

### Releasable (trigger a version bump)

| Commit type               | Version bump              |
| ------------------------- | ------------------------- |
| `feat:`                   | Minor (`0.1.0` → `0.2.0`) |
| `fix:`                    | Patch (`0.1.0` → `0.1.1`) |
| `perf:`                   | Patch (`0.1.0` → `0.1.1`) |
| `BREAKING CHANGE:` footer | Major (`0.1.0` → `1.0.0`) |

### Non-releasable (no version bump)

| Commit type | Result     |
| ----------- | ---------- |
| `docs:`     | No release |
| `chore:`    | No release |
| `refactor:` | No release |
| `test:`     | No release |
| `ci:`       | No release |
| `style:`    | No release |
| `build:`    | No release |

**The most common miss:** squash-merging a PR and leaving the squash commit
message as `feat: my feature (#42)` is correct. But if the squash defaults to
the branch name (`my-feature-branch`) or a non-Conventional format, no commit
type is detected and no release happens.

Always verify the squash commit message before merging.

---

## Condition 3 — Is this the canonical repository?

Artifact publishing (Docker image, Helm chart) is blocked on forks. Semantic-release
itself can still run, but artifact steps are skipped if:

```text
${{ github.repository }} != CANONICAL_REPOSITORY
```

Check **Settings → Variables → Actions** and confirm `CANONICAL_REPOSITORY` matches
your current repo name exactly (case-sensitive, e.g. `acme/my-api`).

> ⚠️ If you renamed the repo after initial setup, update `CANONICAL_REPOSITORY`
> to match the new name.

---

## Quick diagnosis checklist

```text
Did the release workflow run at all?
 ├─ No  → ENABLE_SEMANTIC_RELEASE is unset/false → enable it
 └─ Yes
     └─ Did semantic-release find releasable commits?
         ├─ No  → Check the squash merge commit message type
         └─ Yes
             └─ Did artifacts publish?
                 ├─ No  → Check CANONICAL_REPOSITORY + PUBLISH_* flags
                 └─ Yes → ✅ Everything worked
```

---

## Dry run (preview without side effects)

Before enabling releases for real, run a dry run locally to see what version
would be created:

```bash
npm ci
npx semantic-release --dry-run
```

Or via Make:

```bash
make release-dry-run
```

---

## Related

- [`docs/devops/RELEASE.md`](../../devops/RELEASE.md) — Full release system design and gating
- [`docs/environment/ci/CI_FEATURE_FLAGS.md`](../../environment/ci/CI_FEATURE_FLAGS.md) —
  Feature flags for release and publishing gates
- [`docs/commit/COMMITIZEN.md`](../../commit/COMMITIZEN.md) — Conventional Commits reference
