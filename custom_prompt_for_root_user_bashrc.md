```bash
# terminal prompt for root
PROMPT_COMMAND='PS1_CMD1=$(ip route get 1.1.1.1 | awk -F"src " '"'"'NR == 1{ split($2, a," ");print a[1]}'"'"')'; PS1='\[\e[91;1m\]\u\[\e[0m\]☠️ \[\e[96;1m\]\h\[\e[0m\] \[\e[93;3m\]\w\n\[\e[0;32;2m\]${PS1_CMD1}\[\e[0m\] \[\e[35;2m\]\t\[\e[0m\] \n\[\e[93;2m\]$?\[\e[0m\] \[\e[97;2;5m\]\$\[\e[0m\]: '

# colorize output
GRC_ALIASES=true
[[ -s "/etc/profile.d/grc.sh" ]] && source /etc/grc.sh

#path
export PATH="$PATH:/home/linuxbrew/.linuxbrew/bin/:/usr/games/"

# preferred text editor
#EDITOR=nano

#homebrew
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

#ble.sh
source ~/.local/share/blesh/ble.sh

#most - colorful output for man
#export PAGER=most

#highlight less
# export LESSOPEN="| /usr/bin/highlight %s --out-format xterm256 --force"


# Atuin
. "$HOME/.atuin/bin/env"

[[ -f ~/.bash-preexec.sh ]] && source ~/.bash-preexec.sh
eval "$(atuin init bash)"

# greet me
echo "w3lc0m3 t0 th3 r00t 0f 4ll th1ng5! - m4ast3r y0ur cr4ft" | lolcat
```
