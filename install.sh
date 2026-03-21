#!/bin/bash
DOTFILES="$(cd "$(dirname "$0")" && pwd)"

echo "Installing dotfiles from $DOTFILES"

# Fish
mkdir -p ~/.config/fish
ln -sf "$DOTFILES/fish/config.fish" ~/.config/fish/config.fish

# Starship
mkdir -p ~/.config
ln -sf "$DOTFILES/starship/starship.toml" ~/.config/starship.toml

# Neovim
ln -sfn "$DOTFILES/nvim" ~/.config/nvim

echo "Dotfiles linked!"
echo ""
echo "Still need to install manually:"
echo "  - fish: sudo apt install fish -y && chsh -s \$(which fish)"
echo "  - starship: curl -sS https://starship.rs/install.sh | sh"
echo "  - neovim: sudo snap install nvim --classic"
echo "  - eza: sudo apt install eza -y"
echo "  - wslu: sudo apt install wslu -y (WSL only)"
echo "  - gk: curl -sL https://github.com/gitkraken/gk-cli/releases/latest/download/gk_linux_amd64 -o ~/gk && chmod +x ~/gk && sudo mv ~/gk /usr/local/bin/gk"
