<!--
created_by:   jazicorn-tw
created_date: 2026-03-05
updated_by:   jazicorn-tw
updated_date: 2026-03-09
status:       active
tags:         [onboarding]
description:  "Quick Start"
-->
# Quick Start

Get the API running and make your first requests in under 2 minutes.

> **Setting up for the first time?** See [`PROJECT_SETUP.md`](./PROJECT_SETUP.md) for the full
> checklist — placeholder replacement, env files, bootstrap, and CI configuration.
> **Prerequisites:** Complete [`DAY_1_ONBOARDING.md`](./DAY_1_ONBOARDING.md)
> first. This guide assumes your environment is set up and Docker is running.

## Prerequisites

- `.env` exists (run `make env-init` if not)
- Docker is running (`make docker-up`)

> **Switching between projects?** If you were running another project that uses port 5432,
> run `make env-down` in that project first. Only one Postgres container can hold port 5432 at a time.
> When you're done here, run `make env-down` so the port is free for other projects.

## Start the app

```bash
make run   # starts Postgres + Spring Boot, sources .env
```

The API is available at **`http://localhost:8080`**.

## Health check

Open in browser: `http://localhost:8080/actuator/health`

```bash
curl -s http://localhost:8080/actuator/health | jq .status
# "UP"
```

## Resource endpoints

```bash
# Create a resource and capture the returned ID
RESOURCE_ID=$(curl -s -X POST http://localhost:8080/resources \
  -H "Content-Type: application/json" \
  -d '{"username":"alice"}' | jq -r .id)

echo $RESOURCE_ID   # xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx

curl -s http://localhost:8080/resources | jq .                          # list all
curl -s http://localhost:8080/resources/$RESOURCE_ID | jq .              # get one

curl -s -X PUT http://localhost:8080/resources/$RESOURCE_ID \
  -H "Content-Type: application/json" \
  -d '{"username":"bob"}' | jq .                                       # update

curl -s -X DELETE http://localhost:8080/resources/$RESOURCE_ID \
  -o /dev/null -w "%{http_code}"                                       # delete → 204
```
