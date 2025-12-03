export PATH="/usr/local/bin:$PATH"

# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Lines configured by zsh-newuser-install
HISTFILE=~/.histfile
HISTSIZE=10000
SAVEHIST=10000
bindkey -v
# End of lines configured by zsh-newuser-install
# The following lines were added by compinstall
zstyle :compinstall filename '/home/lafv/.zshrc'

autoload -Uz compinit
compinit
# End of lines added by compinstall

eval "$(pay-respects zsh)"

# Verificar si el agente está corriendo
if [ -z "$SSH_AUTH_SOCK" ]; then
    eval "$(ssh-agent -s)"

    ssh-add ~/.ssh/id_ed25519 2>/dev/null

    # O mejor, verifica primero si ya no está agregada
    if ! ssh-add -l | grep -q "id_ed25519"; then
        ssh-add ~/.ssh/id_ed25519
    fi
fi

# fnm - Fast Node Manager
# export PATH="$HOME/.fnm:$PATH"
# eval "$(fnm env --shell=zsh --use-on-cd)"

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
