#!/bin/bash
set -e
echo "=== GitLab Workspace Bootstrap ==="

# Update apt
echo "Updating apt..."
sudo apt update && sudo apt upgrade -y

# Install core tools
echo "Installing core tools..."
sudo apt install -y \
  fish \
  neovim \
  git \
  ripgrep \
  fd-find \
  eza \
  btop \
  zoxide \
  fzf \
  tldr \
  software-properties-common

# Try to get newer Neovim
echo "Attempting Neovim PPA..."
sudo add-apt-repository ppa:neovim-ppa/unstable -y 2>/dev/null &&
  sudo apt update &&
  sudo apt install -y neovim ||
  echo "PPA failed, using apt version of Neovim"

# Install lazygit
echo "Installing lazygit..."
LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": *"v\K[^"]*') &&
  curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz" &&
  tar xf lazygit.tar.gz lazygit &&
  sudo install lazygit -D -t /usr/local/bin/ &&
  rm -f lazygit.tar.gz lazygit ||
  echo "Lazygit install failed (GitHub may be blocked)"

# Install starship
echo "Installing starship..."
curl -sS https://starship.rs/install.sh | sh -s -- -y

# Set up LazyVim
echo "Setting up LazyVim..."
mv ~/.config/nvim ~/.config/nvim.bak 2>/dev/null || true
git clone https://github.com/LazyVim/starter ~/.config/nvim 2>/dev/null || true
rm -rf ~/.config/nvim/.git

# Configure fish
echo "Configuring fish..."
mkdir -p ~/.config/fish
cat >~/.config/fish/config.fish <<'FISHEOF'
if status is-interactive
    starship init fish | source
    zoxide init fish | source
end
FISHEOF

# Configure starship
echo "Configuring starship..."
mkdir -p ~/.config
cat >~/.config/starship.toml <<'STAREOF'
format = '$time$all'

[time]
disabled = false
format = '[$time]($style) '
time_format = '%H:%M:%S'

[hostname]
disabled = true

[username]
disabled = true

[container]
disabled = true

[kubernetes]
disabled = true

[gcloud]
disabled = true
STAREOF

# Configure lazygit
echo "Configuring lazygit..."
mkdir -p ~/.config/lazygit
cat >~/.config/lazygit/config.yml <<'LGEOF'
os:
  editPreset: 'nvim'
LGEOF

# Set git editor
git config --global core.editor "nvim"

# Set default shell to fish
chsh -s $(which fish) 2>/dev/null || echo "Could not change default shell"

echo ""
echo "=== Bootstrap complete! ==="
echo ""
echo "Manual steps remaining:"
echo "  1. Run 'fish' to switch to fish shell"
echo "  2. Set timezone: set -Ux TZ Australia/Sydney"
echo "  3. Set aliases: alias ls 'eza --icons --group-directories-first' && funcsave ls"
echo "  4. Launch nvim to install LazyVim plugins"
echo "  5. Verify: nvim --version (needs 0.10+ for LazyVim)"
