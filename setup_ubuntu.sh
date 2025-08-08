#!/usr/bin/env bash
set -euo pipefail

SCRIPT_NAME=$(basename "$0")
echo -e "\n=== Ubuntu Repos and Plugins Setup Script ===\n"

# Detect Ubuntu codename
CODENAME=$(lsb_release -cs)
echo "Detected Ubuntu codename: $CODENAME"

# Docker 官方支持的 Ubuntu 版本
DOCKER_SUPPORTED_CODENAMES=("focal" "jammy")

# 如果当前 codename 不在支持列表，回退到 jammy
if [[ ! " ${DOCKER_SUPPORTED_CODENAMES[*]} " =~ " ${CODENAME} " ]]; then
  echo "Docker does not officially support '$CODENAME', falling back to 'jammy'"
  CODENAME="jammy"
fi

# ==== 清理旧 Docker 源和包 ====
echo "Cleaning old Docker sources and packages..."
sudo rm -f /etc/apt/sources.list.d/docker.list
sudo rm -f /usr/share/keyrings/docker-archive-keyring.gpg
sudo apt remove -y docker docker-engine docker.io containerd runc || true

# ==== 函数 ====
# 添加 PPA
add_ppa() {
  local PPA="$1"
  local PPA_NAME="${PPA#*:}"
  if ! grep -Rq "$PPA_NAME" /etc/apt/sources.list.d 2>/dev/null; then
    echo "Adding PPA: $PPA"
    sudo add-apt-repository -y "$PPA"
  else
    echo "PPA already exists: $PPA"
  fi
}

# 添加 Docker 源
add_docker_repo() {
  local KEYRING="/usr/share/keyrings/docker-archive-keyring.gpg"
  if [ ! -f "$KEYRING" ]; then
    echo "Adding Docker GPG key and repository"
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg |
      sudo gpg --dearmor -o "$KEYRING"
    echo "deb [arch=$(dpkg --print-architecture) signed-by=$KEYRING] https://download.docker.com/linux/ubuntu $CODENAME stable" |
      sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
  else
    echo "Docker repository already configured"
  fi
}

# ==== 添加 PPA ====
add_ppa ppa:fish-shell/release-3
add_ppa ppa:neovim-ppa/unstable
add_ppa ppa:zhangsongcui3371/fastfetch

# ==== 添加 Docker 源 ====
add_docker_repo

# ==== 更新软件列表 ====
echo -e "\nUpdating package lists..."
sudo apt update

# 核心软件包
CORE_PKGS=(docker-ce docker-ce-cli containerd.io fastfetch neovim fish tealdeer)

for pkg in "${CORE_PKGS[@]}"; do
  if apt-cache show "$pkg" >/dev/null 2>&1; then
    echo "Installing $pkg..."
    sudo apt install -y "$pkg"
  else
    echo "Package not found in repos, skipping: $pkg"
  fi
done

# ==== 安装 fisher 和 fish 插件 ====
echo -e "\nInstalling Fisher and fish plugins..."
fish -c 'curl -sL https://git.io/fisher | source && fisher install jorgebucaran/fisher'
fish -c 'fisher install bruno-ricard/fish-autopair Pure-Fish/pure'

# ==== 安装 Atuin ====
if ! command -v atuin >/dev/null 2>&1; then
  echo -e "\nInstalling Atuin..."
  curl -sS https://raw.githubusercontent.com/ellie/atuin/main/install.sh | bash
else
  echo "Atuin already installed"
fi

# ==== 改默认 shell 为 fish ====
if [ "$SHELL" != "$(which fish)" ]; then
  echo "Changing default shell to fish"
  chsh -s "$(which fish)"
else
  echo "Default shell is already fish"
fi

echo -e "\n=== Setup Complete! Restart your terminal to apply changes. ==="
