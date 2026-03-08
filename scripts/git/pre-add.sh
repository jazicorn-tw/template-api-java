#!/usr/bin/env bash
set -euo pipefail

# pre-add.sh — lint, format, and exec-bit check before files are staged
#
# Called by the shell-level git() wrapper (not a native Git hook).
# .md files              → markdownlint-cli2 on staged files only (aborts on error)
# .java/.gradle          → make format     (spotlessApply, auto-fixes in place)
# scripts/ / .githooks/  → make exec-bits  (chmod +x + stage, auto-fixes in place)
#
# Configuration hierarchy (highest → lowest priority):
#   1. SKIP_PRE_ADD_LINT=1 git add …        env var — skip this invocation
#   2. git config --local hooks.pre-add-lint developer override (not committed)
#      make pre-add-lint-on / make pre-add-lint-off
#   3. .config/local-settings.json           repo-committed defaults
#      .git.preAddLint.enabled  (bool, default true)
#      .git.preAddLint.spotless (bool, default true)
#   4. Hard defaults: enabled=true, spotless=true
#
# One-off env overrides:
#   SKIP_PRE_ADD_LINT=1    git add …  # skip everything this invocation
#   SKIP_SPOTLESS_ON_ADD=1 git add …  # skip Spotless only (avoids Gradle startup)
#
# See docs/tooling/PRE_ADD_LINT.md for shell function setup.

REPO_ROOT="$(git rev-parse --show-toplevel)"
# shellcheck source=scripts/lib/shell-utils.sh
source "$REPO_ROOT/scripts/lib/shell-utils.sh"

# ── 1. Env var: skip everything ───────────────────────────────────────────────
if [[ "${SKIP_PRE_ADD_LINT:-0}" == "1" ]]; then
  exit 0
fi

# ── 2. Read local-settings.json defaults ──────────────────────────────────────
ls_enabled="true"
ls_spotless="true"
ls_file=""
if [[ -f "$REPO_ROOT/.config/local-settings.json" ]]; then
  ls_file="$REPO_ROOT/.config/local-settings.json"
elif [[ -f "$REPO_ROOT/local-settings.json" ]]; then
  ls_file="$REPO_ROOT/local-settings.json"
fi
if [[ -n "$ls_file" ]] && command -v jq >/dev/null 2>&1; then
  val="$(jq -r '.git.preAddLint.enabled // empty' "$ls_file" 2>/dev/null || true)"
  [[ "$val" == "false" ]] && ls_enabled="false"
  val="$(jq -r '.git.preAddLint.spotless // empty' "$ls_file" 2>/dev/null || true)"
  [[ "$val" == "false" ]] && ls_spotless="false"
fi

# ── 3. git config --local: developer override (beats local-settings.json) ─────
gc_val="$(git config --bool --local hooks.pre-add-lint 2>/dev/null || echo "")"
if [[ "$gc_val" == "false" ]]; then
  exit 0
elif [[ "$gc_val" == "true" ]]; then
  ls_enabled="true"
fi

# ── 4. Apply enabled default ───────────────────────────────────────────────────
if [[ "$ls_enabled" == "false" ]]; then
  exit 0
fi

# ── Collect files from git add arguments ──────────────────────────────────────
args=("$@")
all_mode=false

for arg in "${args[@]:-}"; do
  case "${arg:-}" in
    -A|--all|.) all_mode=true ;;
    -u|--update) all_mode=true ;;
  esac
done

md_files=()
java_files=()
script_files=()

collect_file() {
  local f="$1"
  [[ -f "$REPO_ROOT/$f" || -f "$f" ]] || return 0
  case "$f" in
    *.md)                          md_files+=("$f") ;;
    *.java|*.gradle)               java_files+=("$f") ;;
    scripts/*|.githooks/*|*.sh|*.bash|*.mjs) script_files+=("$f") ;;
  esac
}

if [[ "$all_mode" == "true" ]]; then
  while IFS= read -r f; do
    collect_file "$f"
  done < <(git -C "$REPO_ROOT" ls-files --modified --others --exclude-standard)
else
  # git ls-files (used in all_mode) returns repo-root-relative paths.
  # Single-file args are relative to CWD, which may be a subdirectory.
  # Prepend the git prefix (CWD relative to repo root) so paths stay
  # consistent after the later `cd "$REPO_ROOT"`.
  GIT_PREFIX="$(git rev-parse --show-prefix 2>/dev/null || true)"
  for arg in "${args[@]:-}"; do
    [[ "${arg:-}" == -* ]] && continue
    collect_file "${GIT_PREFIX}${arg}"
  done
fi

if [[ ${#md_files[@]} -eq 0 && ${#java_files[@]} -eq 0 && ${#script_files[@]} -eq 0 ]]; then
  exit 0
fi

failed=0
fail_count=0
cd "$REPO_ROOT"

# ── Output helpers ────────────────────────────────────────────────────────────
_RULE='  ────────────────────────────────────────────────────'
_rule()   { printf '%s\n' "$_RULE"; }
_step()   { printf '\n  %s\n' "$*"; }
_pass()   { printf '  ✅  %s\n' "$*"; }
_fail()   { printf '\n  ❌  %s\n' "$*"; failed=1; fail_count=$(( fail_count + 1 )); }
_skip()   { printf '  ⏭   %s\n' "$*"; }
_indent() { sed 's/^/    /'; }   # nest command output under its _step header

# ── Header ────────────────────────────────────────────────────────────────────
_label="pre-add"
[[ ${#md_files[@]} -gt 0 ]]     && _label+="  ·  ${#md_files[@]} md"
[[ ${#java_files[@]} -gt 0 ]]   && _label+="  ·  ${#java_files[@]} java/gradle"
[[ ${#script_files[@]} -gt 0 ]] && _label+="  ·  ${#script_files[@]} script"

printf '\n'
_rule
printf '  %s\n' "$_label"
_rule

# ── Markdown lint (markdownlint-cli2 on staged files only) ───────────────────
# Runs only on the .md files being added — not the full repo — so unrelated
# markdown violations never block an unrelated git add.
if [[ ${#md_files[@]} -gt 0 ]]; then
  _step "lint-docs"
  printf '    %s\n' "${md_files[@]}"
  if "$REPO_ROOT/node_modules/.bin/markdownlint-cli2" "${md_files[@]}" 2>&1 \
      | sed '/^Finding:/d' | _indent; then
    _pass "lint-docs"
  else
    _fail "lint-docs failed — see errors above, then re-run git add"
  fi
fi

# ── Auto-format Java/Gradle (make format) ─────────────────────────────────────
# Runs spotlessApply — auto-fixes formatting in place so git add can proceed.
# Adds ~10–15 s (Gradle startup). Disable via local-settings.json or env var.
if [[ ${#java_files[@]} -gt 0 ]]; then
  if [[ "${SKIP_SPOTLESS_ON_ADD:-0}" == "1" || "$ls_spotless" == "false" ]]; then
    _skip "format (spotlessApply skipped)"
  else
    _step "format (spotlessApply)"
    if make format 2>&1 | _indent; then
      _pass "format"
    else
      _fail "format failed — see errors above, then re-run git add"
    fi
  fi
fi

# ── Executable bits (make exec-bits) ──────────────────────────────────────────
# Auto-fixes chmod +x and stages the mode change (strict: 2, autoStage: true).
if [[ ${#script_files[@]} -gt 0 ]]; then
  _exec_out=$(make exec-bits 2>&1); _exec_rc=$?
  if [[ $_exec_rc -eq 0 ]]; then
    _pass "exec-bits (${#script_files[@]} script file(s))"
  else
    _step "exec-bits (${#script_files[@]} script file(s))"
  fi
  printf '%s\n' "$_exec_out" | _indent
  if [[ $_exec_rc -ne 0 ]]; then
    _fail "exec-bits failed — see errors above, then re-run git add"
  fi
fi

# ── Footer ────────────────────────────────────────────────────────────────────
printf '\n'
_rule
if [[ $failed -eq 0 ]]; then
  printf '  ✅  all checks passed\n'
elif [[ $fail_count -eq 1 ]]; then
  printf '  ❌  1 check failed — see errors above, then re-run git add\n'
else
  printf '  ❌  %d checks failed — see errors above, then re-run git add\n' "$fail_count"
fi
_rule
printf '\n'

exit $failed
