#!/bin/bash
set -e

# =============================
#  基础软件
# =============================
sudo apt update
sudo apt install -y \
    build-essential curl wget git unzip \
    ca-certificates gnupg lsb-release software-properties-common \
    zsh neovim eza fzf zoxide

# =============================
#  安装 Docker
# =============================
echo ">>> Installing Docker..."

sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

echo \
"deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
https://download.docker.com/linux/ubuntu \
$(lsb_release -sc) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# 加入 Docker 组（避免 sudo）
sudo usermod -aG docker "$USER"
echo ">>> Added $USER to docker group"

# =============================
# 安装 Atuin
# =============================
echo ">>> Installing Atuin..."
curl --proto '=https' --tlsv1.2 -sSf https://setup.atuin.sh | bash

# =============================
# 安装 Starship
# =============================
echo ">>> Installing Starship..."
curl -sS https://starship.rs/install.sh | sh -s -- -y

# =============================
# 安装 JetBrainsMono Nerd Font
# =============================
FONT_NAME="JetBrainsMono"
ZIP_URL="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/${FONT_NAME}.zip"
ZIP_FILE="/tmp/${FONT_NAME}.zip"
FONT_DIR="$HOME/.local/share/fonts"

echo ">>> Downloading Nerd Font..."

mkdir -p "$FONT_DIR"

# 下载失败自动切换 FastGit
wget -O "$ZIP_FILE" "$ZIP_URL" || \
wget -O "$ZIP_FILE" "https://download.fastgit.org/ryanoasis/nerd-fonts/releases/latest/download/${FONT_NAME}.zip"

unzip -o "$ZIP_FILE" -d "$FONT_DIR"
fc-cache -fv

# =============================
# 安装 zsh 插件
# =============================
echo ">>> Installing zsh plugins..."

PLUGIN_DIR="$HOME/.config/zsh/plugins"
mkdir -p "$PLUGIN_DIR"

# zsh-autosuggestions
if [ ! -d "$PLUGIN_DIR/zsh-autosuggestions" ]; then
  git clone https://github.com/zsh-users/zsh-autosuggestions "$PLUGIN_DIR/zsh-autosuggestions"
fi

# syntax-highlighting
if [ ! -d "$PLUGIN_DIR/zsh-syntax-highlighting" ]; then
  git clone https://github.com/zsh-users/zsh-syntax-highlighting "$PLUGIN_DIR/zsh-syntax-highlighting"
fi

# fzf-tab
if [ ! -d "$PLUGIN_DIR/fzf-tab" ]; then
  git clone https://github.com/Aloxaf/fzf-tab "$PLUGIN_DIR/fzf-tab"
fi

# =============================
# 生成 .zshrc
# =============================
echo ">>> Generating ~/.zshrc..."

cat > ~/.zshrc << 'EOF'
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
EOF

# =============================
# 设置 GNOME Terminal 字体
# =============================
if command -v gsettings >/dev/null; then
  if gsettings list-schemas | grep -q "org.gnome.Terminal"; then
    echo ">>> Setting GNOME Terminal font..."

    PROFILE_ID=$(gsettings get org.gnome.Terminal.ProfilesList default | tr -d "'")
    PROFILE_PATH="org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:$PROFILE_ID/"

    gsettings set "$PROFILE_PATH" font 'JetBrainsMono Nerd Font Mono 14' || true
  else
    echo "⚠️ 检测到不是 GNOME Terminal，跳过字体设置。"
  fi
else
  echo "⚠️ gsettings 不可用，跳过终端字体设置。"
fi

# =============================
# 更改默认 shell 为 zsh
# =============================
echo ">>> Changing default shell to zsh..."
chsh -s "$(which zsh)"

echo ">>> 完成！重新登录即可生效所有配置。"
