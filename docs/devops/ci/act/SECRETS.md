<!--
created_by:   jazicorn-tw
created_date: 2026-03-05
updated_by:   jazicorn-tw
updated_date: 2026-03-09
status:       active
tags:         [devops, ci, act]
description:  "Secrets Management"
-->
# 🔐 Secrets Management

This document explains how secrets are handled in this repository.

---

## 📄 `.secrets.example`

`.secrets.example` is a **template file** that documents all supported secret
environment variables required for certain workflows (local or CI).

It exists to:

- Make required secrets **explicit and discoverable**
- Provide safe onboarding without leaking credentials
- Act as the **contract** for what secrets tooling expects

### How to use

```bash
cp .secrets.example .secrets
```

Then fill in real values in `.secrets`.

⚠️ **Important:**  
`.secrets` must never be committed. It should always be ignored by Git.

---

## 🔑 Supported Secrets

### `GH_APP_ID`

The numeric **GitHub App ID**.

**Used for:**

- Generating GitHub App installation tokens
- Authenticating CI workflows that must act as a GitHub App
- Local testing of workflows that mirror CI behavior

---

### `GH_APP_PRIVATE_KEY`

The **private key** for the GitHub App (PEM format).

**Notes:**

- This value is sensitive and must be kept secret
- The key may be represented in **one of three formats**, depending on context:
  1. **Multiline PEM** (default / recommended locally)
  2. **Newline-escaped PEM** (`\n`)
  3. **Base64-encoded PEM**

**Used for:**

- Signing JWTs to exchange for GitHub App tokens

---

## 🔄 Encoding the Private Key (when and why)

Some environments do **not handle multiline secrets reliably**.  
In those cases, the GitHub App private key may need to be **encoded** before storage.

### ✅ When you should use Base64 (`b64`)

Use a Base64-encoded private key when:

- Your secret store does **not support multiline values**
- You see parsing or truncation issues with PEM keys
- A tool or action explicitly expects a Base64 string
- You want a single-line, transport-safe representation

Typical examples:

- Certain CI platforms or secret managers
- JSON-based configuration files
- Environment variable injection layers that strip newlines

---

### 🔧 How to convert the key to Base64

`act` does not support multiline secret values in `.secrets`. The PEM file has
newlines, so it must be base64-encoded to a single line before storing it.

**Recommended: write to `.tmp_key.b64` then append to `.secrets`**

```bash
# Run once — store .pem and .tmp_key.b64 outside the repo
base64 github-app.pem | tr -d '\n' > .tmp_key.b64
echo "GH_APP_PRIVATE_KEY=$(cat .tmp_key.b64)" >> .secrets
rm .tmp_key.b64   # delete the temp file after use
```

Or inline (no temp file):

```bash
echo "GH_APP_PRIVATE_KEY=$(base64 github-app.pem | tr -d '\n')" >> .secrets
```

⚠️ **Security warning**

- Base64 is **encoding, not encryption**
- The encoded value is still a **secret**
- Do **not** commit the encoded string
- Do **not** paste it into documentation or examples
- Do **not** check in generated files containing decoded keys

Store the resulting value as `GH_APP_PRIVATE_KEY` in `.secrets`.

---

### 🔁 How the key is used at runtime

If `GH_APP_PRIVATE_KEY` is Base64-encoded, the consuming script or workflow
**must decode it before use**, for example:

```bash
echo "$GH_APP_PRIVATE_KEY" | base64 --decode > key.pem
```

The decoded file (`key.pem`) is then used normally for JWT signing.

> 🔎 Whether decoding is required depends on the consumer.
> This repository documents the secret **format**, not the decoding strategy.

---

## 🧭 Design Principles

Secrets in this repository follow these rules:

- ❌ No secrets committed to source control
- ✅ Explicit documentation of required secrets
- 🔁 Parity between local workflows and CI
- 🔒 Least-privilege credentials (GitHub Apps over personal tokens)
- 📄 Format clarity over implicit assumptions

---

## 🧪 CI vs Local

In CI:

- Secrets are injected via GitHub Actions secrets or variables
- Values may be **Base64-encoded** depending on platform constraints
- `.secrets` is **not used**

Locally (with `act`):

- `act` does **not** support multiline secret values in `.secrets`
- `GH_APP_PRIVATE_KEY` must be **Base64-encoded** (single line) in `.secrets`
- GitHub Actions secrets support multiline — the raw PEM is used there

---

## 🚫 What NOT to do

- Do not commit `.secrets`
- Do not commit Base64-encoded private keys
- Do not reuse personal access tokens when a GitHub App is expected
- Do not log secret values (even masked ones)
- Do not assume all environments handle multiline secrets correctly

---

## 📌 Summary

- `.secrets.example` documents **what secrets exist**
- `.secrets` contains **real values and is never committed**
- Base64 encoding does **not** make a secret safe to commit
- `GH_APP_PRIVATE_KEY` may be PEM or Base64, depending on environment
- `SECRETS.md` is the **authoritative reference** for secrets usage
