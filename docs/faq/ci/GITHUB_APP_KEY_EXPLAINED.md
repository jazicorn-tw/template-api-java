<!--
created_by:   jazicorn-tw
created_date: 2026-03-07
updated_by:   jazicorn-tw
updated_date: 2026-03-09
status:       active
tags:         [faq, ci]
description:  "How do I set up the GitHub App private key?"
-->
# How do I set up the GitHub App private key?

This article explains what the GitHub App private key is, why two different
formats exist (raw PEM vs Base64), and exactly what to put where.

---

## The short answer

| Where                                        | Format                                | Why                                            |
| -------------------------------------------- | ------------------------------------- | ---------------------------------------------- |
| GitHub Actions secret (`GH_APP_PRIVATE_KEY`) | Raw PEM — paste the `.pem` file as-is | GitHub Secrets support multiline values        |
| Local `.secrets` file (for `act`)            | Base64 single-line                    | `act` does not support multiline secret values |

---

## Why two formats?

The GitHub App private key is a PEM file — it contains newlines:

```text
-----BEGIN RSA PRIVATE KEY-----
MIIEowIBAAKCAQEA...
...multiple lines...
-----END RSA PRIVATE KEY-----
```

**GitHub Actions secrets** handle multiline values correctly. Paste the full
PEM contents into `GH_APP_PRIVATE_KEY` in Settings → Secrets and it works.

**`act`** (local CI simulation) reads secrets from a `.secrets` file, which
uses `KEY=VALUE` format on a single line. Newlines in the value break parsing.
The solution is to base64-encode the PEM to a single line first.

---

## Setting up the GitHub Actions secret

1. Download the `.pem` file from your GitHub App → **Private keys → Generate a private key**
2. Open the file in a text editor — copy everything including the header and footer
3. In your repo: **Settings → Secrets and variables → Actions → New repository secret**
4. Name: `GH_APP_PRIVATE_KEY`, Value: paste the full PEM contents

The release workflow passes this value through `fromJSON(format(...))` to
handle the multiline string correctly inside the workflow YAML.

---

## Setting up `.secrets` for local `act` use

Generate `.tmp_key.b64` — a base64-encoded single-line version of the key:

```bash
# Run once — keep your .pem file outside the repo
base64 github-app.pem | tr -d '\n' > .tmp_key.b64

# Append the encoded key into .secrets
echo "GH_APP_PRIVATE_KEY=$(cat .tmp_key.b64)" >> .secrets

# Delete the temp file — it is still a secret
rm .tmp_key.b64
```

Or inline (no temp file):

```bash
echo "GH_APP_PRIVATE_KEY=$(base64 github-app.pem | tr -d '\n')" >> .secrets
```

> ⚠️ Base64 is **encoding, not encryption**. The encoded value is still
> sensitive — never commit it.

---

## Verifying it works

After setup, run:

```bash
make act-release
```

The "Generate GitHub App token" step should succeed. If it fails, check:

| Error                                        | Cause                                                    |
| -------------------------------------------- | -------------------------------------------------------- |
| `Could not create installation access token` | `GH_APP_ID` or `GH_APP_PRIVATE_KEY` missing or malformed |
| `Could not retrieve installation` (404)      | App not installed on the repository                      |
| Token generated but push fails               | App not in the `main` ruleset bypass list                |

---

## Related

- [`docs/devops/GITHUB_APP_SETUP.md`](../../devops/GITHUB_APP_SETUP.md) —
  Full one-time setup guide (create App, add secrets, install, configure bypass)
- [`docs/devops/ci/act/SECRETS.md`](../../devops/ci/act/SECRETS.md) —
  Full secrets reference for local `act` runs
- [`WHY_NO_RELEASE.md`](./WHY_NO_RELEASE.md) —
  Why a release wasn't created even after the token was generated
