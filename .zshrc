# ---------------------------
# Paths & environment early
# ---------------------------
# Homebrew first (Apple Silicon)
export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"

# Prefer python3 if python is missing
if ! command -v python >/dev/null 2>&1 && command -v python3 >/dev/null 2>&1; then
  alias python=python3
fi

# Language
export LANG=en_US.UTF-8

# autoswitch-virtualenv defaults
export AUTOSWITCH_VIRTUAL_ENV_DIR="$HOME/.virtualenvs"  # default already, explicit for clarity
plugins=(autoswitch_virtualenv ${plugins})
# ---------------------------
# Oh My Zsh setup
# ---------------------------
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="robbyrussell"

# Plugins
plugins=(git autoswitch_virtualenv)

# Load Oh My Zsh
source $ZSH/oh-my-zsh.sh

# ---------------------------
# History settings
# ---------------------------
setopt SHARE_HISTORY
setopt INC_APPEND_HISTORY
setopt HIST_IGNORE_ALL_DUPS
HISTSIZE=20000
SAVEHIST=20000
HISTFILE=~/.zsh_history

# Completion init
autoload -U compinit; compinit -i -C

# ---------------------------
# Aliases
# ---------------------------
alias ls='ls -G'
alias gcf='git add . && git commit -m "fix"'
alias gmd='git add . && git commit --amend'
alias top="gotop -c solarized"
alias mypy="mypy --strict --no-warn-return-any --allow-untyped-calls"

# Cursor app opener
function cursor {
  open -a "/Applications/Cursor.app" "$@"
}

# ---------------------------
# Colors for ls
# ---------------------------
export LS_COLORS="di=34:fi=0:ln=36:pi=33:so=35:bd=34;46:cd=34;43:ex=31"
ZLS_COLORS=$LS_COLORS

# ---------------------------
# VCS info
# ---------------------------
autoload -Uz vcs_info
precmd_vcs_info() { vcs_info }
precmd_functions+=( precmd_vcs_info )
setopt prompt_subst
zstyle ':vcs_info:git:*' formats '%F{240}(%b)%a%m%f'
zstyle ':vcs_info:*' enable git

# Custom prompt (comment out if you prefer theme only)
# PROMPT='%B%F{blue}%n%f@%F{red}%m%f:%F{green}%~%f%b${vcs_info_msg_0_}> '

# ---------------------------
# nvm setup
# ---------------------------
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# ---------------------------
# ---------------------------

# ---------------------------
# Applied devtools completions
# ---------------------------

# ---------------------------
# External tools (guarded)
# ---------------------------

# am shell
if command -v am >/dev/null 2>&1; then
  eval "$(am shell)"
fi

# ---------------------------
# Line search keybindings
# ---------------------------
autoload -U up-line-or-beginning-search
autoload -U down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey "^[[A" up-line-or-beginning-search
bindkey "^[[B" down-line-or-beginning-search

# ---------------------------
# API key (left untouched)
# ---------------------------

# ---------------------------
# Environment include
# ---------------------------
. "$HOME/.local/bin/env"

# lane = first directory under ~/code
function lane_name() {
  local dir="${PWD:A}"

  case "$dir" in
    "$HOME"/code/*)
      local rest="${dir#$HOME/code/}"
      echo "${rest%%/*}"       # gold/silver/...
      ;;
    "$HOME"/personal/*)
      echo "personal"
      ;;
    *)
      echo ""
      ;;
  esac
}

function repo_name() {
  local top
  top="$(git rev-parse --show-toplevel 2>/dev/null)" || return
  echo "${top:t}"   # basename of git root
}

function git_branch_dirty() {
  git rev-parse --is-inside-work-tree &>/dev/null || return
  local branch
  branch="$(git symbolic-ref --short HEAD 2>/dev/null || git rev-parse --short HEAD 2>/dev/null)"
  local dirty=""
  git diff --quiet || dirty="*"
  echo "$branch$dirty"
}

function lane_color() {
  case "$(lane_name)" in
    *)        echo "%F{cyan}" ;;
  esac
}

PROMPT='$(lane_color)[LANE: $(lane_name)]%f %F{250}[REPO: $(repo_name)]%f %F{magenta}$(git_branch_dirty)%f
%F{cyan}%~%f %# '
