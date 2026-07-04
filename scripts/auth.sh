#!/usr/bin/env bash

set -euo pipefail

DRY_RUN=0

if [[ "${1:-}" == "--dry-run" ]]; then
  DRY_RUN=1
fi

status() {
  printf '\n[auth] %s\n' "$*"
}

can_prompt() {
  [[ -t 0 && -t 1 ]]
}

run() {
  if [[ "$DRY_RUN" -eq 1 ]]; then
    printf '[dry-run] %q' "$1"
    shift
    if [[ "$#" -gt 0 ]]; then
      printf ' %q' "$@"
    fi
    printf '\n'
  else
    command "$@"
  fi
}

auth_github() {
  if ! command -v gh >/dev/null 2>&1; then
    printf '[warn] missing command: gh\n' >&2
    return
  fi

  status 'GitHub CLI'
  if [[ "$DRY_RUN" -eq 1 ]]; then
    printf '[dry-run] gh auth status\n'
    printf '[dry-run] gh auth login # if not authenticated\n'
    return
  fi

  if gh auth status >/dev/null 2>&1; then
    run gh auth status
  elif can_prompt; then
    run gh auth login
  else
    printf '[warn] GitHub CLI is not authenticated\n'
    printf '[hint] run: gh auth login\n'
  fi
}

auth_codex() {
  if ! command -v codex >/dev/null 2>&1; then
    printf '[warn] missing command: codex\n' >&2
    return
  fi

  status 'Codex'
  if [[ "$DRY_RUN" -eq 1 ]]; then
    printf '[dry-run] codex doctor\n'
    printf '[dry-run] codex login # if auth is unhealthy\n'
    return
  fi

  if codex doctor >/dev/null 2>&1; then
    run codex doctor
  elif can_prompt; then
    run codex login
  else
    printf '[warn] Codex auth is not healthy\n'
    printf '[hint] run: codex login\n'
  fi
}

auth_pi() {
  if ! command -v pi >/dev/null 2>&1; then
    printf '[warn] missing command: pi\n' >&2
    return
  fi

  status 'Pi coding agent'
  if [[ -n "${GOOGLE_API_KEY:-}${GEMINI_API_KEY:-}${ANTHROPIC_API_KEY:-}${OPENAI_API_KEY:-}" ]]; then
    printf '[ok] provider API key environment is present\n'
  else
    printf '[warn] no provider API key environment found\n'
    printf '[hint] add keys to ~/.config/dotfiles/local.env, then restart your shell\n'
  fi
}

auth_github
auth_codex
auth_pi

printf '\n[auth] complete\n'
