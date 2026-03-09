<!--
created_by:   jazicorn-tw
created_date: 2026-03-07
updated_by:   jazicorn-tw
updated_date: 2026-03-09
status:       active
tags:         [faq, spring]
description:  "Why `management.endpoint.health.show-details=when-authorized`"
-->
# Why `management.endpoint.health.show-details=when-authorized`

This article explains what the `show-details` setting controls, what Spring Boot exposes
at each level, and why this template uses `when-authorized` instead of `always`.

---

## What `show-details` controls

The `management.endpoint.health.show-details` property determines how much information
the `/actuator/health` endpoint returns to callers.

| Value             | Who sees details                               |
| ----------------- | ---------------------------------------------- |
| `never`           | No one — always returns `{"status":"UP"}` only |
| `when-authorized` | Only authenticated + authorized users          |
| `always`          | Everyone, including unauthenticated callers    |

Spring Boot's default is `never`. This template uses `when-authorized` to enable details
for authorized users (Phase 7+) while keeping them hidden from the public.

---

## What `always` actually exposes

When `show-details=always`, every caller — including anonymous internet traffic — receives
a detailed JSON response. A typical response includes:

```json
{
  "status": "UP",
  "components": {
    "db": {
      "status": "UP",
      "details": {
        "database": "PostgreSQL",
        "validationQuery": "isValid()"
      }
    },
    "diskSpace": {
      "status": "UP",
      "details": {
        "total": 499963174912,
        "free": 321456123904,
        "threshold": 10485760,
        "path": "/app/."
      }
    },
    "ping": { "status": "UP" }
  }
}
```

This surfaces:

- **Database engine and version** — confirms PostgreSQL is in use and its validation behavior
- **Disk layout** — absolute paths and available space on the host filesystem
- **Connection pool state** — implicitly (db UP/DOWN with timing)
- **Thread pool and memory indicators** — if additional actuator health indicators are added

---

## Why this is a security concern

Exposing infrastructure details publicly reduces an attacker's reconnaissance effort:

- **Database engine fingerprinting** — knowing PostgreSQL is in use narrows the attack surface
  to known PostgreSQL CVEs and default configuration weaknesses
- **Filesystem paths** — absolute paths confirm deployment layout and may reveal container
  or cloud provider patterns
- **Liveness timing** — response latency and component availability reveal deployment topology

None of this is catastrophic on its own, but defense in depth means not leaking what you
don't need to.

> ⚠️ `show-details=always` is appropriate during local development or on internal-only
> admin endpoints. It is not appropriate for a public-facing service endpoint.

---

## Why `when-authorized` is the right default

`when-authorized` gives you the best of both:

- ✅ Unauthenticated callers see only `{"status":"UP"}` — nothing leaked
- ✅ Authenticated and authorized users (ops, monitoring systems with credentials) see full details
- ✅ No code change required when auth is added in Phase 7 — the setting is already correct

---

## Current behavior in Phase 0

In Phase 0, `SecurityConfig` permits all requests (auth enforcement comes in Phase 7).
This means `when-authorized` currently behaves identically to `never` for unauthenticated
callers — the health endpoint returns only `{"status":"UP"}` without component details.

```bash
# Phase 0 — unauthenticated caller sees only status
curl http://localhost:8080/actuator/health
# {"status":"UP"}
```

This is the correct and expected behavior. The setting is already future-proof for Phase 7.

---

## What changes in Phase 7

Once JWT authentication is enforced (Phase 7), a caller presenting a valid token with the
appropriate authority will receive the full component detail response. No property change
needed — `when-authorized` handles it automatically.

---

## Related

- [`docs/devops/SECURITY.md`](../../devops/SECURITY.md) — Security model and endpoint protection overview
- [`docs/devops/HEALTH.md`](../../devops/HEALTH.md) — How actuator health is used for container healthchecks
- [`docs/phases/PHASES.md`](../../phases/PHASES.md) — Phase 6/7 security rollout plan
- [`docs/adr/ADR-003-actuator-health.md`](../../adr/ADR-003-actuator-health.md) —
  Decision record for actuator health endpoint exposure
