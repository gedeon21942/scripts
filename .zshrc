# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="agnosterzak"

plugins=(
    git
    archlinux
    zsh-autosuggestions
    zsh-syntax-highlighting
)

autoload -Uz compinit
compinit -U


source $ZSH/oh-my-zsh.sh

# Check archlinux plugin commands here
# https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/archlinux

# Display Pokemon-colorscripts
# Project page: https://gitlab.com/phoneybadger/pokemon-colorscripts#on-other-distros-and-macos
#pokemon-colorscripts --no-title -s -r #without fastfetch
#pokemon-colorscripts --no-title -s -r | fastfetch -c $HOME/.config/fastfetch/config-pokemon.jsonc --logo-type file-raw --logo-height 10 --logo-width 5 --logo -

# fastfetch. Will be disabled if above colorscript was chosen to install
fastfetch -c $HOME/.config/fastfetch/config-compact.jsonc

# Set-up icons for files/folders in terminal
alias ls='eza -a --icons'
alias ll='eza -al --icons'
alias lt='eza -a --tree --level=1 --icons'
alias installs='sudo pacman -S --noconfirm'
alias update='sudo pacman -Syu --noconfirm'
alias zshrc='sudo vim .zshrc && source .zshrc'
alias magic=' ssh nortron@192.168.1.46'
alias unraid='ssh root@192.168.1.12'
alias key='sudo vim .config/hypr/configs/Keybinds.conf'
alias shutdown='sudo shutdown now'
alias exe='sudo chmod +x'
alias stop='bash .local/share/scripts/stopwork.sh'
alias win11='bash . local/share/scripts/win11.sh'
alias archy='bash .local/share/scripts/Archy.sh'
alias munraid='bash .local/share/scripts/unraid.sh'
alias uunraid='bash .local/share/scripts/uunraid.sh'
alias umount='bash .local/share/scripts/uunraid.sh && sudo umount /mnt/share/timeshift'
alias backup='bash .local/share/scripts/backup.sh'
alias titus='curl -fsSL christitus.com/linux | sh'
# Set-up FZF key bindings (CTRL R for fuzzy history finder)
source <(fzf --zsh)
eval "$(zoxide init bash)"
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt appendhistory
