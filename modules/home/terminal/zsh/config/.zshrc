# Paths and environment
export PATH="/usr/local/bin:$PATH"
export NIX_SHELL='zsh -i'
export ZED_ALLOW_ROOT=true

# History: shared between sessions, deduplicated and resilient.
HISTFILE="$HOME/.histfile"
HISTSIZE=50000
SAVEHIST=50000
setopt APPEND_HISTORY
setopt EXTENDED_HISTORY
setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_FIND_NO_DUPS
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_REDUCE_BLANKS
setopt INC_APPEND_HISTORY
setopt SHARE_HISTORY

# Useful interactive defaults.
setopt AUTO_CD
setopt AUTO_PUSHD
setopt COMPLETE_IN_WORD
setopt INTERACTIVE_COMMENTS
setopt PUSHD_IGNORE_DUPS
setopt PUSHD_SILENT
unsetopt BEEP

# Completion with caching and friendly, case-insensitive matching.
autoload -Uz compinit
zmodload zsh/complist
mkdir -p "${XDG_CACHE_HOME:-$HOME/.cache}/zsh"
compinit -d "${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompdump-$ZSH_VERSION"
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*'
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "${XDG_CACHE_HOME:-$HOME/.cache}/zsh/completion"
zstyle ':completion:*' group-name ''
zstyle ':completion:*:descriptions' format '%F{cyan}%B%d%b%f'
zstyle ':completion:*:warnings' format '%F{red}No hay coincidencias%f'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

# Vi editing plus predictable history search.
bindkey -v
export KEYTIMEOUT=15
autoload -Uz up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey '^[[A' up-line-or-beginning-search
bindkey '^[[B' down-line-or-beginning-search
bindkey -M vicmd 'k' up-line-or-beginning-search
bindkey -M vicmd 'j' down-line-or-beginning-search
bindkey '^R' history-incremental-pattern-search-backward
bindkey '^[[H' beginning-of-line
bindkey '^[[F' end-of-line
bindkey '^[[3~' delete-char

# Esc Esc prepends sudo, matching the useful Oh My Zsh sudo plugin behavior.
function sudo-command-line() {
  [[ -z "$BUFFER" ]] && zle up-history
  if [[ "$BUFFER" == sudo\ * ]]; then
    BUFFER="${BUFFER#sudo }"
  else
    BUFFER="sudo $BUFFER"
  fi
  CURSOR=${#BUFFER}
}
zle -N sudo-command-line
bindkey -M emacs '\e\e' sudo-command-line
bindkey -M viins '\e\e' sudo-command-line

# Directory history (Alt+Left/Right) backed by Zsh's directory stack.
function dir-back() { builtin cd -q -- "${dirstack[2]:-$OLDPWD}" }
function dir-forward() { builtin pushd -q +1 >/dev/null 2>&1 }
zle -N dir-back
zle -N dir-forward
bindkey '^[[1;3D' dir-back
bindkey '^[[1;3C' dir-forward

# Archive extraction without the Oh My Zsh extract plugin.
function extract() {
  if (( $# == 0 )); then
    print 'Uso: extract <archivo> [...]'
    return 1
  fi
  local archive
  for archive in "$@"; do
    if [[ ! -f "$archive" ]]; then
      print -u2 "extract: no existe: $archive"
      continue
    fi
    case "$archive" in
      (*.tar.bz2|*.tbz2) tar xjf "$archive" ;;
      (*.tar.gz|*.tgz)   tar xzf "$archive" ;;
      (*.tar.xz|*.txz)   tar xJf "$archive" ;;
      (*.tar.zst|*.tzst) tar --zstd -xf "$archive" ;;
      (*.tar)            tar xf "$archive" ;;
      (*.bz2)            bunzip2 "$archive" ;;
      (*.gz)             gunzip "$archive" ;;
      (*.xz)             unxz "$archive" ;;
      (*.zip)            unzip "$archive" ;;
      (*.7z)             7z x "$archive" ;;
      (*.rar)            unrar x "$archive" ;;
      (*) print -u2 "extract: formato no reconocido: $archive" ;;
    esac
  done
}

# Portable clipboard helpers (Wayland first, then X11).
function _copy-stdin() {
  if (( $+commands[wl-copy] )); then wl-copy
  elif (( $+commands[xclip] )); then xclip -selection clipboard
  elif (( $+commands[xsel] )); then xsel --clipboard --input
  else print -u2 'No se encontró wl-copy, xclip ni xsel'; return 1
  fi
}
function copyfile() { [[ -f "$1" ]] && _copy-stdin < "$1" || { print -u2 'Uso: copyfile <archivo>'; return 1; } }
function copypath() { print -rn -- "${1:a}" | _copy-stdin }

# Browser search compatible with the old web-search workflow.
function web-search() {
  local engine=${1:-google}
  (( $# )) && shift
  local base
  case "$engine" in
    (google)     base='https://www.google.com/search?q=' ;;
    (github)     base='https://github.com/search?q=' ;;
    (stackoverflow|so) base='https://stackoverflow.com/search?q=' ;;
    (youtube)    base='https://www.youtube.com/results?search_query=' ;;
    (*) set -- "$engine" "$@"; base='https://www.google.com/search?q=' ;;
  esac
  local query="${(j:+:)${(q)@}}"
  nohup xdg-open "${base}${query}" >/dev/null 2>&1 &!
}
alias google='web-search google'
alias github-search='web-search github'
alias youtube='web-search youtube'

# Better colored man pages.
export LESS_TERMCAP_mb=$'\e[1;31m'
export LESS_TERMCAP_md=$'\e[1;36m'
export LESS_TERMCAP_me=$'\e[0m'
export LESS_TERMCAP_so=$'\e[01;44;33m'
export LESS_TERMCAP_se=$'\e[0m'
export LESS_TERMCAP_us=$'\e[1;32m'
export LESS_TERMCAP_ue=$'\e[0m'

# Interactive tools. These guards keep rescue shells usable.
(( $+commands[zoxide] )) && eval "$(zoxide init zsh)"
(( $+commands[pay-respects] )) && eval "$(pay-respects zsh)"
(( $+commands[starship] )) && eval "$(starship init zsh)"

# Start an SSH agent only when the session has none available.
if [[ -z "$SSH_AUTH_SOCK" ]] && (( $+commands[ssh-agent] )); then
  eval "$(ssh-agent -s)" >/dev/null
  ssh-add "$HOME/.ssh/id_ed25519" 2>/dev/null
fi
