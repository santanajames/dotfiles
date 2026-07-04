# ── 1. Guard: non-interactive shells ─────────────────────────────────────────
[[ $- != *i* ]] && return

# ── 2. History ────────────────────────────────────────────────────────────────
HISTFILE="${XDG_STATE_HOME:-$HOME/.local/state}/zsh/history"
HISTSIZE=50000
SAVEHIST=50000
mkdir -p "${HISTFILE:h}"

setopt HIST_IGNORE_DUPS       # don't record consecutive duplicate commands
setopt HIST_IGNORE_SPACE      # don't record commands starting with a space
setopt HIST_REDUCE_BLANKS     # remove superfluous blanks from history
setopt HIST_VERIFY            # show expanded history before executing
setopt SHARE_HISTORY          # share history across sessions in real time (implies append + inc_append)

# ── 3. Shell options ──────────────────────────────────────────────────────────
setopt AUTO_CD                # type a dir name to cd into it
setopt AUTO_PUSHD             # cd pushes old dir onto stack
setopt PUSHD_IGNORE_DUPS      # don't push duplicate dirs
setopt INTERACTIVE_COMMENTS   # allow comments in interactive shell
setopt EXTENDED_GLOB          # extended globbing patterns
setopt NO_BEEP                # silence all bells

# ── 4. Plugins via sheldon ────────────────────────────────────────────────────
# sheldon caches compiled scripts in ~/.cache/sheldon — fast after first run.
# Plugins loaded (in order): zsh-completions (fpath), zsh-syntax-highlighting,
# zsh-autosuggestions, zsh-history-substring-search, fzf-tab, zsh-autopair
eval "$(sheldon source)"

# ── 5. Completion ─────────────────────────────────────────────────────────────
# compinit runs after sheldon so fpath from zsh-completions is already set.
# -C skips the security check on subsequent runs (reads cached zcompdump).
autoload -Uz compinit
_zcompdump="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompdump"
mkdir -p "${_zcompdump:h}"
if [[ -n $_zcompdump(#qN.mh+24) ]]; then
  compinit -d "$_zcompdump"       # full init: zcompdump is stale (>24h)
else
  compinit -C -d "$_zcompdump"    # fast init: skip security check
fi
unset _zcompdump

# fzf-tab config — must come after compinit
zstyle ':completion:*:descriptions' format '[%d]'        # show group labels
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"  # colorize completions
zstyle ':fzf-tab:*' switch-group '<' '>'                 # switch groups with < >

# Generic preview: bat for files, eza tree for directories
zstyle ':fzf-tab:complete:*:*' fzf-preview \
  '([[ -d $realpath ]] && eza --tree --color=always --level=2 $realpath || bat --color=always --style=numbers $realpath) 2>/dev/null'
# cd: dedicated fast directory preview (overrides generic rule above)
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza --tree --color=always --level=2 $realpath'
# kill/killall: show process details when completing PIDs
zstyle ':fzf-tab:complete:(kill|killall):argument-rest' fzf-preview \
  '[[ $group == "[process ID]" ]] && ps -p $word -o pid,user,%cpu,command'
# git checkout: show branch log or commit info
zstyle ':fzf-tab:complete:git-checkout:*' fzf-preview \
  'git log --oneline --graph --color=always $word 2>/dev/null || git show --color=always $word 2>/dev/null'
# git add/diff/restore: show working-tree diff
zstyle ':fzf-tab:complete:git-(add|diff|restore):*' fzf-preview \
  'git diff --color=always -- $word 2>/dev/null | head -100'
# env vars: expand current value
zstyle ':fzf-tab:complete:(-command-|-parameter-|-brace-parameter-|export|unset):*' fzf-preview \
  'echo ${(P)word}'
# brew: show formula / cask info
zstyle ':fzf-tab:complete:brew-(install|uninstall|search|info):*-argument-rest' fzf-preview \
  'brew info $word 2>/dev/null'

# ── 6. Tool integrations ──────────────────────────────────────────────────────
# fzf — use built-in shell integration (fzf 0.46+), replaces brew --prefix calls
if command -v fzf >/dev/null 2>&1; then
  eval "$(fzf --zsh)"
  # fd as default command: faster, respects .gitignore, includes hidden files
  export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
  export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
  export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
  # Global options — Rose Pine Dawn colours, reverse layout, rounded border
  export FZF_DEFAULT_OPTS='
    --height=50% --layout=reverse --border=rounded
    --bind=ctrl-/:toggle-preview
    --bind=ctrl-u:preview-half-page-up,ctrl-d:preview-half-page-down
    --color=bg:#faf4ed,bg+:#f2e9e1,fg:#575279,fg+:#575279
    --color=hl:#b4637a,hl+:#b4637a,spinner:#286983,pointer:#286983
    --color=header:#b4637a,info:#907aa9,prompt:#907aa9,marker:#56949f'
  # Ctrl-T: bat preview for files, eza tree for directories
  export FZF_CTRL_T_OPTS='
    --preview "([[ -d {} ]] && eza --tree --color=always --level=2 {} || bat --color=always --style=numbers {}) 2>/dev/null"
    --bind "ctrl-/:change-preview-window(right|down|hidden|)"'
  # Alt-C: directory tree preview
  export FZF_ALT_C_OPTS='--preview "eza --tree --color=always --level=2 {}"'
  # Ctrl-R: show full command in preview pane; ? to toggle
  export FZF_CTRL_R_OPTS='
    --preview "echo {}" --preview-window=down:3:wrap
    --bind "?:toggle-preview"'
fi

# mise — runtime version manager
if command -v mise >/dev/null 2>&1; then
  eval "$(mise activate zsh)"
fi

# direnv — per-directory environment
if command -v direnv >/dev/null 2>&1; then
  eval "$(direnv hook zsh)"
fi

# zoxide — smarter cd with frecency ranking (exposes z and zi commands)
if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init zsh)"
fi

# ── 7. Prompt — starship ──────────────────────────────────────────────────────
if command -v starship >/dev/null 2>&1; then
  eval "$(starship init zsh)"
fi

# ── 8. Key bindings ───────────────────────────────────────────────────────────
# history-substring-search: bind up/down arrows after plugin is loaded
bindkey '^[[A' history-substring-search-up    # up arrow
bindkey '^[[B' history-substring-search-down  # down arrow
bindkey '^P'   history-substring-search-up    # Ctrl-P
bindkey '^N'   history-substring-search-down  # Ctrl-N

# ── 9. Aliases ────────────────────────────────────────────────────────────────

# -- Brew
alias b='brew'
alias bi='brew install'
alias bl='brew list'
alias bu='brew update && brew upgrade && brew cleanup'
alias bs='brew search'

# -- Files & navigation
alias ls='eza --group-directories-first'
alias ll='eza -lah --group-directories-first --git'
alias cat='bat --paging=never'

# -- Git
alias g='git'
alias ga='git add'
alias gb='git branch'
alias gbda='git branch -d $(git branch --merged | grep -v "\*" | grep -v "main" | grep -v "master")'
alias gc='git commit'
alias gco='git checkout'
alias gd='git diff'
alias gl='git pull'
alias glo='git log --oneline --decorate --graph -20'
alias gp='git push'
alias gst='git status -sb'
alias gt='git tag'
alias grhh='git reset --hard HEAD'
alias gwt='git worktree'

alias ghr='gh repo'

# -- Pnpm
alias p='pnpm'

# -- Dotfiles
alias dotfiles='git -C "$HOME/code/dotfiles"'
alias dotstow='stow --dir "$HOME/code/dotfiles" --target "$HOME" --restow common "$DOTFILES_PROFILE"'
alias dotmenu='$HOME/code/dotfiles/setup.sh'

# ── 10. Profile-specific config ───────────────────────────────────────────────
alias cleanup-node='find . -name node_modules -type d -prune -exec rm -rf {} +'

# ── 11. Functions ─────────────────────────────────────────────────────────────

# rfv: live ripgrep → fzf → VS Code  (usage: rfv [QUERY])
# Type to search; results reload on every keystroke. Enter opens in VS Code.
# TAB/SHIFT-TAB to multi-select, alt-a/alt-d to select/deselect all.
rfv() (
  RELOAD='reload:rg --column --color=always --smart-case {q} || :'
  OPENER='if [[ $FZF_SELECT_COUNT -eq 0 ]]; then
            code -g {1}:{2}
          else
            while read -r sel; do
              f=$(echo "$sel" | cut -d: -f1)
              l=$(echo "$sel" | cut -d: -f2)
              code -g "$f:$l"
            done < {+f}
          fi'
  fzf --disabled --ansi --multi \
      --bind "start:$RELOAD" --bind "change:$RELOAD" \
      --bind "enter:execute:$OPENER" \
      --bind 'alt-a:select-all,alt-d:deselect-all,ctrl-/:toggle-preview' \
      --delimiter : \
      --preview 'bat --style=full --color=always --highlight-line {2} {1}' \
      --preview-window '~4,+{2}+4/3,<80(up)' \
      --query "$*"
)

# yazi: file manager — cd to the last directory visited on exit
function y() {
  local tmp cwd
  tmp="$(mktemp -t "yazi-cwd.XXXXXX")" || return
  yazi "$@" --cwd-file="$tmp"
  cwd="$(<"$tmp")"
  [[ -n "$cwd" && "$cwd" != "$PWD" ]] && builtin cd -- "$cwd"
  rm -f -- "$tmp"
}

# ── 12. Local overrides ───────────────────────────────────────────────────────
# Shell-only machine-specific overrides. Put environment variables in
# ~/.config/dotfiles/local.env and keep aliases/functions here.
if [[ -f "${XDG_CONFIG_HOME:-$HOME/.config}/dotfiles/zsh.local" ]]; then
  source "${XDG_CONFIG_HOME:-$HOME/.config}/dotfiles/zsh.local"
fi

# bun completions
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
