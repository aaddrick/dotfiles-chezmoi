#!/usr/bin/env bash
# Draft a git commit message for chezmoi auto-commits via `claude -p`.
# Called from .chezmoi.toml.tmpl's [git] commitMessageTemplate.
#
# Usage: chezmoi-commit-message.sh [source-dir]
#
# Reads the staged diff and asks claude-sonnet-4-6 for a conventional-commit
# style message. Any failure (claude missing, empty diff, API error) falls
# back to a generic message so commits never block on message generation.
set -uo pipefail

source_dir="${1:-$HOME/.local/share/chezmoi}"
fallback="chore: update dotfiles"

emit_fallback() { printf '%s\n' "$fallback"; exit 0; }

cd "$source_dir" 2>/dev/null                         || emit_fallback
command -v claude >/dev/null 2>&1                    || emit_fallback

diff="$(git diff --cached 2>/dev/null)"
[ -n "$diff" ]                                       || emit_fallback

read -r -d '' prompt <<'PROMPT' || true
Write a git commit message for the staged diff on stdin.

Rules:
- Subject line under 72 chars, imperative mood, start with a conventional type (feat|fix|chore|refactor|docs|build|ci)
- If the change is non-trivial, leave a blank line after the subject then 1-4 short dashed bullets
- Output ONLY the commit message text — no markdown fences, no preamble, no "Here is..."
- Context: a chezmoi dotfiles repo managing Fedora/Nobara system config
PROMPT

msg="$(printf '%s' "$diff" \
  | claude -p --model claude-sonnet-4-6 "$prompt" 2>/dev/null \
  | awk '
      /^[[:space:]]*```/ { next }
      { lines[++n] = $0 }
      END {
        first = 1
        while (first <= n && lines[first] ~ /^[[:space:]]*$/) first++
        last = n
        while (last >= 1 && lines[last] ~ /^[[:space:]]*$/) last--
        for (i = first; i <= last; i++) print lines[i]
      }
    ')"

[ -n "$msg" ] && printf '%s\n' "$msg" || emit_fallback
