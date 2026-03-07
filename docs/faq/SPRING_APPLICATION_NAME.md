# Why `spring.application.name` is `{{project-name}}`

This article explains what `spring.application.name` controls and what breaks if you
forget to replace the `{{project-name}}` placeholder during template setup.

---

## What `spring.application.name` controls

`spring.application.name` sets the application's identity within the Spring context.
This name propagates to:

- **Distributed trace headers** — used by Spring Cloud Sleuth / Micrometer tracing to
  tag all traces with the service name
- **Metrics** — service name label on all Micrometer metrics emitted to Prometheus,
  Datadog, or any compatible backend
- **Structured logs** — included in JSON log output when structured logging is configured
- **Actuator info** — surfaced in `/actuator/info` if the `info.app.name` property is
  wired to it

---

## Why it is set to `{{project-name}}`

`{{project-name}}` is a template placeholder. It has no runtime meaning — it exists to
be replaced with your actual project name during the setup step.

```bash
# This is the replacement command from PROJECT_SETUP.md step 2
grep -rl '{{project-name}}' . \
  --include='*.yml' --include='*.md' --include='*.json' --include='*.toml' --include='*.properties' \
  | xargs sed -i '' 's/{{project-name}}/my-api/g'
```

Including `*.properties` in that command is what ensures `application.properties` is
covered. See [`docs/onboarding/PROJECT_SETUP.md`](../onboarding/PROJECT_SETUP.md) for
the full setup checklist.

---

## What breaks if you forget

If you deploy without replacing `{{project-name}}`:

- ❌ Distributed traces are tagged `{{project-name}}` — impossible to correlate with your actual service
- ❌ Metrics arrive with service label `{{project-name}}` — dashboards show a phantom service name
- ❌ Log aggregation groups your logs under `{{project-name}}` — filtered out or mixed with other
  projects using the same template

None of these cause a runtime crash, so the problem is invisible until you look at your
observability tooling and wonder why nothing is labelled correctly.

---

## How to verify it is set correctly

```bash
grep spring.application.name src/main/resources/application.properties
# spring.application.name=my-api   ← expected after replacement
# spring.application.name={{project-name}}   ← needs fixing
```

---

## Related

- [`docs/onboarding/PROJECT_SETUP.md`](../onboarding/PROJECT_SETUP.md) — Full placeholder replacement checklist (Step 2)
- [`docs/environment/runtime/OBSERVABILITY_LOGGING.md`](../environment/runtime/OBSERVABILITY_LOGGING.md) —
  Logging and metrics configuration reference
