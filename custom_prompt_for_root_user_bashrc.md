```bash

# Alias definitions.
# You may want to put all your additions into a separate file like
# ~/.bash_aliases, instead of adding them here directly.
# See /usr/share/doc/bash-doc/examples in the bash-doc package.

if [ -f ~/.bash_aliases ]; then
  . ~/.bash_aliases
fi

# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi

# VIM mode for bash prompt
#set -o vi

# Terminal
export TERM=xterm-256color


# colorize output
export GRC_ALIASES=true

#path
export PATH=$PATH:/home/linuxbrew/.linuxbrew/bin:/home/linuxbrew/.linuxbrew/sbin/


# preferred text editor
export EDITOR="hx"

#homebrew
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

#ble.sh
source ~/.local/share/blesh/ble.sh

# Colorful manpages
# Add to your shell config (e.g., ~/.bashrc, ~/.zshrc)
eval "$(batman --export-env)"

#bat theme
export BAT_THEME="Coldark-Dark"

# greet me
echo "w3lc0m3 h4ck3r - let the games begin! - m4ast3r y0ur cr4ft" | lolcat

[[ -f ~/.bash-preexec.sh ]] && source ~/.bash-preexec.sh

# Carapace
# export CARAPACE_BRIDGES='zsh,fish,bash,inshellisense'
# source <(carapace _carapace)

# Enable vi mode
# set -o vi

# # Set vi mode key bindings
# bind '"\e[A": history-search-backward'
# bind '"\e[B": history-search-forward'
# bind '"\e[C": forward-char'
# bind '"\e[D": backward-char'

# # Disable command editing
# set +o vi-command

# Kitty ssh config alias
alias s="kitten ssh"

# command line tool thef@#k
eval "$(thefuck --alias)"

# Rust
#. "$HOME/.cargo/env"

# Atuin
eval "$(atuin init bash)"

# zoxide
eval "$(zoxide init bash)"

#starship prompt - shell prompt
eval "$(starship init bash)"


```
