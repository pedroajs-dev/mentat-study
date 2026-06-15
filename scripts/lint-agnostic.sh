#!/usr/bin/env bash
# lint-agnostic.sh — enforces model-agnostic content in agent and skill files.
# Usage: bash scripts/lint-agnostic.sh [file|dir ...]
# Defaults to: agents/ skills/

set -euo pipefail

# Resolve targets: use args if given, else default directories
if [ "$#" -gt 0 ]; then
  targets=("$@")
else
  targets=("agents/" "skills/")
fi

# Collect all .md files from targets, skipping compiled/ (generated output)
collect_files() {
  for target in "${targets[@]}"; do
    if [ -f "$target" ] && [[ "$target" == *.md ]]; then
      # Skip anything under compiled/
      if [[ "$target" != compiled/* ]] && [[ "$target" != ./compiled/* ]] && [[ "$target" != */compiled/* ]]; then
        echo "$target"
      fi
    elif [ -d "$target" ]; then
      find "$target" -name "*.md" | grep -vE '(^|/)compiled/' | sort
    fi
  done
}

# Patterns to detect (model names — case insensitive)
MODEL_NAMES_PATTERN='GPT-4|GPT-3|GPT4|GPT3|Claude|Gemini|Llama|Mistral|Grok|Falcon|PaLM'

# Platform-specific tokens (case sensitive)
PLATFORM_TOKENS_PATTERN='<claude:|{anthropic:|\[INST\]|<<SYS>>|<\|im_start\|>|<\|im_end\|>|^<s>$|^</s>$|<\|endoftext\|>'

# Context-window references (case insensitive)
CONTEXT_PATTERN='context window|128k|200k|32k|100k|token limit|context length'

found_error=0

while IFS= read -r file; do
  line_number=0
  while IFS= read -r line; do
    line_number=$((line_number + 1))

    # Check model names (case-insensitive)
    if echo "$line" | grep -iEq "$MODEL_NAMES_PATTERN"; then
      match=$(echo "$line" | grep -iEo "$MODEL_NAMES_PATTERN" | head -1)
      echo "lint-agnostic ERROR: ${file}:${line_number}: model name detected: \"${match}\""
      found_error=1
    fi

    # Check platform tokens (case-sensitive)
    if echo "$line" | grep -Eq "$PLATFORM_TOKENS_PATTERN"; then
      match=$(echo "$line" | grep -Eo "$PLATFORM_TOKENS_PATTERN" | head -1)
      echo "lint-agnostic ERROR: ${file}:${line_number}: platform-specific token detected: \"${match}\""
      found_error=1
    fi

    # Check context-window references (case-insensitive)
    if echo "$line" | grep -iEq "$CONTEXT_PATTERN"; then
      match=$(echo "$line" | grep -iEo "$CONTEXT_PATTERN" | head -1)
      echo "lint-agnostic ERROR: ${file}:${line_number}: context-window reference detected: \"${match}\""
      found_error=1
    fi

  done < "$file"

  # Agent version-gate check: any file with `type: agent` in its YAML frontmatter
  # MUST contain the memory-protocol-version check. The version gate must never be
  # omitted (Story 1.4 AC #3). Frontmatter = lines between the first two `---` fences.
  # Print only frontmatter lines (between the first two `---` fences). No early
  # `exit` — awk drains all of `tr`'s output so `tr` never gets SIGPIPE, which
  # would otherwise abort the run under `set -o pipefail` on large files.
  frontmatter=$(tr -d '\r' < "$file" | awk 'BEGIN{fences=0} /^---[[:space:]]*$/{fences++; next} fences==1{print}')
  # Match `type: agent`, tolerating quotes (type: "agent") and a trailing inline
  # comment (type: agent # primary). The word boundary stops `agentic` matching.
  if echo "$frontmatter" | grep -Eq "^[[:space:]]*type:[[:space:]]*[\"']?agent[\"']?[[:space:]]*(#.*)?$"; then
    if ! grep -q 'memory-protocol-version' "$file"; then
      echo "lint-agnostic ERROR: ${file}: agent file is missing the required memory-protocol-version check"
      found_error=1
    fi
  fi
done < <(collect_files)

if [ "$found_error" -eq 0 ]; then
  echo "lint-agnostic: all files OK"
  exit 0
else
  exit 1
fi
