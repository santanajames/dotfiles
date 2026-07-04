# macOS login shells run /etc/zprofile after .zshenv, which can move /usr/bin
# ahead of Homebrew via path_helper. Re-apply Homebrew here so brew tools win.
typeset -U path PATH

if [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -x /usr/local/bin/brew ]]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi

path=("$HOME/.local/bin" "$HOME/bin" $path)

if [[ -z "${JAVA_HOME:-}" && -d /Library/Java/JavaVirtualMachines/zulu-17.jdk/Contents/Home ]]; then
  export JAVA_HOME="/Library/Java/JavaVirtualMachines/zulu-17.jdk/Contents/Home"
fi

if [[ -z "${ANDROID_HOME:-}" && -d "$HOME/Library/Android/sdk" ]]; then
  export ANDROID_HOME="$HOME/Library/Android/sdk"
fi

if [[ -n "${ANDROID_HOME:-}" && -d "$ANDROID_HOME/emulator" ]]; then
  path+=("$ANDROID_HOME/emulator")
fi

if [[ -n "${ANDROID_HOME:-}" && -d "$ANDROID_HOME/platform-tools" ]]; then
  path+=("$ANDROID_HOME/platform-tools")
fi
