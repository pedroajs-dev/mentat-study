#!/usr/bin/env bash
# build-skills.sh — assembles compiled agent files by inlining skill content.
# Usage:
#   bash scripts/build-skills.sh           # build compiled/ from agents/ + skills/
#   bash scripts/build-skills.sh --check   # compare what build would produce against compiled/;
#                                           # fails with error if compiled/ was edited directly

set -euo pipefail

AGENTS_DIR="agents"
SKILLS_DIR="skills"
COMPILED_DIR="compiled"
CHECK_MODE=false

if [ "${1:-}" = "--check" ]; then
  CHECK_MODE=true
fi

# strip_frontmatter: print everything after the closing --- of the YAML block
strip_frontmatter() {
  local file="$1"
  awk 'BEGIN{skip=1;count=0}
       {sub(/\r$/,"")}
       skip && /^---/{count++;if(count==2){skip=0};next}
       !skip{print}' "$file"
}

# inline_skill: append skill body to $2, under the already-written ### heading.
# - Validates the name so reads stay confined to SKILLS_DIR (no path traversal).
# - Demotes skill headings two levels (## → ####) so they nest under the ###
#   skill heading rather than becoming siblings of agent sections (Pattern 2).
#   Heading lines inside fenced code blocks are left untouched.
inline_skill() {
  local skill_name="$1"
  local out_file="$2"

  if [[ ! "$skill_name" =~ ^[A-Za-z0-9._-]+$ ]] || [[ "$skill_name" == "." ]] || [[ "$skill_name" == ".." ]]; then
    echo "build-skills WARNING: invalid skill name '$skill_name' — skipping" >&2
    return
  fi

  local skill_file="$SKILLS_DIR/${skill_name}.md"
  if [ ! -f "$skill_file" ]; then
    echo "build-skills WARNING: skill file not found: $skill_file" >&2
    return
  fi

  strip_frontmatter "$skill_file" | awk '
    /^```/ { fence = !fence }
    !fence && /^#+[[:space:]]/ { sub(/^/, "##") }
    { print }
  ' >> "$out_file"
}

# build_agent: assemble one agent file into $2
# State machine:
#   frontmatter       → copy until second --- then switch to normal
#   normal            → copy; switch to skills on "## Skills"
#   skills            → copy headings; inline skill on "### name"; skip on ##-non-skills
#   skill_placeholder → skip placeholder lines; handle next ### or ## to transition
build_agent() {
  local agent_file="$1"
  local out_file="$2"
  local state="frontmatter"
  local fm_dashes=0

  > "$out_file"

  while IFS= read -r line; do
    line="${line%$'\r'}"
    case "$state" in

      frontmatter)
        echo "$line" >> "$out_file"
        if [[ "$line" == "---" ]]; then
          fm_dashes=$((fm_dashes + 1))
          if [ "$fm_dashes" -eq 2 ]; then
            state="normal"
          fi
        fi
        ;;

      normal)
        if [[ "$line" == "## Skills" ]]; then
          state="skills"
        fi
        echo "$line" >> "$out_file"
        ;;

      skills)
        if [[ "$line" =~ ^##[[:space:]] && "$line" != "## Skills" ]]; then
          # Leaving the Skills section
          state="normal"
          echo "$line" >> "$out_file"
        elif [[ "$line" =~ ^###[[:space:]](.+)$ ]]; then
          local skill_name="${BASH_REMATCH[1]}"
          echo "$line" >> "$out_file"
          inline_skill "$skill_name" "$out_file"
          state="skill_placeholder"
        else
          echo "$line" >> "$out_file"
        fi
        ;;

      skill_placeholder)
        # Skip placeholder content from the source agent file.
        # Transition back on the next heading.
        if [[ "$line" =~ ^##[[:space:]] && "$line" != "## Skills" ]]; then
          state="normal"
          echo "$line" >> "$out_file"
        elif [[ "$line" =~ ^##[[:space:]] && "$line" == "## Skills" ]]; then
          state="skills"
          echo "$line" >> "$out_file"
        elif [[ "$line" =~ ^###[[:space:]](.+)$ ]]; then
          # Next skill in the same ## Skills block
          local skill_name="${BASH_REMATCH[1]}"
          echo "$line" >> "$out_file"
          inline_skill "$skill_name" "$out_file"
          # Stay in skill_placeholder
        fi
        # All other lines (placeholder content) are silently skipped
        ;;

    esac
  done < "$agent_file"
}

# Determine output directory
TARGET_DIR="$COMPILED_DIR"
TEMP_DIR=""
if $CHECK_MODE; then
  TEMP_DIR=$(mktemp -d)
  trap 'rm -rf "$TEMP_DIR"' EXIT
  TARGET_DIR="$TEMP_DIR"
else
  mkdir -p "$COMPILED_DIR"
fi

# Process every agent file
agent_count=0
for agent_file in "$AGENTS_DIR"/*.md; do
  [ -f "$agent_file" ] || continue

  # Extract id from YAML frontmatter
  agent_id=$(awk '{sub(/\r$/,"")} /^---/{c++;next} c==1 && /^id:/{gsub(/^id:[[:space:]]*/,""); gsub(/[[:space:]]+$/,""); print; exit}' "$agent_file")
  if [ -z "$agent_id" ]; then
    echo "build-skills ERROR: no 'id' field found in frontmatter of $agent_file" >&2
    exit 1
  fi

  out_file="$TARGET_DIR/bmad-study-${agent_id}.md"
  build_agent "$agent_file" "$out_file"

  if ! $CHECK_MODE; then
    echo "  built: compiled/bmad-study-${agent_id}.md"
  fi
  agent_count=$((agent_count + 1))
done

if [ "$agent_count" -eq 0 ]; then
  echo "build-skills ERROR: no agent files found in $AGENTS_DIR/" >&2
  exit 1
fi

# --check: diff temp output against compiled/
if $CHECK_MODE; then
  if [ ! -d "$COMPILED_DIR" ] || [ -z "$(ls -A "$COMPILED_DIR"/*.md 2>/dev/null)" ]; then
    echo "build-skills --check: compiled/ is empty or absent — nothing to compare"
    exit 0
  fi

  mismatch=0
  for temp_file in "$TEMP_DIR"/bmad-study-*.md; do
    [ -f "$temp_file" ] || continue
    filename=$(basename "$temp_file")
    committed="$COMPILED_DIR/$filename"
    if [ ! -f "$committed" ]; then
      mismatch=1
      break
    fi
    if ! diff -q "$temp_file" "$committed" > /dev/null 2>&1; then
      mismatch=1
      break
    fi
  done

  # Detect orphaned compiled files (no corresponding agent → not rebuilt)
  if [ "$mismatch" -eq 0 ]; then
    for committed_file in "$COMPILED_DIR"/bmad-study-*.md; do
      [ -f "$committed_file" ] || continue
      filename=$(basename "$committed_file")
      if [ ! -f "$TEMP_DIR/$filename" ]; then
        mismatch=1
        break
      fi
    done
  fi

  if [ "$mismatch" -eq 1 ]; then
    echo "compiled/ must not be edited directly — run build-skills.sh"
    exit 1
  fi

  echo "build-skills --check: compiled/ is up to date"
  exit 0
fi

echo "build-skills: $agent_count agent(s) compiled successfully"
exit 0
