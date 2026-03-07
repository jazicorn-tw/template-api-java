# Why `spring.flyway.clean-disabled=true`

This article explains what `flyway:clean` does, why Spring Boot enables it by default,
and why this template explicitly disables it — so you understand the setting before
deciding to change it.

---

## What `spring.flyway.clean-disabled` controls

| Value | Effect |
| ----- | ------ |
| `true` | `flyway:clean` is **blocked** — running it throws an error |
| `false` | `flyway:clean` is **allowed** — running it drops everything |

Spring Boot's default is `false` (clean is allowed). This template overrides it to `true`.

---

## What `flyway:clean` actually does

`flyway:clean` drops every schema object that Flyway manages — tables, sequences, indexes,
views — in a single operation. It does not prompt. It does not ask for confirmation.
It succeeds silently and the data is gone.

```bash
# This destroys your database in one shot — no undo without a backup
./gradlew flywayClean
```

The intent is to give you a blank slate before re-running migrations. Locally, that is
sometimes useful. In production or on any shared database, it is catastrophic.

---

## Why Spring Boot ships `clean-disabled=false`

Spring Boot 2.x left `flywayClean` enabled for developer convenience — it makes local
resets trivial. Starting in Spring Boot 3, the recommended default shifted toward
`clean-disabled=true`, but the framework still ships `false` to avoid breaking existing
setups that rely on `flywayClean` in local scripts.

The result is a footgun: every Spring Boot project that does not explicitly set
`clean-disabled=true` is one mistyped Gradle command away from an empty database.

---

## Why this template sets it to `true`

> ⚠️ There is no meaningful reason to leave `flyway:clean` enabled in a production-bound
> service. The risk — accidental data loss — is asymmetric: the downside is catastrophic,
> the upside (slightly easier local resets) is trivially solved another way.

This template sets `clean-disabled=true` so that:

- A developer who accidentally runs `./gradlew flywayClean` gets an error, not a wiped database
- The setting propagates to production without requiring an environment override
- Forks and derivatives start from a safe default

---

## Resetting your local database (the safe way)

If you need to wipe and rebuild your local database, use Docker instead of `flyway:clean`:

```bash
# Stop the container and delete its volume (local data only)
docker compose down -v

# Restart — Flyway re-runs all migrations on boot
docker compose up -d postgres
./gradlew bootRun
```

This achieves the same result as `flyway:clean` + re-migrate, without touching any
production setting.

---

## If you have a legitimate use case for `flyway:clean`

Some teams use `flyway:clean` in CI reset scripts or local seed pipelines. If you have
that need, enable it via an environment variable override rather than changing the
default in `application.properties`:

```properties
# application-local.properties (not committed, not active in prod)
spring.flyway.clean-disabled=false
```

Or pass it directly to Gradle:

```bash
./gradlew flywayClean -Dspring.flyway.clean-disabled=false
```

> ⚠️ Never enable `flyway:clean` in `application.properties` directly.
> Never run it against a shared or production database.
> Always treat it as a local-only operation.

---

## Related

- [`FLYWAY_MIGRATIONS_EXPLAINED.md`](./FLYWAY_MIGRATIONS_EXPLAINED.md) —
  How migrations work, versioning rules, and adding new ones
- [`docs/adr/ADR-002-testcontainers.md`](../adr/ADR-002-testcontainers.md) —
  Why Testcontainers is used instead of a shared test database
- [`docs/devops/UNDO_ACCIDENTAL_RELEASE.md`](../devops/UNDO_ACCIDENTAL_RELEASE.md) —
  Recovery steps for other irreversible operations
