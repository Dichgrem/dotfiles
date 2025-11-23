# ========================
#  Locale & Editor
# ========================
export EDITOR=nano

export PATH="$HOME/.atuin/bin:$PATH"

# ========================
#  History
# ========================
HISTFILE="${XDG_STATE_HOME:-$HOME/.local/state}/zsh/history"
mkdir -p "$(dirname "$HISTFILE")"
HISTSIZE=10000
SAVEHIST=10000
setopt HIST_IGNORE_DUPS HIST_IGNORE_SPACE SHARE_HISTORY INC_APPEND_HISTORY

# ========================
#  Tools Integration
# ========================
if [[ -o interactive ]]; then
  # AtuIn
  if command -v atuin >/dev/null 2>&1; then
    eval "$(atuin init zsh)"
  fi

  # zoxide
  if command -v zoxide >/dev/null 2>&1; then
    eval "$(zoxide init zsh)"
  fi

  # starship
  if command -v starship >/dev/null 2>&1; then
    eval "$(starship init zsh)"
  fi
fi

# ========================
#  Colors & Aliases
# ========================
autoload -U colors && colors

alias ls='eza --icons=auto --group-directories-first'
alias ll='eza -lh --icons=auto --group-directories-first'
alias la='eza -lha --icons=auto --group-directories-first'

alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'
alias ..='cd ..'
alias ...='cd ../..'

# ========================
#  Completion
# ========================
autoload -Uz compinit
mkdir -p ~/.cache/zsh
compinit -d ~/.cache/zsh/zcompdump
setopt CORRECT

if [[ -o interactive ]]; then
  source ~/.config/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
  source ~/.config/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
  source ~/.config/zsh/plugins/fzf-tab/fzf-tab.plugin.zsh

  ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=8'
  ZSH_AUTOSUGGEST_STRATEGY=(history completion)

  bindkey -e
fi

# ========================
#  Prompt
# ========================
if ! command -v starship >/dev/null 2>&1; then
  PROMPT='%F{green}%n@%m%f:%F{blue}%~%f %# '
  RPROMPT='%F{yellow}[%D{%H:%M}]%f'
fi
