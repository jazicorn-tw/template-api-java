# Project Configuration Checklist

Quick reference for everything needed to configure a new project from this template.
Full instructions: [`PROJECT_SETUP.md`](./PROJECT_SETUP.md)

---

## GitHub → Settings → Secrets and variables → Actions

### Secrets

| Secret | Required | Description |
| --- | --- | --- |
| `GH_APP_ID` | Release only | GitHub App ID |
| `GH_APP_PRIVATE_KEY` | Release only | Full `.pem` contents (multiline is fine) |

### Variables

| Variable | Required | Value | Description |
| --- | --- | --- | --- |
| `CANONICAL_REPOSITORY` | ✅ Always | `your-org/your-repo` | Only repo allowed to publish artifacts |
| `ENABLE_SEMANTIC_RELEASE` | ✅ Always | `true` / `false` | Gates push-based releases |
| `PUBLISH_DOCKER_IMAGE` | Optional | `true` / `false` | Enable Docker image publishing |
| `PUBLISH_HELM_CHART` | Optional | `true` / `false` | Enable Helm chart publishing |
| `ENABLE_STATIC_ANALYSIS` | Optional | `false` to disable | Checkstyle / PMD / SpotBugs |
| `ENABLE_SONAR` | Optional | `false` to disable | SonarCloud analysis |
| `ENABLE_MD_LINT` | Optional | `false` to disable | Markdown lint CI job |
| `ENABLE_DOCTOR_SNAPSHOT` | Optional | `false` to disable | Doctor snapshot CI job |
| `ENABLE_CODEQL` | Optional | `false` to disable | CodeQL security analysis |

> Optional CI flags (`ENABLE_*`) are **on by default** when unset. Set to `false` to skip.

---

## Local files

| File | Source | Required |
| --- | --- | --- |
| `.env` | `cp .env.example .env` | ✅ Always |
| `.vars` | `cp .vars.example .vars` | `act` local CI only |
| `.secrets` | `cp .secrets.example .secrets` | `act` release runs only |

### `.env` — key values to set

| Key | Description |
| --- | --- |
| `APP_NAME` | Sets DB name, Docker Compose defaults, scripts |
| `SPRING_DATASOURCE_URL` | Update to match `APP_NAME` |
| `SPRING_DATASOURCE_USERNAME` | Update to match `APP_NAME` |
| `POSTGRES_PASSWORD` | Any non-default password |

### `.vars` — key values to set

| Key | Description |
| --- | --- |
| `CANONICAL_REPOSITORY` | Must match the GitHub variable above |
| `ENABLE_SEMANTIC_RELEASE` | `true` to enable in local `act` runs |

### `.secrets` — key values to set

| Key | Description |
| --- | --- |
| `GH_APP_ID` | GitHub App ID (integer) |
| `GH_APP_PRIVATE_KEY` | Base64-encoded PEM key (multiline not supported by `act`) |

---

## One-time git setup

```bash
make bootstrap                                          # install hooks + fix executable bits
git tag v0.0.0 $(git rev-list --max-parents=0 HEAD)    # baseline tag for semantic-release
git push origin v0.0.0
```

---

## Template placeholder replacement

| Token | Replace with |
| --- | --- |
| `{{project-name}}` | Repo / pipeline name (e.g. `my-api`) |
| `your-org` | GitHub org or username (e.g. `acme`) |
| `com.example` | Java base package (e.g. `com.acme`) |

**Quick option:** `make init-project name=my-api owner=acme` replaces `{{project-name}}`,
`your-org`, and `jazicorn-tw` across all key files automatically.

See [PROJECT_SETUP.md §2](./PROJECT_SETUP.md#2-replace-template-placeholders) for full details.
