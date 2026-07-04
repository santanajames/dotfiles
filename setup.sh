#!/usr/bin/env bash

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/dotfiles"
PROFILE_FILE="$DOTFILES_CONFIG_DIR/profile"
LOCAL_ENV_FILE="$DOTFILES_CONFIG_DIR/local.env"
GIT_LOCAL_FILE="$DOTFILES_CONFIG_DIR/git.local"
STOW_PACKAGES=(common)
PROFILE=""
RUN_DEFAULTS=1
RUN_BREW=1
RUN_DOCTOR=1
DRY_RUN=0

log() {
  printf '[dotfiles] %s\n' "$*"
}

fail() {
  printf '[dotfiles] %s\n' "$*" >&2
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

usage() {
  cat <<'EOF'
Usage: ./setup.sh [options]

With no options, opens the interactive setup menu.

Options:
  --profile <personal|work>  Set the active dotfiles profile.
  --dry-run                 Print the planned setup actions without running them.
  --skip-brew               Skip Homebrew package installation.
  --skip-defaults           Skip macOS defaults automation.
  --skip-doctor             Skip the final doctor pass.
  -h, --help                Show this help text.
EOF
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --profile)
        PROFILE="$2"
        shift 2
        ;;
      --dry-run)
        DRY_RUN=1
        shift
        ;;
      --skip-brew)
        RUN_BREW=0
        shift
        ;;
      --skip-defaults)
        RUN_DEFAULTS=0
        shift
        ;;
      --skip-doctor)
        RUN_DOCTOR=0
        shift
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      *)
        printf 'Unknown argument: %s\n' "$1" >&2
        usage >&2
        exit 1
        ;;
    esac
  done
}

seed_git_local() {
  cp "$REPO_ROOT/templates/git.local.example" "$GIT_LOCAL_FILE"
  log "Created $GIT_LOCAL_FILE from template"
}

resolve_profile() {
  if [[ -z "$PROFILE" && -f "$PROFILE_FILE" ]]; then
    PROFILE="$(tr -d '[:space:]' < "$PROFILE_FILE")"
  fi

  if [[ -z "$PROFILE" ]]; then
    PROFILE="personal"
  fi

  case "$PROFILE" in
    personal|work)
      ;;
    *)
      printf 'Unsupported profile: %s\n' "$PROFILE" >&2
      exit 1
      ;;
  esac
}

print_dry_run() {
  resolve_profile

  printf '[dry-run] profile=%s\n' "$PROFILE"

  if [[ "$RUN_BREW" -eq 1 ]]; then
    printf '[dry-run] brew bundle install --file %q\n' "$REPO_ROOT/Brewfile"
    if [[ -f "$REPO_ROOT/Brewfile.$PROFILE" ]]; then
      printf '[dry-run] brew bundle install --file %q\n' "$REPO_ROOT/Brewfile.$PROFILE"
    fi
    if [[ -f "$REPO_ROOT/Brewfile.local" ]]; then
      printf '[dry-run] brew bundle install --file %q\n' "$REPO_ROOT/Brewfile.local"
    fi
  else
    printf '[dry-run] skip Homebrew package installation\n'
  fi

  printf '[dry-run] write profile file: %q\n' "$PROFILE_FILE"
  printf '[dry-run] create local config templates if missing\n'
  printf '[dry-run] stow --dir %q --target %q --restow common %q\n' "$REPO_ROOT" "$HOME" "$PROFILE"
  printf '[dry-run] mise install\n'

  if [[ "$RUN_DEFAULTS" -eq 1 ]]; then
    printf '[dry-run] %q\n' "$REPO_ROOT/scripts/macos-defaults.sh"
  else
    printf '[dry-run] skip macOS defaults\n'
  fi

  if [[ "$RUN_DOCTOR" -eq 1 ]]; then
    printf '[dry-run] %q\n' "$REPO_ROOT/scripts/doctor.sh"
  else
    printf '[dry-run] skip doctor\n'
  fi
}

stow_target_for() {
  local package="$1"
  local source_file="$2"
  local relative_path

  relative_path="${source_file#"$REPO_ROOT/$package/"}"
  printf '%s/%s\n' "$HOME" "$relative_path"
}

prepare_stow_targets() {
  local package source_file target_file backup_file timestamp

  timestamp="$(date +%Y%m%d%H%M%S)"

  for package in "${STOW_PACKAGES[@]}"; do
    while IFS= read -r source_file; do
      target_file="$(stow_target_for "$package" "$source_file")"

      if [[ -L "$target_file" || ! -e "$target_file" ]]; then
        continue
      fi

      if [[ -f "$target_file" && -f "$source_file" ]] && cmp -s "$source_file" "$target_file"; then
        rm "$target_file"
        continue
      fi

      backup_file="$target_file.pre-stow.$timestamp"
      mv "$target_file" "$backup_file"
      log "Moved existing $target_file to $backup_file"
    done < <(find "$REPO_ROOT/$package" -type f -print)
  done
}

ensure_local_config() {
  mkdir -p "$DOTFILES_CONFIG_DIR"
  resolve_profile

  if [[ -L "$PROFILE_FILE" ]]; then
    rm "$PROFILE_FILE"
  fi

  printf '%s\n' "$PROFILE" > "$PROFILE_FILE"
  STOW_PACKAGES+=( "$PROFILE" )

  if [[ ! -f "$LOCAL_ENV_FILE" ]]; then
    cp "$REPO_ROOT/templates/local.env.example" "$LOCAL_ENV_FILE"
    log "Created $LOCAL_ENV_FILE"
  fi

  if [[ ! -f "$GIT_LOCAL_FILE" ]]; then
    seed_git_local
  fi
}

install_packages() {
  apply_brew_shellenv

  if ! command -v brew >/dev/null 2>&1; then
    fail 'Homebrew is required. Run bootstrap.sh first, or install Homebrew before running setup.'
  fi

  export HOMEBREW_BUNDLE_FILE="$REPO_ROOT/Brewfile"
  export HOMEBREW_CASK_OPTS="--appdir=/Applications --force"

  log 'Installing Brewfile packages'
  brew bundle install --file "$REPO_ROOT/Brewfile"

  if [[ -f "$REPO_ROOT/Brewfile.$PROFILE" ]]; then
    log "Installing Brewfile.$PROFILE overlay"
    brew bundle install --file "$REPO_ROOT/Brewfile.$PROFILE"
  fi

  if [[ -f "$REPO_ROOT/Brewfile.local" ]]; then
    log 'Installing Brewfile.local overlay'
    brew bundle install --file "$REPO_ROOT/Brewfile.local"
  fi
}

apply_stow() {
  apply_brew_shellenv

  if ! command -v stow >/dev/null 2>&1; then
    fail 'stow is required. Run setup without --skip-brew, or install stow first.'
  fi

  log "Linking dotfiles with stow profile=$PROFILE"
  prepare_stow_targets
  stow --dir "$REPO_ROOT" --target "$HOME" --restow "${STOW_PACKAGES[@]}"
}

install_mise_runtimes() {
  apply_brew_shellenv

  if command -v mise >/dev/null 2>&1; then
    log 'Installing runtimes from mise config'
    mise install
  fi
}

apply_macos_defaults() {
  if [[ "$RUN_DEFAULTS" -eq 1 ]]; then
    "$REPO_ROOT/scripts/macos-defaults.sh"
  fi
}

run_doctor() {
  if [[ "$RUN_DOCTOR" -eq 1 ]]; then
    "$REPO_ROOT/scripts/doctor.sh"
  fi
}

run_setup() {
  resolve_profile

  if [[ "$RUN_BREW" -eq 1 ]]; then
    apply_brew_shellenv
    install_packages
  fi

  ensure_local_config
  apply_stow
  install_mise_runtimes
  apply_macos_defaults
  run_doctor

  log 'Setup complete'
}

run_menu_action() {
  local label="$1"
  shift

  printf '\n[menu] %s\n' "$label"
  "$@"
}

preview_menu_action() {
  local label="$1"
  shift

  printf '\n[menu] %s\n' "$label"
  if [[ "$DRY_RUN" -eq 1 ]]; then
    printf '[dry-run] %q' "$1"
    shift
    if [[ "$#" -gt 0 ]]; then
      printf ' %q' "$@"
    fi
    printf '\n'
  else
    "$@"
  fi
}

show_menu() {
  local choice

  while true; do
    cat <<'EOF'

dotfiles
1) Setup personal
2) Setup work
3) Update active profile
4) Auth
5) Doctor
6) Capture Brewfile
7) Quit
EOF

    read -r -p '> ' choice

    case "$choice" in
      1)
        if [[ "$DRY_RUN" -eq 1 ]]; then
          run_menu_action 'setup personal' "$REPO_ROOT/setup.sh" --profile personal --dry-run
        else
          run_menu_action 'setup personal' "$REPO_ROOT/setup.sh" --profile personal
        fi
        ;;
      2)
        if [[ "$DRY_RUN" -eq 1 ]]; then
          run_menu_action 'setup work' "$REPO_ROOT/setup.sh" --profile work --dry-run
        else
          run_menu_action 'setup work' "$REPO_ROOT/setup.sh" --profile work
        fi
        ;;
      3) preview_menu_action 'update active profile' "$REPO_ROOT/scripts/update.sh" ;;
      4)
        if [[ "$DRY_RUN" -eq 1 ]]; then
          run_menu_action 'auth' "$REPO_ROOT/scripts/auth.sh" --dry-run
        else
          run_menu_action 'auth' "$REPO_ROOT/scripts/auth.sh"
        fi
        ;;
      5) preview_menu_action 'doctor' "$REPO_ROOT/scripts/doctor.sh" ;;
      6) preview_menu_action 'capture Brewfile' "$REPO_ROOT/scripts/capture.sh" ;;
      7|q|quit|exit) exit 0 ;;
      *) printf '[warn] unknown option: %s\n' "$choice" >&2 ;;
    esac
  done
}

main() {
  local arg_count="$#"

  parse_args "$@"

  if [[ "$arg_count" -eq 0 || ( "$DRY_RUN" -eq 1 && -z "$PROFILE" ) ]]; then
    show_menu
  fi

  if [[ "$DRY_RUN" -eq 1 ]]; then
    print_dry_run
    exit 0
  fi

  run_setup
}

main "$@"
