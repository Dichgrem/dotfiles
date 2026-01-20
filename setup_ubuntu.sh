#!/bin/bash
set -e

if [ "$EUID" -eq 0 ]; then
  echo "❌ 请不要以 root 用户运行此脚本"
  echo "   脚本会提示输入密码来安装需要 root 权限的软件"
  exit 1
fi

# =============================
#  基础软件
# =============================
echo ">>> 检查基础软件..."
PACKAGES="build-essential curl wget git unzip ca-certificates gnupg lsb-release software-properties-common zsh neovim eza fzf zoxide"
TO_INSTALL=""

for pkg in $PACKAGES; do
  if ! dpkg -l | grep -q "^ii  $pkg "; then
    TO_INSTALL="$TO_INSTALL $pkg"
  fi
done

if [ -n "$TO_INSTALL" ]; then
  echo "   需要安装:$TO_INSTALL"
  sudo apt update
  sudo apt install -y $TO_INSTALL
else
  echo "   ✓ 基础软件已安装"
fi

# =============================
#  安装 Docker
# =============================
echo ">>> 检查 Docker..."
if ! command -v docker >/dev/null 2>&1; then
  echo ">>> Installing Docker..."

  sudo install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

  echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu \
  $(lsb_release -sc) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

  sudo apt update
  sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
else
  echo "   ✓ Docker 已安装"
fi

if ! groups | grep -q docker; then
  sudo usermod -aG docker "$USER"
  echo ">>> Added $USER to docker group"
else
  echo "   ✓ 用户已在 docker 组中"
fi

# =============================
# 安装 Atuin
# =============================
echo ">>> 检查 Atuin..."
if ! command -v atuin >/dev/null 2>&1; then
  echo ">>> Installing Atuin..."
  curl --proto '=https' --tlsv1.2 -sSf https://setup.atuin.sh | bash
else
  echo "   ✓ Atuin 已安装"
fi

# =============================
# 安装 Starship
# =============================
echo ">>> 检查 Starship..."
if ! command -v starship >/dev/null 2>&1; then
  echo ">>> Installing Starship..."
  curl -sS https://starship.rs/install.sh | sh -s -- -y
else
  echo "   ✓ Starship 已安装"
fi

# =============================
# 安装 Fastfetch
# =============================
echo ">>> 检查 Fastfetch..."
if ! command -v fastfetch >/dev/null 2>&1; then
  echo ">>> Installing Fastfetch..."

  ARCH=$(uname -m)
  case $ARCH in
    x86_64)
      ARCH="amd64"
      ;;
    aarch64)
      ARCH="aarch64"
      ;;
    armv7l)
      ARCH="armv7"
      ;;
    *)
      echo "   ⚠️ 不支持的架构: $ARCH"
      ;;
  esac

  if [ "$ARCH" != "x86_64" ] && [ "$ARCH" != "aarch64" ] && [ "$ARCH" != "armv7" ]; then
    echo "   ⚠️ 跳过 Fastfetch 安装"
  else
    FASTFETCH_VERSION=$(curl -s "https://api.github.com/repos/fastfetch-cli/fastfetch/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
    FASTFETCH_URL="https://github.com/fastfetch-cli/fastfetch/releases/download/${FASTFETCH_VERSION}/fastfetch-linux-${ARCH}.deb"

    TEMP_DEB="/tmp/fastfetch.deb"
    wget -O "$TEMP_DEB" "$FASTFETCH_URL"
    sudo dpkg -i "$TEMP_DEB" || sudo apt install -f -y
    rm -f "$TEMP_DEB"
    echo "   ✓ Fastfetch 安装完成"
  fi
else
  echo "   ✓ Fastfetch 已安装"
fi

# =============================
# 安装 JetBrainsMono Nerd Font
# =============================
echo ">>> 检查 Nerd Font..."
FONT_NAME="JetBrainsMono"
ZIP_URL="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/${FONT_NAME}.zip"
ZIP_FILE="/tmp/${FONT_NAME}.zip"
FONT_DIR="$HOME/.local/share/fonts"

if [ ! -f "$FONT_DIR/JetBrains Mono Nerd Font Mono.ttf" ]; then
  echo ">>> Downloading Nerd Font..."

  mkdir -p "$FONT_DIR"

  wget -O "$ZIP_FILE" "$ZIP_URL" || \
  wget -O "$ZIP_FILE" "https://download.fastgit.org/ryanoasis/nerd-fonts/releases/latest/download/${FONT_NAME}.zip"

  unzip -o "$ZIP_FILE" -d "$FONT_DIR"
  fc-cache -fv
  echo "   ✓ Nerd Font 安装完成"
else
  echo "   ✓ Nerd Font 已安装"
fi

# =============================
# 安装 zsh 插件
# =============================
echo ">>> 检查 zsh 插件..."

PLUGIN_DIR="$HOME/.config/zsh/plugins"
mkdir -p "$PLUGIN_DIR"

install_plugin() {
  local name=$1
  local url=$2
  if [ ! -d "$PLUGIN_DIR/$name" ]; then
    git clone "$url" "$PLUGIN_DIR/$name"
    echo "   ✓ $name 安装完成"
  else
    echo "   ✓ $name 已安装"
  fi
}

install_plugin "zsh-autosuggestions" "https://github.com/zsh-users/zsh-autosuggestions"
install_plugin "zsh-syntax-highlighting" "https://github.com/zsh-users/zsh-syntax-highlighting"
install_plugin "fzf-tab" "https://github.com/Aloxaf/fzf-tab"

# =============================
# 生成 .zshrc
# =============================
echo ">>> 生成 ~/.zshrc..."

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
  if command -v atuin >/dev/null 2>&1; then
    eval "$(atuin init zsh)"
  fi

  if command -v zoxide >/dev/null 2>&1; then
    eval "$(zoxide init zsh)"
  fi

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

echo "   ✓ .zshrc 已生成"

# =============================
# 设置 GNOME Terminal 字体
# =============================
echo ">>> 检查 GNOME Terminal 字体..."
if command -v gsettings >/dev/null; then
  if gsettings list-schemas | grep -q "org.gnome.Terminal"; then
    PROFILE_ID=$(gsettings get org.gnome.Terminal.ProfilesList default | tr -d "'")
    PROFILE_PATH="org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:$PROFILE_ID/"
    CURRENT_FONT=$(gsettings get "$PROFILE_PATH" font 2>/dev/null | tr -d "'")

    if [ "$CURRENT_FONT" != "JetBrainsMono Nerd Font Mono 14" ]; then
      echo ">>> Setting GNOME Terminal font..."
      gsettings set "$PROFILE_PATH" font 'JetBrainsMono Nerd Font Mono 14' || true
      echo "   ✓ 字体已设置"
    else
      echo "   ✓ 字体已正确设置"
    fi
  else
    echo "   ⚠️ 检测到不是 GNOME Terminal，跳过字体设置"
  fi
else
  echo "   ⚠️ gsettings 不可用，跳过终端字体设置"
fi

# =============================
# 更改默认 shell 为 zsh
# =============================
echo ">>> 检查默认 shell..."
CURRENT_SHELL=$(getent passwd "$USER" | cut -d: -f7)
if [ "$CURRENT_SHELL" != "$(which zsh)" ]; then
  echo ">>> Changing default shell to zsh..."
  sudo chsh -s "$(which zsh)" "$USER"
  echo "   ✓ 默认 shell 已设置为 zsh"
else
  echo "   ✓ 默认 shell 已是 zsh"
fi

echo ""
echo ">>> ✓ 完成！重新登录即可生效所有配置。"
