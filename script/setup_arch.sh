#!/bin/bash
set -e

if [ "$EUID" -eq 0 ]; then
  echo "❌ 请不要以 root 用户运行此脚本"
  exit 1
fi

# 配置文件远程下载基础路径
CONFIG_BASE="https://raw.githubusercontent.com/Dichgrem/dotfiles/main"

# =============================
#  基础软件 (pacman)
# =============================
echo ">>> 安装基础软件..."
sudo pacman -S --needed --noconfirm \
  base-devel curl wget git unzip ca-certificates gnupg \
  zsh neovim eza fzf zoxide btop tmux \
  starship fastfetch fontconfig

echo "   ✓ 基础软件已安装"

# =============================
#  安装 yay (AUR helper)
# =============================
echo ">>> 检查 yay..."
if ! command -v yay >/dev/null 2>&1; then
  echo ">>> 安装 yay..."
  cd /tmp
  git clone https://aur.archlinux.org/yay.git
  cd yay
  makepkg -si --noconfirm
  cd ..
  rm -rf yay
  echo "   ✓ yay 已安装"
else
  echo "   ✓ yay 已安装"
fi

# =============================
#  安装 paru (AUR helper)
# =============================
echo ">>> 检查 paru..."
if ! command -v paru >/dev/null 2>&1; then
  echo ">>> 安装 paru..."
  cd /tmp
  git clone https://aur.archlinux.org/paru.git
  cd paru
  makepkg -si --noconfirm
  cd ..
  rm -rf paru
  echo "   ✓ paru 已安装"
else
  echo "   ✓ paru 已安装"
fi

# =============================
# 安装 Atuin (AUR)
# =============================
echo ">>> 检查 Atuin..."
if ! command -v atuin >/dev/null 2>&1; then
  echo ">>> 安装 Atuin..."
  yay -S --noconfirm atuin
  echo "   ✓ Atuin 已安装"
else
  echo "   ✓ Atuin 已安装"
fi

# =============================
#  安装 Docker
# =============================
echo ">>> 检查 Docker..."
if ! command -v docker >/dev/null 2>&1; then
  echo ">>> 安装 Docker..."
  sudo pacman -S --needed --noconfirm docker docker-compose
  echo "   ✓ Docker 已安装"
else
  echo "   ✓ Docker 已安装"
fi

if ! groups | grep -q docker; then
  sudo usermod -aG docker "$USER"
  echo ">>> 已将 $USER 加入 docker 组"
else
  echo "   ✓ 用户已在 docker 组中"
fi

# 启动 docker 服务 (WSL2 支持 systemd)
if command -v systemctl >/dev/null 2>&1; then
  sudo systemctl enable docker --now 2>/dev/null && echo "   ✓ Docker 服务已启动" || echo "   ⚠️ 请手动启动 docker 服务"
else
  echo "   ⚠️ 未检测到 systemd，请手动启动 dockerd"
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

  wget -O "$ZIP_FILE" "$ZIP_URL" ||
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
# 部署 btop 配置
# =============================
echo ">>> 部署 btop 配置..."
BTOP_CONFIG_DIR="$HOME/.config/btop"
mkdir -p "$BTOP_CONFIG_DIR"

wget -q -O "$BTOP_CONFIG_DIR/btop.conf" "$CONFIG_BASE/btop/btop.conf"
# 修正硬编码的 home 路径
sed -i "s|/home/dich|$HOME|" "$BTOP_CONFIG_DIR/btop.conf"
echo "   ✓ btop.conf 已下载"

mkdir -p "$BTOP_CONFIG_DIR/themes"
for theme in catppuccin_frappe catppuccin_latte catppuccin_macchiato catppuccin_mocha; do
  wget -q -O "$BTOP_CONFIG_DIR/themes/${theme}.theme" "$CONFIG_BASE/btop/themes/${theme}.theme"
done
echo "   ✓ btop themes 已下载"

# =============================
# 部署 tmux 配置 & TPM
# =============================
echo ">>> 部署 tmux 配置..."
wget -q -O "$HOME/.tmux.conf" "$CONFIG_BASE/tmux/tmux.conf"
echo "   ✓ tmux.conf 已下载"

# 安装 TPM (tmux plugin manager)
TPM_DIR="$HOME/.tmux/plugins/tpm"
if [ ! -d "$TPM_DIR" ]; then
  echo ">>> 安装 TPM..."
  git clone https://github.com/tmux-plugins/tpm "$TPM_DIR"
  echo "   ✓ TPM 已安装"
else
  echo "   ✓ TPM 已安装"
fi

# =============================
# 部署 Starship 配置
# =============================
echo ">>> 部署 Starship 配置..."
mkdir -p "$HOME/.config"
wget -q -O "$HOME/.config/starship.toml" "$CONFIG_BASE/starship.toml"
echo "   ✓ starship.toml 已下载"

# =============================
# 部署 Neovim 配置 (LazyVim)
# =============================
echo ">>> 部署 Neovim 配置..."
NVIM_CONFIG_DIR="$HOME/.config/nvim"
mkdir -p "$NVIM_CONFIG_DIR/lua/config" "$NVIM_CONFIG_DIR/lua/plugins"

# 根级文件
wget -q -O "$NVIM_CONFIG_DIR/init.lua" "$CONFIG_BASE/nvim/init.lua"
wget -q -O "$NVIM_CONFIG_DIR/lazy-lock.json" "$CONFIG_BASE/nvim/lazy-lock.json"
wget -q -O "$NVIM_CONFIG_DIR/lazyvim.json" "$CONFIG_BASE/nvim/lazyvim.json"
wget -q -O "$NVIM_CONFIG_DIR/stylua.toml" "$CONFIG_BASE/nvim/stylua.toml"

# lua/config/
wget -q -O "$NVIM_CONFIG_DIR/lua/config/keymaps.lua" "$CONFIG_BASE/nvim/lua/config/keymaps.lua"
wget -q -O "$NVIM_CONFIG_DIR/lua/config/lazy.lua" "$CONFIG_BASE/nvim/lua/config/lazy.lua"
wget -q -O "$NVIM_CONFIG_DIR/lua/config/options.lua" "$CONFIG_BASE/nvim/lua/config/options.lua"

# lua/plugins/
wget -q -O "$NVIM_CONFIG_DIR/lua/plugins/dashboard.lua" "$CONFIG_BASE/nvim/lua/plugins/dashboard.lua"
wget -q -O "$NVIM_CONFIG_DIR/lua/plugins/diffview.lua" "$CONFIG_BASE/nvim/lua/plugins/diffview.lua"
wget -q -O "$NVIM_CONFIG_DIR/lua/plugins/osc52.lua" "$CONFIG_BASE/nvim/lua/plugins/osc52.lua"

echo "   ✓ Neovim 配置已下载"

# =============================
# 生成 .zshrc
# =============================
echo ">>> 生成 ~/.zshrc..."

cat >~/.zshrc <<'EOF'
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
