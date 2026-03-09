<!--
created_by:   jazicorn-tw
created_date: 2026-03-05
updated_by:   jazicorn-tw
updated_date: 2026-03-09
status:       active
tags:         [env, runtime]
description:  "️ Platform Notes"
-->
# ☁️ Platform Notes

## Render (Phase 1)

- Env vars configured via Render dashboard
- Secrets encrypted by Render
- Health checks:
  - `/actuator/health`
  - `/actuator/health/readiness`

No CI-driven deployments in Phase 1.

## Kubernetes / Helm (Phase 2)

Environment variables injected via:

- Helm `values.yaml`
- Kubernetes `ConfigMap`
- Kubernetes `Secret`

Helm charts support:

- image repository + tag
- env var templating
- readiness/liveness probes
