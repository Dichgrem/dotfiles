#!/usr/bin/env bash
# === Ubuntu / UOS Quick Setup ===
# Docker + Fastfetch + Neovim + Zsh(eza/fzf/zoxide/atuin/starship)
set -euo pipefail

echo -e "\n🚀 === Ubuntu Environment Setup ===\n"

# --- Base ---
sudo apt update
sudo apt install -y curl git ca-certificates gnupg lsb-release software-properties-common

# --- PPA ---
sudo add-apt-repository -y ppa:neovim-ppa/unstable || true
sudo add-apt-repository -y ppa:zhangsongcui3371/fastfetch || true

# --- Docker ---
if ! command -v docker >/dev/null 2>&1; then
  echo -e "\n🐳 Installing Docker (official script)..."
  curl -fsSL https://get.docker.com | sh
else
  echo "🐳 Docker already installed"
fi

# --- Package ---
CORE_PKGS=(fastfetch neovim zsh eza fzf zoxide ripgrep tealdeer)
for pkg in "${CORE_PKGS[@]}"; do
  if apt-cache show "$pkg" >/dev/null 2>&1; then
    sudo apt install -y "$pkg"
  else
    echo "⚠️ Package not found in repos: $pkg"
  fi
done

# --- Atuin ---
if ! command -v atuin >/dev/null 2>&1; then
  echo -e "\n📜 Installing Atuin..."
  curl -sS https://raw.githubusercontent.com/ellie/atuin/main/install.sh | bash
else
  echo "Atuin already installed"
fi

# --- Starship ---
if ! command -v starship >/dev/null 2>&1; then
  echo -e "\n🌟 Installing Starship..."
  curl -sS https://starship.rs/install.sh | sh -s -- -y
else
  echo "Starship already installed"
fi

# --- Shell ---
if [ "$SHELL" != "$(command -v zsh)" ]; then
  echo -e "\n💫 Changing default shell to zsh"
  chsh -s "$(command -v zsh)"
fi

echo -e "\n✅ All done! Restart your terminal or run 'exec zsh' to enjoy!"