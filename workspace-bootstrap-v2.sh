#!/bin/bash
echo "=== GitLab Workspace Bootstrap ==="
echo ""

# ============================================================
# PERSISTENT WORKSPACE SETUP
#
# This script installs tools to ~/.local/ which persists across
# workspace rebuilds (since /home/gitlab-workspaces/ survives).
#
# On first run: installs everything (~2-3 minutes)
# On subsequent runs: skips tools already in ~/.local/bin
#
# Run from: cd ~/dotfiles && bash workspace-bootstrap.sh
# ============================================================

LOCAL_BIN="$HOME/.local/bin"
LOCAL_OPT="$HOME/.local/opt"
mkdir -p "$LOCAL_BIN" "$LOCAL_OPT" /tmp/bootstrap-work

# Helper: skip if already installed
already_installed() {
  if [ -x "$LOCAL_BIN/$1" ]; then
    echo "  ✓ $1 already installed (persistent)"
    return 0
  fi
  return 1
}

# ============================================================
# STEP 1: System packages (apt) — these DON'T persist
# Only fish truly needs apt (it's a shell, needs system install)
# ============================================================
echo "[1/10] Installing system packages (apt)..."
if ! command -v fish &>/dev/null; then
  sudo apt update || true
  sudo apt install -y fish software-properties-common || true
  chsh -s "$(which fish)" 2>/dev/null || true
else
  echo "  ✓ fish already installed"
fi

# Neovim via PPA (system install, needs apt)
# Default apt gives 0.9.5, PPA gives 0.12.0-dev
NVIM_VER=$(nvim --version 2>/dev/null | head -n 1 | grep -oP 'v\K[0-9]+\.[0-9]+' || echo "0")
NVIM_MAJOR=$(echo "$NVIM_VER" | cut -d. -f1)
NVIM_MINOR=$(echo "$NVIM_VER" | cut -d. -f2)
if [ "$NVIM_MAJOR" -eq 0 ] && [ "$NVIM_MINOR" -lt 10 ] 2>/dev/null; then
  echo "  Neovim too old ($NVIM_VER), upgrading via PPA..."
  sudo apt install -y software-properties-common || true
  sudo add-apt-repository ppa:neovim-ppa/unstable -y || true
  sudo apt update || true
  sudo apt install -y neovim || true
else
  echo "  ✓ neovim $(nvim --version 2>/dev/null | head -n 1 || echo 'not found')"
fi

# ripgrep and fd — needed by LazyVim's Telescope, apt is fine
sudo apt install -y ripgrep fd-find git 2>/dev/null || true

# ============================================================
# STEP 2-7: Binary tools — installed to ~/.local/bin (PERSISTENT)
# ============================================================

# --- Starship ---
echo "[2/10] Starship..."
if ! already_installed starship; then
  curl -sS https://starship.rs/install.sh | sh -s -- -y -b "$LOCAL_BIN" || echo "  Starship install failed"
fi

# --- Lazygit ---
echo "[3/10] Lazygit..."
if ! already_installed lazygit; then
  cd /tmp/bootstrap-work
  rm -rf lazygit lazygit.tar.gz
  LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": *"v\K[^"]*')
  if [ -n "$LAZYGIT_VERSION" ]; then
    curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz" &&
      tar xf lazygit.tar.gz lazygit &&
      mv lazygit "$LOCAL_BIN/" &&
      chmod +x "$LOCAL_BIN/lazygit" &&
      rm -f lazygit.tar.gz || echo "  Lazygit install failed"
  else
    echo "  Lazygit install failed (could not reach GitHub API)"
  fi
  cd - >/dev/null
fi

# --- Eza ---
echo "[4/10] Eza..."
if ! already_installed eza; then
  cd /tmp/bootstrap-work
  curl -Lo eza.tar.gz "https://github.com/eza-community/eza/releases/latest/download/eza_x86_64-unknown-linux-gnu.tar.gz" &&
    tar xf eza.tar.gz &&
    mv eza "$LOCAL_BIN/" &&
    chmod +x "$LOCAL_BIN/eza" &&
    rm -f eza.tar.gz || echo "  Eza install failed"
  cd - >/dev/null
fi

# --- Zoxide ---
echo "[5/10] Zoxide..."
if ! already_installed zoxide; then
  curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash -s -- --bin-dir "$LOCAL_BIN" 2>/dev/null ||
    echo "  Zoxide install failed"
fi

# --- Fzf ---
echo "[6/10] Fzf..."
if ! already_installed fzf; then
  FZF_VERSION=$(curl -s "https://api.github.com/repos/junegunn/fzf/releases/latest" | grep -Po '"tag_name": *"v\K[^"]*')
  if [ -n "$FZF_VERSION" ]; then
    cd /tmp/bootstrap-work
    curl -Lo fzf.tar.gz "https://github.com/junegunn/fzf/releases/download/v${FZF_VERSION}/fzf-${FZF_VERSION}-linux_amd64.tar.gz" &&
      tar xf fzf.tar.gz &&
      mv fzf "$LOCAL_BIN/" &&
      chmod +x "$LOCAL_BIN/fzf" &&
      rm -f fzf.tar.gz || echo "  Fzf install failed"
    cd - >/dev/null
  else
    echo "  Fzf install failed (could not reach GitHub API)"
  fi
fi

# --- Tmux ---
echo "[7/11] Tmux..."
if ! already_installed tmux; then
  cd /tmp/bootstrap-work
  TMUX_VERSION="3.6a"
  curl -Lo tmux.tar.gz "https://github.com/tmux/tmux-builds/releases/download/v${TMUX_VERSION}/tmux-${TMUX_VERSION}-linux-x86_64.tar.gz" &&
    tar xf tmux.tar.gz &&
    mv tmux "$LOCAL_BIN/" &&
    chmod +x "$LOCAL_BIN/tmux" &&
    rm -f tmux.tar.gz || echo "  Tmux binary install failed, trying apt..."
  if ! already_installed tmux; then
    sudo apt install -y tmux 2>/dev/null || echo "  Tmux install failed"
  fi
  cd - >/dev/null
fi

# --- Btop ---
echo "[8/11] Btop..."
if ! already_installed btop; then
  sudo apt install -y btop 2>/dev/null || echo "  Btop install failed (apt only)"
fi

# --- Harlequin ---
echo "[9/11] Harlequin..."
if ! command -v harlequin &>/dev/null && ! [ -x "$LOCAL_BIN/harlequin" ]; then
  pip install 'harlequin[postgres]' --break-system-packages 2>/dev/null ||
    python3 -m pip install 'harlequin[postgres]' --break-system-packages 2>/dev/null ||
    echo "  Harlequin install failed"
else
  echo "  ✓ harlequin already installed (persistent)"
fi

# ============================================================
# STEP 8: LazyVim config
# ============================================================
echo "[10/11] Setting up LazyVim..."
if [ ! -f ~/.config/nvim/lazyvim.json ]; then
  if [ -d ~/.config/nvim ]; then
    mv ~/.config/nvim ~/.config/nvim.bak.$(date +%s) 2>/dev/null || true
  fi
  git clone https://github.com/LazyVim/starter ~/.config/nvim 2>/dev/null || true
  rm -rf ~/.config/nvim/.git
  echo "  LazyVim installed — launch nvim to install plugins"
else
  echo "  ✓ LazyVim already configured (persistent)"
fi

# ============================================================
# STEP 9: Config files (persistent in ~/.config/)
# ============================================================
echo "[11/11] Configuring fish, starship, lazygit, tmux, and git..."

# --- Fish config ---
mkdir -p ~/.config/fish
if ! grep -q "Import workspace environment" ~/.config/fish/config.fish 2>/dev/null; then
  cat >~/.config/fish/config.fish <<'FISHEOF'
if status is-interactive
    # Import workspace environment variables from bash
    # Without this, git credentials and workspace tools break in fish
    for line in (bash -c 'source /etc/profile 2>/dev/null; source ~/.bashrc 2>/dev/null; env')
        set -l parts (string split -m 1 '=' -- $line)
        if test (count $parts) -eq 2
            switch $parts[1]
                case PWD SHLVL _ SHELL USER LOGNAME HOME TERM
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
  echo "  Fish config written"
else
  echo "  ✓ Fish config already exists (persistent)"
fi

# --- Starship config ---
mkdir -p ~/.config
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
if [ ! -f ~/.config/starship.toml ]; then
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
  echo "  Starship config written"
else
  echo "  ✓ Starship config already exists (persistent)"
fi

# --- Lazygit config ---
mkdir -p ~/.config/lazygit
if [ ! -f ~/.config/lazygit/config.yml ]; then
  cat >~/.config/lazygit/config.yml <<'LGEOF'
os:
  editPreset: 'nvim'
gui:
  showIcons: true
  nerdFontsVersion: "3"
  mouseEvents: false
LGEOF
  echo "  Lazygit config written"
else
  echo "  ✓ Lazygit config already exists (persistent)"
fi

# --- Tmux config ---
mkdir -p ~/.config/tmux
if [ ! -f ~/.config/tmux/tmux.conf ]; then
  cat >~/.config/tmux/tmux.conf <<'TMUXEOF'
# Enable mouse (resize panes, click to select, scroll)
set -g mouse on

# Better colors
set -g default-terminal "tmux-256color"
set -ag terminal-overrides ",xterm-256color:RGB"

# Start windows and panes at 1 instead of 0
set -g base-index 1
setw -g pane-base-index 1

# Use fish as default shell
set -g default-shell /usr/bin/fish

# Easier pane navigation (Alt+arrow without prefix)
bind -n M-Left select-pane -L
bind -n M-Right select-pane -R
bind -n M-Up select-pane -U
bind -n M-Down select-pane -D

# Easier splits
bind | split-window -h -c "#{pane_current_path}"
bind - split-window -v -c "#{pane_current_path}"

# Reload config
bind r source-file ~/.config/tmux/tmux.conf \; display "Config reloaded"

# Status bar
set -g status-style "bg=default,fg=white"
set -g status-left "#[bold]#S "
set -g status-right "%H:%M"
set -g status-left-length 20
TMUXEOF
  echo "  Tmux config written"
else
  echo "  ✓ Tmux config already exists (persistent)"
fi

# --- Git config (aliases and editor only, NEVER identity) ---
if [ ! -f ~/.gitconfig ]; then
  git config --global core.editor "nvim"
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
  git config --global color.ui auto
  git config --global fetch.prune true
  git config --global help.autocorrect 10
  git config --global push.default current
  git config --global pull.rebase false
  git config --global init.defaultbranch main
  git config --global rerere.enabled true
  git config --global merge.conflictstyle diff3
  echo "  Git config written"
else
  echo "  ✓ Git config already exists (persistent)"
fi

# --- Dotfiles repo GitHub identity ---
if [ -d "$SCRIPT_DIR/.git" ]; then
  git -C "$SCRIPT_DIR" config --local credential.helper store 2>/dev/null
  git -C "$SCRIPT_DIR" config --local user.name "deadpanpanda" 2>/dev/null
  git -C "$SCRIPT_DIR" config --local user.email "139224044+deadpanpanda@users.noreply.github.com" 2>/dev/null
  echo "  Dotfiles repo configured for GitHub"
fi

# --- Fish aliases and variables (persistent via fish universal vars) ---
fish -c '
    if not set -q TZ
        set -Ux TZ Australia/Sydney
    end
    if not functions -q ls
        alias ls "eza --icons --group-directories-first"
        funcsave ls
    end
    if not functions -q services
        alias services "bash ~/dotfiles/dev-services.sh"
        funcsave services
    end
    fish_add_path ~/.local/bin
' 2>/dev/null || echo "  Fish alias setup skipped (fish may not be installed yet)"

# ============================================================
# CLEANUP
# ============================================================
rm -rf /tmp/bootstrap-work

# ============================================================
# VERIFY
# ============================================================
echo ""
echo "=== Bootstrap complete! ==="
echo ""
echo "Installed versions:"
echo "  fish:      $(fish --version 2>/dev/null || echo 'NOT INSTALLED')"
echo "  nvim:      $(nvim --version 2>/dev/null | head -n 1 || echo 'NOT INSTALLED')"
echo "  tmux:      $($LOCAL_BIN/tmux -V 2>/dev/null || tmux -V 2>/dev/null || echo 'NOT INSTALLED')"
echo "  starship:  $($LOCAL_BIN/starship --version 2>/dev/null || echo 'NOT INSTALLED')"
echo "  lazygit:   $($LOCAL_BIN/lazygit --version 2>/dev/null | head -c 60 || echo 'NOT INSTALLED')"
echo "  eza:       $($LOCAL_BIN/eza --version 2>/dev/null | head -n 1 || echo 'NOT INSTALLED')"
echo "  zoxide:    $($LOCAL_BIN/zoxide --version 2>/dev/null || echo 'NOT INSTALLED')"
echo "  fzf:       $($LOCAL_BIN/fzf --version 2>/dev/null || echo 'NOT INSTALLED')"
echo "  harlequin: $(harlequin --version 2>/dev/null | head -n 1 || echo 'NOT INSTALLED')"
echo ""
echo "Persistent (survive rebuild): tmux, starship, lazygit, eza, zoxide, fzf,"
echo "                              harlequin, LazyVim config, fish config,"
echo "                              starship config, lazygit config, tmux config,"
echo "                              git aliases, fish aliases, dev-services script"
echo ""
echo "Need reinstall after rebuild: fish (apt), neovim (apt+PPA), ripgrep, fd-find"
echo ""
echo "To finish: run 'fish' then 'nvim' to install LazyVim plugins"
echo ""
echo "To launch services: type 'services' (edit commands in ~/dotfiles/dev-services.sh)"
echo "  tmux basics: Ctrl+B then arrow keys to switch panes"
echo "  Detach: Ctrl+B then D  |  Reattach: tmux attach -t services"
echo "  Kill session: tmux kill-session -t services"
