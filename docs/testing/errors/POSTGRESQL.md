<!--
created_by:   jazicorn-tw
created_date: 2026-03-05
updated_by:   jazicorn-tw
updated_date: 2026-03-09
status:       active
tags:         [test, errors]
description:  "PostgreSQL Errors"
-->
<!-- markdownlint-disable MD036 -->
# PostgreSQL Errors

## 1. Authentication failures

**Symptoms**

- `FATAL: password authentication failed for user`

**Cause**

- Username/password mismatch between the container and application configuration

**Fix**

- Ensure container credentials and Spring properties match
- Prefer Testcontainers dynamic properties:

```java
registry.add("spring.datasource.username", POSTGRES::getUsername);
registry.add("spring.datasource.password", POSTGRES::getPassword);
```

## 2. Database does not exist

**Symptoms**

- `FATAL: database "<name>" does not exist`

**Cause**

- Incorrect database name
- Container initialized with a different database

**Fix**

- Ensure the database name matches the container configuration:

```java
.withDatabaseName("{{app-name}}_test")
```

## 3. Connection refused

**Symptoms**

- `Connection refused`
- `could not connect to server`

**Cause**

- PostgreSQL container not fully started
- Hardcoded host/port overriding Testcontainers values

**Fix**

- Do not hardcode `spring.datasource.url`
- Always rely on:

```java
registry.add("spring.datasource.url", POSTGRES::getJdbcUrl);
```

## 4. Role does not exist

**Symptoms**

- `FATAL: role "<user>" does not exist`

**Cause**

- Username mismatch

**Fix**

- Align container username and Spring configuration

## 5. Schema permission errors

**Symptoms**

- `permission denied for schema public`

**Cause**

- Database user does not own the schema

**Fix**

```properties
spring.flyway.schemas=public
spring.jpa.properties.hibernate.default_schema=public
```

---

## 6. Host / port mistakes

**Cause**

- Connecting to `localhost:5432`
- Ignoring Testcontainers dynamic ports

**Fix**

- Never hardcode host or port
- Always use the JDBC URL from Testcontainers

---

## 7. Persistent Docker volume issues

**Cause**

- Reused Docker volumes keeping old database state

**Fix**

```bash
docker volume ls
docker volume rm <volume_name>
```

---

## 8. Port 5432 already allocated (local dev)

**Symptoms**

```bash
Bind for 0.0.0.0:5432 failed: port is already allocated
```

**Cause**

- Another project's Docker Postgres container is still running
- A native PostgreSQL installation (e.g. Homebrew) is running on the host
- An SSH tunnel is forwarding port 5432 from a remote machine

**Diagnose**

```bash
lsof -i :5432
```

**Fix — stop the other project's container**

```bash
docker ps                        # find the container using 5432
make env-down                    # run from the other project's directory
```

Then re-run `make env-up` here.

**Fix — stop the native Postgres**

```bash
brew services stop postgresql
# or for a versioned install:
brew services stop postgresql@16
```

Then re-run `make env-up`.

**Fix — change the Docker compose port**

If you need the native Postgres running, map a different host port in `docker-compose.yml`:

```yaml
ports:
  - "5433:5432"
```

Then update `DB_PORT` (or equivalent) in your `.env` to `5433`.

---

## 9. Golden rules for PostgreSQL in tests

- ❌ Never hardcode JDBC URLs
- ❌ Never rely on persistent DB state
- ✅ Always use Testcontainers dynamic properties
- ✅ Prefer fresh containers per test run
