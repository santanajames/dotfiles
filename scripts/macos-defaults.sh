#!/usr/bin/env bash

set -euo pipefail

printf '[macos] applying defaults\n'

defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false
defaults write NSGlobalDomain InitialKeyRepeat -int 15
defaults write NSGlobalDomain KeyRepeat -int 2
defaults write com.apple.dock autohide -bool true
defaults write com.apple.dock autohide-delay -float 0
defaults write com.apple.dock expose-animation-duration -float 0.1
defaults write com.apple.finder AppleShowAllFiles -bool true
defaults write com.apple.finder AppleShowAllExtensions -bool true
defaults write com.apple.finder ShowPathbar -bool true
defaults write com.apple.finder _FXSortFoldersFirst -bool true
defaults write com.apple.screencapture location -string "$HOME/Desktop"

killall Dock >/dev/null 2>&1 || true
killall Finder >/dev/null 2>&1 || true
