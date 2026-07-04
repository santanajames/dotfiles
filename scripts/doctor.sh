#!/usr/bin/env bash

set -euo pipefail

check_command() {
  local name="$1"
  if command -v "$name" >/dev/null 2>&1; then
    printf '[ok] %s\n' "$name"
  else
    printf '[warn] missing command: %s\n' "$name"
  fi
}

check_app() {
  local app_name="$1"
  if [[ -d "/Applications/$app_name.app" ]]; then
    printf '[ok] %s.app\n' "$app_name"
  else
    printf '[warn] missing app: %s.app\n' "$app_name"
  fi
}

printf '[doctor] validating toolchain\n'

check_command brew
check_app cmux
check_command code
check_command gh
check_command git
check_command mise
check_command pi
check_command pnpm
check_command stow
check_command tmux
check_command uv
check_command xh
check_command yazi
check_command zsh

if [[ -f "${XDG_CONFIG_HOME:-$HOME/.config}/dotfiles/profile" ]]; then
  printf '[ok] profile file present\n'
else
  printf '[warn] missing profile file\n'
fi

if [[ -f "$HOME/.zshrc" ]]; then
  printf '[ok] ~/.zshrc present\n'
else
  printf '[warn] missing ~/.zshrc\n'
fi

if [[ -L "$HOME/.zshrc" ]]; then
  printf '[ok] ~/.zshrc is stowed\n'
else
  printf '[warn] ~/.zshrc is not a symlink\n'
fi

git_local_file="${XDG_CONFIG_HOME:-$HOME/.config}/dotfiles/git.local"
if [[ -f "$git_local_file" ]]; then
  if grep -Eq 'Your Name|you@example.com|your-handle' "$git_local_file"; then
    printf '[warn] git.local still has placeholder identity values\n'
  else
    printf '[ok] git.local has non-placeholder values\n'
  fi
else
  printf '[warn] missing git.local\n'
fi
