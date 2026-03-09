<!--
created_by:   jazicorn-tw
created_date: 2026-03-05
updated_by:   jazicorn-tw
updated_date: 2026-03-09
status:       active
tags:         [env, runtime]
description:  "Security & Authentication"
-->
# 🔐 Security & Authentication

JWT-based authentication configuration.

## Variables

```text
JWT_SECRET
JWT_EXPIRATION_SECONDS
JWT_ISSUER
JWT_AUDIENCE
```

## Notes

- Secrets must come from platform secret storage
- Never log or echo secret values
- Issuer/Audience become required once validation is enforced
