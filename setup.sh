#!/bin/zsh

# MacOS
# ---------------
# Core
sudo nvram SystemAudioVolume=" "
defaults write com.apple.menuextra.battery ShowPercent -string "YES"
# Finder
defaults write NSGlobalDomain AppleShowAllExtensions -bool true
defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"
defaults write com.apple.finder AppleShowAllFiles YES
defaults write com.apple.finder ShowPathbar -bool true
defaults write com.apple.finder ShowStatusBar -bool true
defaults write com.apple.dock mru-spaces -bool false

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