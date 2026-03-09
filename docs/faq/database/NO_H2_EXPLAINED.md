<!--
created_by:   jazicorn-tw
created_date: 2026-03-07
updated_by:   jazicorn-tw
updated_date: 2026-03-09
status:       active
tags:         [faq, db]
description:  "Why can't I use H2 or an in-memory database for tests?"
-->
# Why can't I use H2 or an in-memory database for tests?

This article explains why this project does not support H2, SQLite, or any
in-memory database for tests — and why that constraint produces better software.

---

## The short answer

This project runs **PostgreSQL everywhere**: local development, tests, CI, and
production. In-memory databases are explicitly banned. This is ADR-001.

---

## What goes wrong with H2

H2 is a popular choice for Spring Boot tutorials because tests run fast and
Docker is not required. In a production-bound service, however, H2 consistently
causes problems:

### SQL dialect differences

PostgreSQL and H2 have different SQL dialects. Queries, functions, and operators
that work in H2 may not exist or behave differently in PostgreSQL.

```sql
-- Works in H2, fails in PostgreSQL (different boolean handling)
WHERE active = 1

-- Works in PostgreSQL, not supported in H2
WHERE data @> '{"key": "value"}'::jsonb
```

### Constraint enforcement

H2 is permissive about some constraint violations that PostgreSQL enforces strictly.
A unique constraint or foreign key that H2 allows through will blow up in production.

### Transaction semantics

PostgreSQL's transaction isolation and locking behavior differs from H2. Race
conditions and deadlocks that are latent in production may not surface in H2 tests.

### The result

> ❌ "All tests pass in H2 → Merge to main → Fails in production"

This pattern is the reason the project bans H2 outright. The cost of discovering
database issues late is orders of magnitude higher than the cost of running Docker.

---

## Why Testcontainers instead

Testcontainers starts a real PostgreSQL container for each test run, using the
same version and configuration as production. This means:

- ✅ Constraints, indexes, and query plans behave identically to production
- ✅ Flyway migrations are validated against the real engine
- ✅ Transaction semantics match what will run in production
- ✅ No "passes locally, fails in CI" surprises

The tradeoff is that Docker must be running. On macOS, Docker Desktop or Colima
satisfies this requirement. The first test run pulls the PostgreSQL image (1–3 min);
subsequent runs reuse it.

---

## What this looks like in the code

All integration tests extend `BaseIntegrationTest`, which wires up Testcontainers:

```java
// ✅ Correct — real PostgreSQL via Testcontainers
class ResourceServiceTest extends BaseIntegrationTest {
    ...
}

// ❌ Wrong — never add H2 as a test dependency
// testImplementation 'com.h2database:h2'
```

---

## If Docker isn't running

```text
Could not find a valid Docker environment
```

Start Docker or Colima first:

```bash
colima start           # macOS with Colima
# or
open -a Docker         # macOS with Docker Desktop
```

Then re-run:

```bash
./gradlew test
```

---

## Related

- [`TESTCONTAINERS_EXPLAINED.md`](../testing/TESTCONTAINERS_EXPLAINED.md) —
  How Testcontainers works, lifecycle, and BaseIntegrationTest
- [`FLYWAY_MIGRATIONS_EXPLAINED.md`](./FLYWAY_MIGRATIONS_EXPLAINED.md) —
  How schema migrations run against the real PostgreSQL engine
- [`docs/adr/ADR-001-database-postgresql.md`](../../adr/ADR-001-database-postgresql.md) —
  Decision record explaining the PostgreSQL-everywhere policy
- [`docs/adr/ADR-002-testcontainers.md`](../../adr/ADR-002-testcontainers.md) —
  Decision record for Testcontainers as the integration test strategy
