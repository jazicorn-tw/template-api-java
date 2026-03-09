<!--
created_by:   jazicorn-tw
created_date: 2026-03-05
updated_by:   jazicorn-tw
updated_date: 2026-03-09
status:       active
tags:         [faq]
description:  "FAQ"
-->
# FAQ

Short, focused documents that explain *why* things work the way they do
in this project — and what to do when they go wrong.

These are not reference docs. Each one answers a specific question a
contributor is likely to have after their first few days.

---

## `ci/` — CI/CD & Release

| Document                                                          | Answers                                                                                                         |
| ----------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------- |
| [`CI_WORKFLOWS_EXPLAINED.md`](./ci/CI_WORKFLOWS_EXPLAINED.md)     | What does each GitHub Actions workflow do, when does it run, and how do feature flags control it?               |
| [`GITHUB_APP_KEY_EXPLAINED.md`](./ci/GITHUB_APP_KEY_EXPLAINED.md) | Why are there two key formats (raw PEM vs Base64)? What goes in the GitHub secret vs the local `.secrets` file? |
| [`QUALITY_GATE_EXPLAINED.md`](./ci/QUALITY_GATE_EXPLAINED.md)     | What do Spotless / Checkstyle / PMD / SpotBugs / markdownlint errors mean, and how do I fix them?               |
| [`SONARCLOUD_EXPLAINED.md`](./ci/SONARCLOUD_EXPLAINED.md)         | What does SonarCloud check, how do I set it up, and how do I disable it for a new fork?                         |
| [`WHY_NO_RELEASE.md`](./ci/WHY_NO_RELEASE.md)                     | Why didn't my commit create a release? What three conditions must all be true for a release to publish?         |

## `database/` — Database & Migrations

| Document                                                                      | Answers                                                                                                  |
| ----------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------- |
| [`FLYWAY_CLEAN_DISABLED.md`](./database/FLYWAY_CLEAN_DISABLED.md)             | Why is `flyway.clean-disabled=true`? What does `flyway:clean` do and how do I reset locally?             |
| [`FLYWAY_MIGRATIONS_EXPLAINED.md`](./database/FLYWAY_MIGRATIONS_EXPLAINED.md) | Why are all tables in V1? How do I add a migration? What happens if I edit one? How do I reset?          |
| [`NO_H2_EXPLAINED.md`](./database/NO_H2_EXPLAINED.md)                         | Why is H2 banned? What goes wrong with in-memory databases and why does this project use Testcontainers? |

## `dx/` — Developer Experience

| Document                                                            | Answers                                                                                                     |
| ------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------- |
| [`EXECUTABLE_BITS_EXPLAINED.md`](./dx/EXECUTABLE_BITS_EXPLAINED.md) | Why does Git track executable bits? Why does the checker complain even when the script runs?                |
| [`PRE_ADD_HOOK_EXPLAINED.md`](./dx/PRE_ADD_HOOK_EXPLAINED.md)       | How does the `git add` wrapper work? What does it check, how do I skip it, and why does markdownlint abort? |

## `spring/` — Spring & Application Config

| Document                                                              | Answers                                                                                              |
| --------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------- |
| [`ACTUATOR_HEALTH_SECURITY.md`](./spring/ACTUATOR_HEALTH_SECURITY.md) | Why is `show-details=when-authorized`? What does `always` expose and why is it dangerous?            |
| [`SPRING_APPLICATION_NAME.md`](./spring/SPRING_APPLICATION_NAME.md)   | Why is `spring.application.name` set to `{{project-name}}`? What breaks if you forget to replace it? |

## `testing/` — Testing

| Document                                                               | Answers                                                                                                     |
| ---------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------- |
| [`TESTCONTAINERS_EXPLAINED.md`](./testing/TESTCONTAINERS_EXPLAINED.md) | Why must Docker run for tests? Why is first run slow? What is BaseIntegrationTest and why must I extend it? |

---

📄 Stuck on something not listed here? Check
[`docs/onboarding/COMMON_FIRST_DAY_FAILURES.md`](../onboarding/COMMON_FIRST_DAY_FAILURES.md)
or open an issue — docs are part of the system.
