# How does the pre-add hook work?

This article explains the shell-level `git add` wrapper that runs lint and
formatting checks before files are staged — what it does, why it exists, and
how to control it.

---

## What it is

`scripts/git/pre-add.sh` is a Bash script invoked by a shell function that
shadows the `git` command. When you run `git add <files>`, the wrapper
intercepts the call, runs checks on the files you are about to stage, and only
passes the add through if everything passes.

This is **not** a native Git hook (`.githooks/pre-commit`). It runs earlier —
at `git add` time — so formatting is applied before a commit is even attempted.

---

## What it checks

| Files staged | Check | Behavior |
| ------------ | ----- | -------- |
| `*.md` | markdownlint-cli2 | Aborts on error — fix violations, then re-run `git add` |
| `*.java`, `*.gradle` | Spotless (`make format`) | Auto-fixes in place — just re-run `git add` |
| `scripts/`, `.githooks/`, `*.sh` | Exec-bits (`make exec-bits`) | Auto-fixes `chmod +x` and stages the mode change |

The key design principle: **only staged files are checked**. If you run
`git add src/Main.java`, markdownlint never fires. If you run
`git add docs/guide.md`, Spotless never fires. Unrelated violations in other
files do not block your add.

---

## Why it exists

Without this hook, a developer might:

- Commit a Java file with Spotless violations → CI fails on `spotlessCheck`
- Stage a shell script without `+x` → exec-bits check fails in CI
- Commit a markdown file with MD013 violations → `markdown-lint` job fails

The hook catches all three classes of error locally, before the push, with
auto-fix where possible. The CI jobs become a safety net rather than the first
line of enforcement.

---

## How it decides what to check

The script collects files from the `git add` arguments:

```bash
# Explicit files — only those files
git add src/Main.java docs/guide.md

# -A / --all / . — all modified and untracked files
git add -A
git add .
```

For `-A` mode it queries `git ls-files --modified --others --exclude-standard`
to build the file list.

---

## How to skip it

Three escape hatches exist, ordered from broadest to narrowest:

### 1. Skip everything for one `git add`

```bash
SKIP_PRE_ADD_LINT=1 git add <files>
```

### 2. Skip Spotless only (avoids Gradle startup cost)

```bash
SKIP_SPOTLESS_ON_ADD=1 git add <files>
```

### 3. Disable the hook for your local clone

```bash
make pre-add-lint-off   # sets git config --local hooks.pre-add-lint false
make pre-add-lint-on    # re-enables
```

This writes to `.git/config` only — it is never committed.

### 4. Disable via local-settings.json

```json
{
  "git": {
    "preAddLint": {
      "enabled": false,
      "spotless": false
    }
  }
}
```

Set `enabled: false` to disable the whole hook; `spotless: false` to skip
Spotless only.

---

## Why markdownlint aborts but Spotless does not

Spotless (`spotlessApply`) is an auto-formatter — it rewrites the file in
place and you re-run `git add`. There is no manual fix step.

markdownlint is a linter, not a formatter. It reports violations that require
a human decision (e.g., restructuring a table, rewrapping a paragraph). Auto-
fixing markdown is unreliable, so the hook exits non-zero and prints the
violations for you to fix.

---

## If markdownlint fails

```text
pre-add: 📝 lint-docs…
docs/faq/MY_ARTICLE.md:45:121 error MD013/line-length ...
pre-add: ❌ markdownlint failed — fix violations then re-run git add
```

1. Open the file at the reported line
2. Fix the violation (wrap the line, add a language tag, etc.)
3. Re-run `git add <file>`

See [`QUALITY_GATE_EXPLAINED.md`](./QUALITY_GATE_EXPLAINED.md) for a full
reference of markdownlint rule codes and how to resolve them.

---

## Related

- [`QUALITY_GATE_EXPLAINED.md`](./QUALITY_GATE_EXPLAINED.md) —
  Spotless, Checkstyle, PMD, SpotBugs, and markdownlint error reference
- [`docs/tooling/PRE_ADD_LINT.md`](../tooling/PRE_ADD_LINT.md) —
  Shell function setup, full configuration reference, and CI comparison
- [`scripts/git/pre-add.sh`](../../scripts/git/pre-add.sh) —
  The script itself
