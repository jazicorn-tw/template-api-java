# FAQ

Short, focused documents that explain *why* things work the way they do
in this project — and what to do when they go wrong.

These are not reference docs. Each one answers a specific question a
contributor is likely to have after their first few days.

---

## Contents

| Document | Answers |
| -------- | ------- |
| [`ACTUATOR_HEALTH_SECURITY.md`](./ACTUATOR_HEALTH_SECURITY.md) | Why is `show-details=when-authorized`? What does `always` expose and why is it dangerous? |
| [`EXECUTABLE_BITS_EXPLAINED.md`](./EXECUTABLE_BITS_EXPLAINED.md) | Why does Git track executable bits? Why does the checker complain even when the script runs? |
| [`FLYWAY_CLEAN_DISABLED.md`](./FLYWAY_CLEAN_DISABLED.md) | Why is `flyway.clean-disabled=true`? What does `flyway:clean` do and how do I reset locally? |
| [`FLYWAY_MIGRATIONS_EXPLAINED.md`](./FLYWAY_MIGRATIONS_EXPLAINED.md) | Why are all tables in V1? How do I add a migration? What happens if I edit one? How do I reset? |
| [`QUALITY_GATE_EXPLAINED.md`](./QUALITY_GATE_EXPLAINED.md) | What do Spotless / Checkstyle / PMD / SpotBugs / markdownlint errors mean, and how do I fix them? |
| [`SPRING_APPLICATION_NAME.md`](./SPRING_APPLICATION_NAME.md) | Why is `spring.application.name` set to `{{project-name}}`? What breaks if you forget to replace it? |
| [`TESTCONTAINERS_EXPLAINED.md`](./TESTCONTAINERS_EXPLAINED.md) | Why must Docker run for tests? Why is first run slow? What is BaseIntegrationTest and why must I extend it? |

---

📄 Stuck on something not listed here? Check
[`docs/onboarding/COMMON_FIRST_DAY_FAILURES.md`](../onboarding/COMMON_FIRST_DAY_FAILURES.md)
or open an issue — docs are part of the system.
