# dotfiles

macOS dev-machine setup using Homebrew + GNU Stow.

## First Run

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/santanajames/dotfiles/main/bootstrap.sh)"
```

Bootstrap installs Homebrew if missing, uses it to install Git if needed,
clones this repo, then opens the setup menu.

To run a profile directly:

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/santanajames/dotfiles/main/bootstrap.sh)" -- --profile personal
bash -c "$(curl -fsSL https://raw.githubusercontent.com/santanajames/dotfiles/main/bootstrap.sh)" -- --profile work
```

## Daily Flow

Managed files are symlinks into this repo, so normal edits are captured by Git:

```bash
vim ~/.zshrc
cd ~/code/dotfiles
git diff
git add common/.zshrc
git commit -m "Update zsh config"
```

Refresh installed Homebrew state when you intentionally change apps:

```bash
./scripts/capture.sh
```

`capture.sh` rewrites the shared `Brewfile` from the currently installed
Homebrew state. Move personal or work-only entries into `Brewfile.personal`,
`Brewfile.work`, or `Brewfile.local` before committing.

Update this machine from the repo:

```bash
git pull
./scripts/update.sh
```

Run interactive auth checks:

```bash
./scripts/auth.sh
```

Use the lightweight menu:

```bash
./setup.sh
```

Preview menu actions without running them:

```bash
./setup.sh --dry-run
```

## Layout

- `common/`: shared Stow package
- `personal/`, `work/`: profile-specific Stow packages
- `Brewfile`: shared Homebrew packages
- `Brewfile.personal`, `Brewfile.work`: profile package overlays
- `Brewfile.local`: optional untracked machine/employer package overlay
- `templates/`: starter files for local-only config
- `scripts/auth.sh`: interactive auth for GitHub CLI, Codex, and Pi

Switching profiles installs the shared Brewfile plus the matching profile
overlay unless you pass `--skip-brew`.
Use `--skip-brew` only for a fast config-only switch.

## Local Secrets

Keep these local and untracked:

- `~/.config/dotfiles/local.env`
- `~/.config/dotfiles/git.local`
- `~/.config/dotfiles/git-work.local`
- `~/.config/dotfiles/git-personal.local`
- `~/.config/dotfiles/zsh.local`

Use `templates/git-personal.local.example` and
`templates/git-work.local.example` as starting points for the Git identity
files. The committed `common/.gitconfig` owns the routing rules; the local
files own the real names, emails, and GitHub handles.

## Runtime Management

`mise` pins global Node/Python defaults in `~/.config/mise/config.toml` and handles
per-project runtime versions. Homebrew owns CLI apps; mise owns runtimes.
