#!/usr/bin/env bash

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if command -v brew >/dev/null 2>&1; then
  printf '[capture] refreshing Brewfile from installed Homebrew state\n'
  brew bundle dump --file "$REPO_ROOT/Brewfile" --force --no-describe
else
  printf '[warn] missing command: brew\n' >&2
fi

printf '[capture] repo changes\n'
git -C "$REPO_ROOT" status --short

printf '\n[capture] possible untracked config to review manually\n'
find "$HOME/.config" -maxdepth 2 -type f \
  -not -path "$HOME/.config/dotfiles/*" \
  -not -path "$HOME/.config/homebrew/*" \
  -not -path "*/node_modules/*" \
  -print 2>/dev/null |
  sed "s#^$HOME/##" |
  sort
