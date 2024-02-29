#!/bin/zsh
- install mac cli tools
- install homebrew
```
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

- add homebrew to shell
```
(echo; echo 'eval "$(/opt/homebrew/bin/brew shellenv)"') >> /Users/ec938378/.zprofile
eval "$(/opt/homebrew/bin/brew shellenv)"
```
- brew install chezmoi
- chezmoi init santanajames --apply
- volta install node

ssh-keygen -t ed25519 -C "santana.james@gmail.com"
eval "$(ssh-agent -s)"
code ~/.ssh/config
```
Host github.com
  AddKeysToAgent yes
  IdentityFile ~/.ssh/id_ed25519
```
ssh-add ~/.ssh/id_ed25519
pbcopy < ~/.ssh/id_ed25519.pub

# ---------------
# MacOS
# ---------------

# Core
# =====
# Turn off startup sound
sudo nvram SystemAudioVolume=" "

# Finder
# =====
# Disable screenshot shadow when capturing an app
defaults write com.apple.screencapture disable-shadow -bool true
# Show all file extensions inside the Finder
defaults write NSGlobalDomain AppleShowAllExtensions -bool true
# Show hidden files inside the Finder
defaults write com.apple.finder AppleShowAllFiles -bool true
# Show path bar
defaults write com.apple.finder ShowPathbar -bool true
# Search the current folder
defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"
# Remove the delay when hovering the toolbar title
defaults write NSGlobalDomain NSToolbarTitleViewRolloverDelay -float 0
# Show the Finder status bar
defaults write com.apple.finder ShowStatusBar -bool true

# Menu Bar
# Show battery Percentage
defaults write com.apple.menuextra.battery ShowPercent -string "YES"

# Mission Control
# =====
# Do not reorder Spaces based on most recent use
defaults write com.apple.dock "mru-spaces" -bool false

killall Finder

# Git 
# ---------------
git config --global user.name "Santana James"
git config --global user.email "santana.james@gmail.com"
git config --global core.editor "code --wait"
git config --global merge.tool vscode
git config --global mergetool.vscode.cmd "code --wait $MERGED"
git config --global push.default simple

# Homebrew
# ---------------
if test ! $(which brew); then
  echo "==== Installing Homebrew ===="
  /bin/zsh -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

brew update
brew upgrade
brew bundle
brew cleanup

source ~/.zshrc