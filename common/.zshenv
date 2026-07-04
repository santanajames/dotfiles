export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"

if [[ -f "$XDG_CONFIG_HOME/dotfiles/local.env" ]]; then
  set -a
  . "$XDG_CONFIG_HOME/dotfiles/local.env"
  set +a
fi

export EDITOR="${EDITOR:-code}"
export VISUAL="${VISUAL:-code}"
export PAGER="${PAGER:-less -FRX}"

if [[ -f "$XDG_CONFIG_HOME/dotfiles/profile" ]]; then
  export DOTFILES_PROFILE="$(tr -d '[:space:]' < "$XDG_CONFIG_HOME/dotfiles/profile")"
else
  export DOTFILES_PROFILE="personal"
fi
