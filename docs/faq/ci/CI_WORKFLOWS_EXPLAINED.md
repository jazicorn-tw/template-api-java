# What does each CI workflow do?

This article describes every GitHub Actions workflow in this project — when it
runs, what it checks, and what can skip or gate it.

---

## Workflow overview

| Workflow file | Name | Trigger |
| --- | --- | --- |
| `ci.yml` | CI | All PRs, push to `main`/`staging`, manual |
| `release.yml` | Release | All PRs and pushes to `main`/`staging`/`canary`, tag push, manual |
| `publish.yml` | Publish | Tag push `v*.*.*` |
| `security.yml` | Security | All PRs, push to `main`/`staging`, weekly schedule, manual |
| `changelog-guard.yml` | Changelog Guard | All PRs and pushes |
| `pr-helper.yml` | PR Helper | After CI run completes with failure |
| `doctor.yml` | Doctor | All PRs, push to `main`, manual |

---

## ci.yml — CI

**Triggers:** all PRs, push to `main`/`staging`, `workflow_dispatch`

Four parallel / sequenced jobs:

1. **`test`** — compile + `./gradlew test` with Testcontainers (requires Docker).
   - Docker sanity check (`docker version` / `docker info`)
   - Full `act` + Testcontainers compatibility env vars
   - SonarCloud: `./gradlew jacocoTestReport sonar` — gated by
     `ENABLE_SONAR != 'false'`; requires `SONAR_TOKEN`; skipped under `act`
   - Uploads test report artifact on failure

2. **`quality`** — Spotless + static analysis (no Docker, no Sonar, runs in
   parallel with `test` for fast feedback)
   - `spotlessCheck`
   - `checkstyleMain/Test`, `pmdMain/Test`, `spotbugsMain/Test` — gated by
     `ENABLE_STATIC_ANALYSIS != 'false'`

3. **`markdown-lint`** — runs `markdownlint-cli2 '**/*.md'` independently;
   gated by `ENABLE_MD_LINT != 'false'`

4. **`planning-lint`** — needs `test`; lints `IDEAS.md`, `TODO.md`, and
   `PROMOTION_CHECKLIST.md` using `scripts/planning/planning-lint.sh`

Named `"CI"` so that `pr-helper.yml` (`workflow_run: workflows: ["CI"]`)
correctly receives failure events and posts helper comments on PRs.

---

## release.yml — Release

**Triggers:** PRs targeting `main`/`staging`/`canary`, push to those
branches, tag push `v*.*.*`, `workflow_dispatch`

Three jobs, each with its own `if:` condition and minimal `permissions:`:

1. **`docker-build`** — Docker build check, no push; runs on PRs and branch
   pushes (skipped on tag push). Permissions: `contents: read`

2. **`helm-lint`** — `helm lint helm/app`; same trigger as `docker-build`.
   Permissions: `contents: read`

3. **`release`** — semantic-release; runs only on push to `main`/`canary` or
   manual dispatch, gated by `ENABLE_SEMANTIC_RELEASE=true`. Permissions:
   `contents: write`, `issues: write`, `pull-requests: write`, `packages: write`
   - GitHub App token via `tibdex/github-app-token`
   - Dry-run preview → publish (dry-run only under `act`)
   - Writes job summary with gate values and outcome

> Artifact publishing (Docker + Helm) is handled by `publish.yml` — see below.

See [`WHY_NO_RELEASE.md`](./WHY_NO_RELEASE.md) for the full release diagnosis
guide.

---

## publish.yml — Publish

**Triggers:** tag push `v*.*.*`

Two independent jobs, each gated by its own feature flag:

1. **`docker`** — builds and pushes the Docker image to GHCR; gated by
   `PUBLISH_DOCKER_IMAGE=true` + `CANONICAL_REPOSITORY` match.
   Permissions: `contents: read`, `packages: write`
   - Tag strategy: stable `v1.2.3` → `1.2.3`, `1.2`, `1`, `latest`;
     canary `v1.2.3-canary.1` → `1.2.3-canary.1`, `canary`

2. **`helm`** — packages and pushes the Helm chart as an OCI artifact to
   `ghcr.io/<owner>/charts`; gated by `PUBLISH_HELM_CHART=true` +
   `CANONICAL_REPOSITORY` match.
   Permissions: `contents: read`, `packages: write`

Kept separate from `release.yml` to avoid a `needs`-chain skip: when
triggered by a tag push, `release.yml`'s `release` job is skipped, which
caused a `publish` job inside `release.yml` to be skipped even with
`always()` in its `if` condition.

---

## security.yml — Security

**Triggers:** all PRs, push to `main`/`staging`, weekly schedule (Monday
03:00 UTC), `workflow_dispatch`

**Gated:** skipped when `ENABLE_CODEQL=false` or when running under `act`.

Single job:

- Initializes CodeQL for `java-kotlin` with the `security-and-quality` query
  suite
- Builds the project via CodeQL autobuild (no Docker required)
- Uploads results as SARIF to the **Security → Code scanning** tab

On PRs, CodeQL posts inline annotations on changed lines where issues are found.
The weekly schedule catches new vulnerability rules published between pushes.

**To disable:**

```text
Settings → Variables → Actions → ENABLE_CODEQL = false
```

---

## changelog-guard.yml — Changelog Guard

**Triggers:** all PRs and all pushes (no branch filter)

Prevents manual edits to `CHANGELOG.md`. Rules:

- **PRs** — any PR that modifies `CHANGELOG.md` fails
- **Pushes to non-`main` branches** — modification blocked
- **Pushes to `main`** — allowed only if the commit message matches
  `chore(release): X.Y.Z [skip ci]` and the author is a recognized bot

Can be disabled via `GUARD_RELEASE_ARTIFACTS=false` (repo variable).

---

## pr-helper.yml — PR Helper

**Triggers:** after a workflow named `"CI"` completes with a non-success result
on a pull request

Posts (or updates) a single comment on the PR linking to the First PR Smoke
Test checklist. Uses an idempotent marker so the comment is updated in place
rather than duplicated on every failure.

This workflow does not run any tests. It only writes a comment.

---

## doctor.yml — Doctor

**Triggers:** all PRs, push to `main`, `workflow_dispatch`

Runs `scripts/doctor.sh --json --allow-ci` and validates the output:

- Checks required JSON fields: `status`, `os`, `git_branch`, `java_major`,
  `docker_provider`, `warnings`, `errors`
- Fails if `status=fail`
- Emits GitHub annotations for each warning and error
- Uploads `build/doctor/doctor.json` as a build artifact (14-day retention)

Can be disabled via `ENABLE_DOCTOR_SNAPSHOT=false` (repo variable).

---

## Feature flags summary

Most workflows respect repository variables that let you disable expensive or
optional steps. See
[`docs/environment/ci/CI_FEATURE_FLAGS.md`](../../environment/ci/CI_FEATURE_FLAGS.md)
for the complete list.

| Variable | Default | Controls |
| --- | --- | --- |
| `ENABLE_CODEQL` | on | CodeQL analysis job in `security` |
| `ENABLE_STATIC_ANALYSIS` | on | Checkstyle/PMD/SpotBugs in `ci` |
| `ENABLE_SONAR` | on | SonarCloud analysis in `ci` |
| `ENABLE_MD_LINT` | on | markdownlint job in `ci` |
| `ENABLE_SEMANTIC_RELEASE` | off | Release job in `release` |
| `PUBLISH_DOCKER_IMAGE` | off | Docker publish in `publish` |
| `PUBLISH_HELM_CHART` | off | Helm publish in `publish` |
| `GUARD_RELEASE_ARTIFACTS` | on | CHANGELOG guard in `changelog-guard` |
| `ENABLE_DOCTOR_SNAPSHOT` | on | `doctor` workflow |

---

## Related

- [`WHY_NO_RELEASE.md`](./WHY_NO_RELEASE.md) —
  Diagnosing why a release was not created
- [`SONARCLOUD_EXPLAINED.md`](./SONARCLOUD_EXPLAINED.md) —
  SonarCloud setup and quality gate details
- [`docs/devops/BRANCH_FLOW.md`](../../devops/BRANCH_FLOW.md) —
  Which workflows trigger on which branches
- [`docs/environment/ci/CI_FEATURE_FLAGS.md`](../../environment/ci/CI_FEATURE_FLAGS.md) —
  Full feature flag reference
