#!/bin/bash
echo "=== GitLab Workspace Bootstrap ==="
echo ""

# ============================================================
# IMPORTANT: Run this script in BASH, not fish.
# Run from: cd ~/dotfiles && bash workspace-bootstrap.sh
#
# NOTE: We intentionally do NOT use 'set -e' here.
# The workspace has a broken Atlassian apt repo that causes
# 'apt update' to return non-zero. With 'set -e' this kills
# the entire script. Instead, each step handles its own errors.
# ============================================================

# Update apt (|| true because workspace Atlassian repo has GPG errors)
echo "[1/10] Updating apt..."
sudo apt update || true
sudo apt upgrade -y || true

# Install software-properties-common first (needed for add-apt-repository)
echo "[2/10] Installing prerequisites..."
sudo apt install -y software-properties-common python3-pip || true

# ============================================================
# NEOVIM — Install latest via PPA BEFORE installing from default apt
# Default apt gives 0.9.5 which is too old for LazyVim (needs 0.10+)
# The unstable PPA provides 0.12.0-dev which works perfectly
# ============================================================
echo "[3/10] Installing Neovim via PPA (latest version)..."
sudo add-apt-repository ppa:neovim-ppa/unstable -y || true
sudo apt update || true
sudo apt install -y neovim || true

NVIM_VERSION=$(nvim --version 2>/dev/null | head -n 1 || echo "not installed")
echo "  Installed: $NVIM_VERSION"

# Install core tools (neovim excluded — already installed from PPA above)
echo "[4/10] Installing core tools..."
sudo apt install -y \
  fish \
  git \
  ripgrep \
  fd-find \
  eza \
  btop \
  zoxide \
  fzf \
  tldr || true

# Install lazygit (not in apt, must use GitHub binary)
echo "[5/10] Installing lazygit..."
cd /tmp
rm -rf lazygit lazygit.tar.gz
LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": *"v\K[^"]*')
if [ -n "$LAZYGIT_VERSION" ]; then
  curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz" &&
    tar xf lazygit.tar.gz lazygit &&
    sudo install lazygit -D -t /usr/local/bin/ &&
    rm -f lazygit.tar.gz lazygit &&
    echo "  Lazygit installed: $(lazygit --version 2>/dev/null | head -c 50)" ||
    echo "  Lazygit install failed"
else
  echo "  Lazygit install failed (could not reach GitHub API)"
fi
cd - >/dev/null

# Install starship prompt
echo "[6/10] Installing starship..."
curl -sS https://starship.rs/install.sh | sh -s -- -y || echo "  Starship install failed"

# Install harlequin (terminal SQL IDE)
echo "[7/10] Installing harlequin..."
pip install 'harlequin[postgres]' --break-system-packages 2>/dev/null ||
  python3 -m pip install 'harlequin[postgres]' --break-system-packages 2>/dev/null ||
  echo "  Harlequin install failed"

# Set up LazyVim
echo "[8/10] Setting up LazyVim..."
if [ -d ~/.config/nvim ]; then
  mv ~/.config/nvim ~/.config/nvim.bak.$(date +%s) 2>/dev/null || true
fi
git clone https://github.com/LazyVim/starter ~/.config/nvim 2>/dev/null || true
rm -rf ~/.config/nvim/.git

# ============================================================
# CONFIGURE FISH, STARSHIP, LAZYGIT
# ============================================================
echo "[9/10] Configuring fish, starship, and lazygit..."

mkdir -p ~/.config/fish

# Fish config — imports workspace environment variables from bash
# The workspace injects critical variables (GL_TOKEN_FILE_PATH,
# GIT_CONFIG_COUNT, GIT_CONFIG_KEY_*, GIT_CONFIG_VALUE_*) into bash.
# Fish doesn't inherit these, so we import them on startup.
cat >~/.config/fish/config.fish <<'FISHEOF'
if status is-interactive
    # Import workspace environment variables from bash
    # Without this, git credentials and workspace tools break in fish
    for line in (bash -c 'source /etc/profile 2>/dev/null; source ~/.bashrc 2>/dev/null; env')
        set -l parts (string split -m 1 '=' -- $line)
        if test (count $parts) -eq 2
            switch $parts[1]
                case PWD SHLVL _ SHELL USER LOGNAME HOME TERM
                    # Skip read-only and shell-managed variables
                    continue
                case '*'
                    set -gx $parts[1] $parts[2]
            end
        end
    end

    starship init fish | source
    zoxide init fish | source
end
FISHEOF

# ============================================================
# CONFIGURE STARSHIP
# Hides noisy workspace info (hostname, username, container, k8s)
# ============================================================
mkdir -p ~/.config

# Use dotfiles starship config if it exists, otherwise create one
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
if [ -f "$SCRIPT_DIR/starship/starship.toml" ]; then
  cp "$SCRIPT_DIR/starship/starship.toml" ~/.config/starship.toml
else
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
fi

# ============================================================
# CONFIGURE LAZYGIT
# Disables autoFetch (breaks with workspace credential helper)
# Disables mouseEvents (causes escape code leak over SSH)
# ============================================================
mkdir -p ~/.config/lazygit
cat >~/.config/lazygit/config.yml <<'LGEOF'
os:
  editPreset: 'nvim'
gui:
  showIcons: true
  nerdFontsVersion: "3"
  mouseEvents: false
LGEOF

# ============================================================
# GIT CONFIG — SAFE FOR WORKSPACE
# ============================================================
# DO NOT set user.name or user.email globally.
# The workspace injects these via GIT_CONFIG_COUNT environment
# variables. Setting them in ~/.gitconfig overrides the workspace
# identity and breaks GitLab authentication.
#
# DO NOT symlink or copy the dotfiles .gitconfig — it contains
# personal identity (GitHub email) that will be used for work commits.
# ============================================================

echo "[10/10] Configuring git (aliases and editor only)..."

# Editor
git config --global core.editor "nvim"

# Useful aliases
git config --global alias.s "status --short --branch"
git config --global alias.a "add"
git config --global alias.aa "add --all"
git config --global alias.ap "add --patch"
git config --global alias.au "add --update"
git config --global alias.b "branch"
git config --global alias.ba "branch --all"
git config --global alias.c "commit"
git config --global alias.ca "commit --amend"
git config --global alias.cm "commit --message"
git config --global alias.cv "commit --verbose"
git config --global alias.d "diff"
git config --global alias.dc "diff --cached"
git config --global alias.ds "diff --staged"
git config --global alias.dw "diff --word-diff"
git config --global alias.o "checkout"
git config --global alias.ob "checkout -b"
git config --global alias.l "log"
git config --global alias.lg "log --graph"
git config --global alias.lo "log --oneline"
git config --global alias.lp "log --patch"
git config --global alias.pul "pull"
git config --global alias.pus "push"
git config --global alias.unstage "reset HEAD"
git config --global alias.undo-commit "reset --soft HEAD^"
git config --global alias.set-upstream '!git branch --set-upstream-to=origin/$(git symbolic-ref --short HEAD)'

# Other useful settings
git config --global color.ui auto
git config --global fetch.prune true
git config --global help.autocorrect 10
git config --global push.default current
git config --global pull.rebase false
git config --global init.defaultbranch main
git config --global rerere.enabled true
git config --global merge.conflictstyle diff3

# Set default shell to fish
chsh -s "$(which fish)" 2>/dev/null || echo "Could not change default shell"

# ============================================================
# VERIFY INSTALLATIONS
# ============================================================
echo ""
echo "=== Bootstrap complete! ==="
echo ""
echo "Installed versions:"
echo "  fish:     $(fish --version 2>/dev/null || echo 'NOT INSTALLED')"
echo "  nvim:     $(nvim --version 2>/dev/null | head -n 1 || echo 'NOT INSTALLED')"
echo "  starship: $(starship --version 2>/dev/null || echo 'NOT INSTALLED')"
echo "  lazygit:  $(lazygit --version 2>/dev/null | head -c 50 || echo 'NOT INSTALLED')"
echo "  eza:      $(eza --version 2>/dev/null | head -n 1 || echo 'NOT INSTALLED')"
echo "  zoxide:   $(zoxide --version 2>/dev/null || echo 'NOT INSTALLED')"
echo "  harlequin:$(harlequin --version 2>/dev/null | head -n 1 || echo 'NOT INSTALLED')"
echo ""
echo "Manual steps:"
echo "  1. Run 'fish' to switch to fish shell"
echo ""
echo "For GitHub dotfiles repo (optional):"
echo "  cd ~/dotfiles"
echo "  git config --local credential.helper store"
echo "  git config --local user.name 'deadpanpanda'"
echo "  git config --local user.email '139224044+deadpanpanda@users.noreply.github.com'"
