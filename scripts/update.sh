#!/usr/bin/env bash

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROFILE_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/dotfiles/profile"
PROFILE="personal"

if [[ -f "$PROFILE_FILE" ]]; then
  PROFILE="$(tr -d '[:space:]' < "$PROFILE_FILE")"
fi

if command -v brew >/dev/null 2>&1; then
  export HOMEBREW_CASK_OPTS="--appdir=/Applications --force"

  brew update
  brew upgrade
  brew bundle install --file "$REPO_ROOT/Brewfile"
  if [[ -f "$REPO_ROOT/Brewfile.$PROFILE" ]]; then
    brew bundle install --file "$REPO_ROOT/Brewfile.$PROFILE"
  fi
  if [[ -f "$REPO_ROOT/Brewfile.local" ]]; then
    brew bundle install --file "$REPO_ROOT/Brewfile.local"
  fi
  brew cleanup
fi

if command -v stow >/dev/null 2>&1; then
  stow --dir "$REPO_ROOT" --target "$HOME" --restow common "$PROFILE"
else
  printf '[warn] missing command: stow\n' >&2
fi

printf '[update] complete\n'
