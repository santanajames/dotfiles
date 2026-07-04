#!/usr/bin/env bash

set -euo pipefail

REPO_URL="${DOTFILES_REPO_URL:-https://github.com/santanajames/dotfiles.git}"
TARGET_DIR="${DOTFILES_DIR:-$HOME/code/dotfiles}"

log() {
  printf '[bootstrap] %s\n' "$*"
}

fail() {
  printf '[bootstrap] %s\n' "$*" >&2
  exit 1
}

detect_brew_prefix() {
  if [[ -x /opt/homebrew/bin/brew ]]; then
    printf '/opt/homebrew\n'
  elif [[ -x /usr/local/bin/brew ]]; then
    printf '/usr/local\n'
  else
    return 1
  fi
}

apply_brew_shellenv() {
  local brew_prefix

  brew_prefix="$(detect_brew_prefix || true)"
  if [[ -n "$brew_prefix" ]]; then
    eval "$("$brew_prefix"/bin/brew shellenv)"
  fi
}

install_homebrew() {
  if command -v brew >/dev/null 2>&1; then
    return
  fi

  if ! id -Gn | tr ' ' '\n' | grep -qx 'admin'; then
    fail "Homebrew installation requires a macOS administrator account for sudo access. Current user '$USER' is not in the admin group."
  fi

  if [[ -t 0 && -t 1 ]]; then
    log 'Requesting administrator access for Homebrew installation'
    sudo -v
    log 'Installing Homebrew'
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  elif sudo -n -v >/dev/null 2>&1; then
    log 'Installing Homebrew'
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  else
    fail 'Homebrew installation needs sudo access. Rerun bootstrap in an interactive terminal so macOS can prompt for your password, or run sudo -v first.'
  fi

  apply_brew_shellenv
}

ensure_git() {
  if command -v git >/dev/null 2>&1; then
    return
  fi

  if ! command -v brew >/dev/null 2>&1; then
    fail 'brew is required to install git'
  fi

  log 'Installing git'
  brew install git
}

install_homebrew
apply_brew_shellenv
ensure_git

mkdir -p "$(dirname "$TARGET_DIR")"

if [[ -d "$TARGET_DIR/.git" ]]; then
  git -C "$TARGET_DIR" pull --ff-only
else
  git clone "$REPO_URL" "$TARGET_DIR"
fi

exec "$TARGET_DIR/setup.sh" "$@"
