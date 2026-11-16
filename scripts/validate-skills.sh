#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SKILLS_DIR="$ROOT_DIR/skills"
HAS_ERRORS=false
SKILL_COUNT=0

while IFS= read -r -d '' file; do
  SKILL_COUNT=$((SKILL_COUNT + 1))
  rel="${file#"$ROOT_DIR"/}"
  if ! head -n1 "$file" | grep -q "^---$"; then
    echo "❌ Missing YAML frontmatter start in $rel" >&2
    HAS_ERRORS=true
    continue
  fi
  if ! awk '/^---$/{c++; next} c==1{print} c>=2{exit}' "$file" | grep -qE '^name:\s*\S+'; then
    echo "❌ Missing 'name:' in frontmatter of $rel" >&2
    HAS_ERRORS=true
    continue
  fi
  if ! awk '/^---$/{c++; next} c==1{print} c>=2{exit}' "$file" | grep -qE '^description:\s*.+'; then
    echo "❌ Missing 'description:' in frontmatter of $rel" >&2
    HAS_ERRORS=true
    continue
  fi
  echo "✅ Valid skill: $rel"
done < <(find "$SKILLS_DIR" -name "SKILL.md" -print0 | sort -z)

for script in "$ROOT_DIR"/skills/basic/init-agents/templates/scripts/*.sh; do
  rel="${script#"$ROOT_DIR"/}"
  bash -n "$script"
  echo "✅ Valid bash syntax: $rel"
done

for pyscript in "$ROOT_DIR"/skills/basic/init-agents/templates/scripts/*.py; do
  rel="${pyscript#"$ROOT_DIR"/}"
  python3 -m py_compile "$pyscript"
  echo "✅ Valid python syntax: $rel"
done

if [[ "$HAS_ERRORS" == "true" ]]; then
  exit 1
fi

echo ""
echo "All $SKILL_COUNT skills and template scripts validated successfully!"
