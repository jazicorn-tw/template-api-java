#!/usr/bin/env bash
# scripts/docs/backfill-frontmatter.sh
#
# One-time script: seeds YAML frontmatter into every docs/**/*.md file that
# doesn't already have one.
#
# - created_by / created_date: derived from the oldest git commit that added
#   the file (git log --diff-filter=A). Falls back to current user + today
#   for files not yet in git history.
# - updated_by / updated_date: derived from the most recent commit touching
#   the file. Falls back to current user + today.
# - status: "active" (existing docs are already in use)
# - tags: auto-derived from the directory path (e.g. docs/adr/ → [adr])
# - description: "" (left empty for contributors to fill in)
#
# Does NOT run git add — review and stage the changes yourself.
#
# Usage:
#   bash scripts/docs/backfill-frontmatter.sh
#   git diff --stat        # review
#   git add docs/
#   git commit -m "docs: seed YAML frontmatter in all docs files"

set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel)"
DOCS_DIR="$REPO_ROOT/docs"

_fallback_author=$(git config user.name 2>/dev/null \
  || git config user.email 2>/dev/null \
  || echo "unknown")
_fallback_date=$(date +%Y-%m-%d)

patched=0
skipped=0

# Derive tags from a file path relative to docs/
# e.g. docs/faq/dx/FOO.md → [faq, dx]
#      docs/onboarding/BAR.md → [onboarding]
#      docs/README.md → []
# Map a raw directory segment to the canonical tag name.
_canonical_tag() {
  case "$1" in
    environment) echo "env"  ;;
    testing)     echo "test" ;;
    quality)     echo "qa"   ;;
    database)    echo "db"   ;;
    _templates)  echo ""     ;;  # internal dir — no tag
    *)           echo "$1"   ;;
  esac
}

_tags_for_path() {
  local rel="${1#"$DOCS_DIR"/}"   # strip leading docs/
  local dir
  dir="$(dirname "$rel")"
  if [[ "$dir" == "." ]]; then
    echo "[]"
    return
  fi
  # Split on / and map each segment to its canonical tag
  IFS='/' read -ra parts <<< "$dir"
  local joined=""
  for part in "${parts[@]}"; do
    local canonical
    canonical=$(_canonical_tag "$part")
    [[ -z "$canonical" ]] && continue
    [[ -n "$joined" ]] && joined+=", "
    joined+="$canonical"
  done
  echo "[$joined]"
}

while IFS= read -r -d '' f; do
  # Skip files that already have frontmatter (first line is <!-- or ---)
  if head -1 "$f" | grep -qE '^(<!--|---)$'; then
    skipped=$(( skipped + 1 ))
    continue
  fi

  # Get creation info from the commit that first added the file
  _created_by=$(git log --diff-filter=A --follow --format="%an" -- "$f" 2>/dev/null | tail -1)
  _created_date=$(git log --diff-filter=A --follow --format="%as" -- "$f" 2>/dev/null | tail -1)

  # Get last-update info from the most recent commit
  _updated_by=$(git log -1 --format="%an" -- "$f" 2>/dev/null)
  _updated_date=$(git log -1 --format="%as" -- "$f" 2>/dev/null)

  # Fallback for files with no git history (new, uncommitted)
  [[ -z "$_created_by"   ]] && _created_by="$_fallback_author"
  [[ -z "$_created_date" ]] && _created_date="$_fallback_date"
  [[ -z "$_updated_by"   ]] && _updated_by="$_fallback_author"
  [[ -z "$_updated_date" ]] && _updated_date="$_fallback_date"

  _tags=$(_tags_for_path "$f")

  _tmp=$(mktemp)
  {
    echo '<!--'
    printf 'created_by:   %s\n' "$_created_by"
    printf 'created_date: %s\n' "$_created_date"
    printf 'updated_by:   %s\n' "$_updated_by"
    printf 'updated_date: %s\n' "$_updated_date"
    echo 'status:       active'
    printf 'tags:         %s\n' "$_tags"
    echo 'description:  ""'
    echo '-->'
    cat "$f"
  } > "$_tmp" && mv "$_tmp" "$f"

  patched=$(( patched + 1 ))
  printf '  ✅  %s\n' "${f#"$REPO_ROOT"/}"
done < <(find "$DOCS_DIR" -name '*.md' -print0 | sort -z)

printf '\n'
printf '  Backfill complete: %d patched, %d already had frontmatter\n' \
  "$patched" "$skipped"
printf '  Review with:  git diff docs/\n'
printf '  Stage with:   git add docs/\n'
