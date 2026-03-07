# How does SonarCloud work in this project?

This article explains what SonarCloud does, when it runs, what it reports,
and how to set it up for a repository forked from this template.

---

## What SonarCloud does

SonarCloud performs static analysis on your Java source code and test coverage
data. It tracks:

- **Bugs** — code patterns that are likely to fail at runtime
- **Vulnerabilities** — security issues (e.g., injection risks, insecure APIs)
- **Code smells** — maintainability problems that accumulate as technical debt
- **Coverage** — line and branch coverage from JaCoCo reports
- **Duplication** — blocks of repeated code

Results appear in the SonarCloud dashboard and, on pull requests, as inline
comments on changed lines.

---

## When it runs

SonarCloud analysis is part of the `CI` workflow
(`.github/workflows/ci.yml`), in the `test` job. It is gated by two conditions:

```yaml
if: ${{ vars.ENABLE_SONAR != 'false' && github.actor != 'nektos/act' }}
```

| Condition | Effect |
| --------- | ------ |
| `ENABLE_SONAR` unset or `'true'` | Analysis runs |
| `ENABLE_SONAR=false` | Analysis is skipped (no error) |
| Running under `act` (local CI) | Analysis is always skipped |

If `SONAR_TOKEN` is not set, the step emits a warning and exits cleanly — it
does not block the build.

---

## What runs before analysis

The Sonar step runs after `./gradlew test` completes in the same `test` job,
then produces and uploads the coverage report:

```bash
./gradlew jacocoTestReport sonar --no-daemon --no-configuration-cache --info
```

Running Sonar in the `test` job (rather than a separate quality job) avoids
re-running the full test suite a second time. JaCoCo generates
`build/reports/jacoco/test/jacocoTestReport.xml`, which the Sonar Gradle
plugin reads automatically.

---

## How to set it up

### 1. Create a SonarCloud project

1. Go to [sonarcloud.io](https://sonarcloud.io) and sign in with GitHub
2. Add your repository as a new project
3. Choose **Gradle** as the build system
4. Copy the `sonar.projectKey` and `sonar.organization` values shown

### 2. Configure `build.gradle`

```groovy
sonar {
    properties {
        property "sonar.projectKey",   "your-org_your-repo"
        property "sonar.organization", "your-org"
        property "sonar.host.url",     "https://sonarcloud.io"
    }
}
```

These values are already stubbed in `build.gradle` — replace the placeholders.

### 3. Add the repository secret

In **Settings → Secrets and variables → Actions**, add:

```text
SONAR_TOKEN = <token from SonarCloud>
```

The token is generated under **My Account → Security** in SonarCloud.

### 4. Verify

Push a branch and open a PR. The `CI` workflow's `test` job runs SonarCloud
analysis and posts a quality gate result on the PR.

---

## PR decoration

When a PR is open, SonarCloud posts:

- A quality gate badge (pass/fail) in the PR checks
- Inline comments on changed lines that introduce new issues

The `CI` workflow requests `pull-requests: write` permission for this
reason.

---

## Quality gate

SonarCloud enforces a **quality gate** — a set of conditions that new code
must meet to pass. The default Sonar Way gate checks:

| Metric | Threshold |
| ------ | --------- |
| Coverage on new code | ≥ 80 % |
| Duplicated lines on new code | ≤ 3 % |
| Maintainability rating on new code | A |
| Reliability rating on new code | A |
| Security rating on new code | A |

A failing quality gate marks the PR check as failed but does not block merging
by default unless branch protection requires it.

---

## Disabling SonarCloud

If you are not ready to configure SonarCloud, set the repository variable:

```text
ENABLE_SONAR = false
```

The analysis step is skipped silently. All other quality checks (Spotless,
Checkstyle, PMD, SpotBugs, markdownlint) continue to run.

---

## Related

- [`QUALITY_GATE_EXPLAINED.md`](./QUALITY_GATE_EXPLAINED.md) —
  Local quality checks (Spotless, Checkstyle, PMD, SpotBugs)
- [`docs/environment/ci/CI_FEATURE_FLAGS.md`](../environment/ci/CI_FEATURE_FLAGS.md) —
  Full list of CI feature flags including `ENABLE_SONAR`
- [`CI_WORKFLOWS_EXPLAINED.md`](./CI_WORKFLOWS_EXPLAINED.md) —
  When each workflow runs and what it checks
