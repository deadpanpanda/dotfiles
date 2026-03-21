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
rm -rf ~/.config/nvim
ln -sfn "$DOTFILES/nvim" ~/.config/nvim

# Lazygit
mkdir -p ~/.config/lazygit
ln -sf "$DOTFILES/lazygit/config.yml" ~/.config/lazygit/config.yml 2>/dev/null

# Git
ln -sf "$DOTFILES/git/.gitconfig" ~/.gitconfig

# WezTerm (only link if on WSL)
if grep -qi microsoft /proc/version 2>/dev/null; then
  WIN_HOME=$(wslpath "$(cmd.exe /C 'echo %USERPROFILE%' 2>/dev/null | tr -d '\r')")
  if [ -n "$WIN_HOME" ]; then
    ln -sf "$DOTFILES/wezterm/.wezterm.lua" "$WIN_HOME/.wezterm.lua"
    echo "WezTerm config linked to $WIN_HOME"
  fi
fi

echo ""
echo "Dotfiles linked!"
echo ""
echo "Still need to install manually:"
echo "  - fish: sudo apt install fish -y && chsh -s \$(which fish)"
echo "  - starship: curl -sS https://starship.rs/install.sh | sh"
echo "  - neovim: sudo snap install nvim --classic"
echo "  - lazygit: install from github.com/jesseduffield/lazygit"
echo "  - eza: sudo apt install eza -y"
echo "  - btop: sudo apt install btop -y"
echo "  - zoxide: sudo apt install zoxide -y"
echo "  - fzf: sudo apt install fzf -y"
echo "  - tldr: sudo apt install tldr -y"
echo "  - wslu: sudo apt install wslu -y (WSL only)"
echo "  - harlequin: pip install 'harlequin[postgres,mysql]' --break-system-packages"
echo "  - jira-cli: install from github.com/ankitpokhrel/jira-cli"
echo "  - jiratui: pip install jiratui --break-system-packages"
echo "  - gk: curl -sL https://github.com/gitkraken/gk-cli/releases/latest/download/gk_linux_amd64 -o ~/gk && chmod +x ~/gk && sudo mv ~/gk /usr/local/bin/gk"
