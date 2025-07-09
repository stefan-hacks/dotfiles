# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples

# If not running interactively, don't do anything
case $- in
*i*) ;;
*) return ;;
esac

# don't put duplicate lines or lines starting with space in the history.
# See bash(1) for more options
HISTCONTROL=ignoreboth

# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=1000
HISTFILESIZE=2000

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# If set, the pattern "**" used in a pathname expansion context will
# match all files and zero or more directories and subdirectories.
#shopt -s globstar

# make less more friendly for non-text input files, see lesspipe(1)
#[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# set variable identifying the chroot you work in (used in the prompt below)
if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
  debian_chroot=$(cat /etc/debian_chroot)
fi

# enable color support of ls and also add handy aliases
# if [ -x /usr/bin/dircolors ]; then
#   test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
#   #alias ls='ls --color=auto'
#   #alias dir='dir --color=auto'
#   #alias vdir='vdir --color=auto'

#   #alias grep='grep --color=auto'
#   #alias fgrep='fgrep --color=auto'
#   #alias egrep='egrep --color=auto'
# fi

# colored GCC warnings and errors
export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'

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
# export TERM=xterm-256color


# colorize output
export GRC_ALIASES=true

#Brightness control from keybaord
gsettings set org.gnome.settings-daemon.plugins.media-keys screen-brightness-up "['<Ctrl><Super>Up']"
gsettings set org.gnome.settings-daemon.plugins.media-keys screen-brightness-down "['<Ctrl><Super>Down']"

#path
export PATH=/home/linuxbrew/.linuxbrew/bin:/home/linuxbrew/.linuxbrew/sbin:/home/h4ck3r/.local/bin:/home/h4ck3r/.cargo/bin:/snap/bin:$PATH


# preferred text editor
export EDITOR="hx"

#homebrew
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

#ble.sh
source ~/.local/share/blesh/ble.sh

# Colorful manpages
# Add to your shell config (e.g., ~/.bashrc, ~/.zshrc)
export MANPAGER="less -R --use-color -Dd+r -Du+b"

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
. "$HOME/.cargo/env"

# Atuin
eval "$(atuin init bash)"

# zoxide
eval "$(zoxide init bash)"

#starship prompt - shell prompt
eval "$(starship init bash)"


