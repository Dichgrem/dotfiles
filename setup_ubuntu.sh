#!/usr/bin/env bash
set -euo pipefail

SCRIPT_NAME=$(basename "$0")
echo "\n=== Ubuntu Repos and Plugins Setup Script ===\n"

# Determine Ubuntu codename
CODENAME=$(lsb_release -cs)
echo "Detected Ubuntu codename: $CODENAME"

# Function to add PPA if not present
add_ppa() {
  local PPA="$1"
  if ! grep -Rq "${PPA#*:}" /etc/apt/sources.list.d; then
    echo "Adding PPA: $PPA"
    sudo add-apt-repository -y "$PPA"
  else
    echo "PPA already exists: $PPA"
  fi
}

# Function to add Docker repo
add_docker_repo() {
  local KEYRING="/usr/share/keyrings/docker-archive-keyring.gpg"
  if [ ! -f "$KEYRING" ]; then
    echo "Adding Docker GPG key and repository"
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg |
      sudo gpg --dearmor -o "$KEYRING"
    echo "deb [arch=amd64 signed-by=$KEYRING] https://download.docker.com/linux/ubuntu $CODENAME stable" |
      sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
  else
    echo "Docker repository already configured"
  fi
}

# Add PPAs
add_ppa ppa:fish-shell/release-3
add_ppa ppa:neovim-ppa/unstable
add_ppa ppa:zhangsongcui3371/fastfetch

# Add Docker repo
add_docker_repo

# Update package list
echo "\nUpdating package lists..."
sudo apt update

# Core packages to install
CORE_PKGS=(docker-ce docker-ce-cli containerd.io fastfetch neovim fish tealdeer)

# Install each package, skip if not found
for pkg in "${CORE_PKGS[@]}"; do
  if apt-cache show "$pkg" >/dev/null 2>&1; then
    echo "Installing $pkg..."
    sudo apt install -y "$pkg"
  else
    echo "Package not found in repos, skipping: $pkg"
  fi
done

# Fisher and fish plugins
echo "\nInstalling Fisher and fish plugins..."
fish -c 'curl -sL https://git.io/fisher | source && fisher install jorgebucaran/fisher'
fish -c 'fisher install bruno-ricard/fish-autopair Pure-Fish/pure'

# Atuin installation
if ! command -v atuin >/dev/null 2>&1; then
  echo "\nInstalling Atuin"
  curl -sS https://raw.githubusercontent.com/ellie/atuin/main/install.sh | bash
else
  echo "Atuin already installed"
fi

# Change default shell to fish
if [ "$SHELL" != "$(which fish)" ]; then
  echo "Changing default shell to fish"
  chsh -s "$(which fish)"
else
  echo "Default shell is already fish"
fi

echo "\n=== Setup Complete! Restart your terminal to apply changes. ==="
