# Terminal Development Environment Setup Cheatsheet

> **Stack:** WezTerm → WSL2 (Ubuntu) → Fish Shell → Starship Prompt → Neovim (LazyVim) → Lazygit + Harlequin + Jira CLI/TUI

---

## 1. Install WSL2

Open **PowerShell as Administrator**:

```powershell
wsl --install -d Ubuntu-24.04
```

Restart your PC. After reboot, open **Ubuntu** from the Start menu. Create a username and password.

If `wsl --install -d Ubuntu` loops after reboot, try the specific version `Ubuntu-24.04` or manually enable the required features:

```powershell
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
```

Then restart and retry. Also check virtualization is enabled: `Get-ComputerInfo -Property HyperVisorPresent` (needs to be `True`).

Update everything:

```bash
sudo apt update && sudo apt upgrade -y
```

### Remove sudo password prompt

```bash
sudo visudo
```

Add at the bottom (replace `yourusername` — run `whoami` if unsure):

```
yourusername ALL=(ALL) NOPASSWD: ALL
```

Save: `Ctrl+X`, then `Y`, then `Enter`.

### Understanding WSL

WSL is not a desktop or separate OS. There's no GUI. It's just a Linux command line running inside your terminal window. You still use Windows for your browser and everything else.

---

## 2. Set Up Windows File Access

Windows files are at `/mnt/c/Users/YourWindowsUsername/`.

Create a symlink so you can access Windows files easily (this works as a real path everywhere — `cd`, `ls`, `nvim`, etc.):

```bash
ln -s /mnt/c/Users/YourWindowsUsername ~/win
ln -s /mnt/c/Users/YourWindowsUsername/path/to/repos ~/repos
```

Find a folder if you're not sure where it is:

```bash
find /mnt/c/Users -maxdepth 4 -type d -name "repo*" 2>/dev/null
```

---

## 3. Install Fish Shell

```bash
sudo apt install fish -y
chsh -s $(which fish)
```

### Fish vs Bash syntax differences

Fish uses different syntax from bash. Key differences you'll run into:

| Bash | Fish |
|------|------|
| `export VAR=value` | `set -Ux VAR value` |
| `VAR=$(command)` | `set VAR (command)` |
| `$()` for subshells | `()` for subshells |
| `~/.bashrc` | `~/.config/fish/config.fish` |

### Useful Fish commands

| Command | Action |
|---------|--------|
| `alias name 'command'` | Create alias |
| `funcsave name` | Save alias permanently |
| `functions --erase name` then `funcsave name` | Remove alias |
| `set -Ux VAR value` | Set persistent env variable |
| Right arrow | Accept autosuggestion |
| Tab | Autocomplete |

### Remove welcome message

```bash
set -U fish_greeting
```

---

## 4. Install Starship Prompt

Starship is just the prompt line — it replaces Fish's default prompt with a smarter one showing git info, directory, timestamps, etc.

```bash
curl -sS https://starship.rs/install.sh | sh
echo 'starship init fish | source' >> ~/.config/fish/config.fish
```

### Configure Starship

```bash
mkdir -p ~/.config
nvim ~/.config/starship.toml
```

Example config (time at the start, keeping all defaults with `$all`):

```toml
format = '$time$all'

[time]
disabled = false
format = '[$time]($style) '
time_format = '%H:%M:%S'
```

Using `$all` preserves all default modules (directory, git branch, language versions, etc.). Without it, defining a custom `format` overrides everything.

Browse all modules at: https://starship.rs/config/

---

## 5. Install WezTerm (Windows Side)

Download from [wezfurlong.org/wezterm](https://wezfurlong.org/wezterm/).

### Install a Nerd Font

Download **FiraCode Nerd Font** from [nerdfonts.com/font-downloads](https://www.nerdfonts.com/font-downloads). Extract zip, select all `.ttf` files, right click → **Install for all users**.

Nerd Fonts include special icons used by eza, LazyVim's file explorer, starship, and lazygit.

### Configure WezTerm

In PowerShell:

```powershell
notepad $HOME/.wezterm.lua
```

Paste:

```lua
local wezterm = require 'wezterm'
local config = {}

-- Launch into WSL with Fish
config.default_domain = 'WSL:Ubuntu'
config.default_prog = { 'fish' }

-- Theme (browse: wezfurlong.org/wezterm/colorschemes)
config.color_scheme = 'Catppuccin Mocha'

-- Font with ligatures
config.font = wezterm.font('FiraCode Nerd Font')
config.harfbuzz_features = { 'calt=1', 'clig=1', 'liga=1' }

return config
```

WezTerm hot-reloads on config changes — no restart needed. The config file lives on the Windows side at `C:\Users\YourUsername\.wezterm.lua`. To edit from WSL:

```bash
nvim ~/win/.wezterm.lua
```

### Popular themes

Catppuccin Mocha, Tokyo Night, Gruvbox Dark, Dracula, Kanagawa, Rose Pine. Pick a matching Neovim colorscheme for a cohesive look.

---

## 6. Fix WSL Browser Opening

WSL can't open Windows browsers by default. Install `wslu`:

```bash
sudo apt install wslu -y
set -Ux BROWSER wslview
sudo ln -s (which wslview) /usr/local/bin/xdg-open
```

Test: `wslview https://google.com`

The `xdg-open` symlink helps CLI tools (like `gk`) that use `xdg-open` internally to open URLs.

---

## 7. Install Neovim

```bash
sudo snap install nvim --classic
nvim --version
```

Set Neovim as your default git editor:

```bash
git config --global core.editor "nvim"
```

---

## 8. Install LazyVim

Install dependencies:

```bash
sudo apt install git ripgrep fd-find -y
```

Clone starter config:

```bash
mv ~/.config/nvim ~/.config/nvim.bak 2>/dev/null
git clone https://github.com/LazyVim/starter ~/.config/nvim
rm -rf ~/.config/nvim/.git
```

Launch `nvim` — plugins auto-install on first run. When all show "already up to date", press `q`.

### Key LazyVim Commands

| Keys | Action |
|------|--------|
| `Space` | Open which-key menu (your best friend) |
| `Space f f` | Find files |
| `Space f g` | Search text across files (grep) |
| `Space e` | Toggle file explorer |
| `Space b b` | Switch between open buffers |
| `Space g g` | Open lazygit (built-in integration) |
| `Space l` | LSP/language options |
| `Space q q` | Quit |

---

## 9. Install Lazygit

Lazygit is NOT in Ubuntu's default repos. Install from GitHub releases:

```fish
cd ~
set LAZYGIT_VERSION (curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": *"v\K[^"]*')
curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/download/v$LAZYGIT_VERSION/lazygit_{$LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
tar xf lazygit.tar.gz lazygit
sudo install lazygit -D -t /usr/local/bin/
rm lazygit.tar.gz lazygit
```

Note: The above uses **fish syntax**. In bash the variable assignment would use `=` and `$()`.

Verify: `lazygit --version`

### Configure lazygit

```bash
mkdir -p ~/.config/lazygit
nvim ~/.config/lazygit/config.yml
```

Add:

```yaml
os:
  editPreset: 'nvim'
gui:
  showIcons: true
  nerdFontsVersion: "3"
  mouseEvents: false
```

LazyVim has built-in lazygit integration: press `Space g g` inside Neovim.

### Key lazygit controls

| Key | Action |
|-----|--------|
| `Space` | Stage/unstage file |
| `c` | Commit |
| `p` | Push |
| `P` | Pull |
| `n` | New branch |
| `Tab` | Switch panels |
| `?` | Help |
| `q` | Quit |

---

## 10. Install Harlequin (Terminal SQL IDE)

```bash
pip install harlequin --break-system-packages
```

For specific database support:

```bash
pip install 'harlequin[postgres,mysql]' --break-system-packages
```

If you get PATH warnings about `~/.local/bin`, fix with:

```bash
fish_add_path ~/.local/bin
```

Connect:

```bash
harlequin -a postgres "postgresql://user:pass@host:5432/dbname"
harlequin -a sqlite "path/to/db.sqlite"
harlequin  # opens in-memory DuckDB session
```

---

## 11. Install Jira Tools

### jira-cli (quick actions & interactive mode)

```bash
go install github.com/ankitpokhrel/jira-cli/cmd/jira@latest
```

Or download the binary from the GitHub releases page. Then run:

```bash
jira init
```

Follow the prompts to configure your Jira instance.

| Command | Action |
|---------|--------|
| `jira issue list` | List issues assigned to you |
| `jira issue view ISSUE-1` | View issue details |
| `jira issue move ISSUE-1 "In Progress"` | Transition a ticket |
| `jira issue assign ISSUE-1 $(jira me)` | Assign to yourself |
| `jira sprint list` | List sprints |
| `jira board list` | List boards |

### JiraTUI (visual TUI for Jira)

```bash
pip install jiratui --break-system-packages
```

Configure at `~/.config/jiratui/config.yaml`:

```yaml
jira_api_username: 'your.email@company.com'
jira_api_token: 'your-api-token'
jira_api_base_url: 'https://your-company.atlassian.net'
```

Launch: `jiratui ui`

---

## 12. Install Terminal Utilities

### eza (modern ls replacement)

```bash
sudo apt install eza -y
alias ls 'eza --icons --group-directories-first'
funcsave ls
```

Note: `ls` hides dotfiles by default. Use `ls -a` to show them.

The green background highlights you see on Windows directories are caused by WSL interpreting Windows permissions as wide-open. This is normal — eza handles it more gracefully than default `ls`.

### btop (system monitor)

```bash
sudo apt install btop -y
```

### zoxide (smart cd)

```bash
sudo apt install zoxide -y
echo 'zoxide init fish | source' >> ~/.config/fish/config.fish
```

Use `z` instead of `cd` — it learns your directories. e.g. `z repos` jumps to your repos folder after visiting it once.

### fzf (fuzzy finder)

```bash
sudo apt install fzf -y
```

### tldr (simplified man pages)

```bash
sudo apt install tldr -y
```

---

## 13. Git Configuration

```bash
git config --global user.name "Your Name"
git config --global user.email "your.email@company.com"
git config --global core.editor "nvim"
```

View all settings and where they come from:

```bash
git config --list --show-origin
```

Edit global config directly:

```bash
nvim ~/.gitconfig
```

Note: Your Windows git config at `C:\Program Files\Git\etc\gitconfig` is NOT shared with WSL. They are separate git installations.

---

## 14. SSH Setup

### Copy Windows SSH keys into WSL

Files on `/mnt/c/` can't have Linux permissions changed, so you must copy keys into WSL's native filesystem:

```bash
mkdir -p ~/.ssh
cp ~/win/.ssh/id_rsa_gh ~/.ssh/id_rsa_gh
cp ~/win/.ssh/config ~/.ssh/config
chmod 700 ~/.ssh
chmod 600 ~/.ssh/id_rsa_gh
chmod 600 ~/.ssh/config
```

The `chmod 600` is critical — SSH refuses to use keys with open permissions.

### SSH config example

`~/.ssh/config`:

```
Host github.com
    HostName github.com
    User yourgithubusername
    IdentityFile ~/.ssh/id_rsa_gh
    IdentitiesOnly yes

Host my-workspace
    HostName your.gitlab.server.com
    User your-username
    IdentityFile ~/.ssh/id_ed25519
```

### Test connections

```bash
ssh -T git@github.com
ssh my-workspace
```

### Troubleshooting

If you get `client_global_hostkeys_prove_confirm` errors:

```bash
ssh-keygen -R hostname-or-ip
```

If you get `UNPROTECTED PRIVATE KEY FILE` errors, the key permissions are wrong:

```bash
chmod 600 ~/.ssh/your_key_file
```

---

## 15. Dotfiles Repo

### Structure

```
~/dotfiles/
├── fish/
│   ├── config.fish
│   └── functions/
│       ├── lg.fish
│       ├── ls.fish
│       ├── lsa.fish
│       ├── opt_api.fish
│       ├── opt_app.fish
│       ├── opt_orch_w.fish
│       ├── opt_w.fish
│       └── services.fish
├── starship/
│   └── starship.toml
├── nvim/
│   ├── init.lua
│   ├── lazyvim.json
│   ├── stylua.toml
│   └── lua/
│       ├── config/
│       │   ├── autocmds.lua
│       │   ├── keymaps.lua
│       │   ├── lazy.lua
│       │   └── options.lua
│       └── plugins/
│           ├── colors.lua
│           ├── colorscheme.lua
│           ├── dadbod.lua
│           ├── gitsigns.lua
│           ├── mini-files.lua
│           ├── mini-surround.lua
│           └── telescope-fzf.lua
├── tmux/
│   └── tmux.conf
├── wezterm/
│   └── .wezterm.lua
├── git/
│   └── .gitconfig
├── lazygit/
│   └── config.yml
├── .gitignore
└── install.sh
```

### Create from scratch

```bash
mkdir -p ~/dotfiles && cd ~/dotfiles && git init
mkdir -p fish/functions starship nvim wezterm git lazygit tmux

cp ~/.config/fish/config.fish fish/
cp ~/.config/fish/functions/*.fish fish/functions/
cp ~/.config/starship.toml starship/
cp -r ~/.config/nvim/* nvim/
cp ~/win/.wezterm.lua wezterm/
cp ~/.gitconfig git/
cp ~/.config/lazygit/config.yml lazygit/ 2>/dev/null
cp ~/.config/tmux/tmux.conf tmux/ 2>/dev/null
```

### .gitignore

```
nvim/lazy-lock.json
```

### install.sh

```bash
#!/bin/bash
DOTFILES="$(cd "$(dirname "$0")" && pwd)"
echo "Installing dotfiles from $DOTFILES"

# Fish
mkdir -p ~/.config/fish/functions
ln -sf "$DOTFILES/fish/config.fish" ~/.config/fish/config.fish
for f in "$DOTFILES"/fish/functions/*.fish; do
  ln -sf "$f" ~/.config/fish/functions/
done

# Starship
mkdir -p ~/.config
ln -sf "$DOTFILES/starship/starship.toml" ~/.config/starship.toml

# Neovim
rm -rf ~/.config/nvim
ln -sfn "$DOTFILES/nvim" ~/.config/nvim

# Lazygit
mkdir -p ~/.config/lazygit
ln -sf "$DOTFILES/lazygit/config.yml" ~/.config/lazygit/config.yml 2>/dev/null

# Tmux
mkdir -p ~/.config/tmux
ln -sf "$DOTFILES/tmux/tmux.conf" ~/.config/tmux/tmux.conf

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
echo "  - lazygit: see cheatsheet (install from GitHub releases)"
echo "  - eza: sudo apt install eza -y"
echo "  - btop: sudo apt install btop -y"
echo "  - zoxide: sudo apt install zoxide -y"
echo "  - fzf: sudo apt install fzf -y"
echo "  - tldr: sudo apt install tldr -y"
echo "  - wslu: sudo apt install wslu -y (WSL only)"
echo "  - harlequin: pip install 'harlequin[postgres,mysql]' --break-system-packages"
echo "  - jira-cli: install from github.com/ankitpokhrel/jira-cli"
echo "  - jiratui: pip install jiratui --break-system-packages"
echo ""
echo "After installing, add ~/.local/bin to PATH: fish_add_path ~/.local/bin"
```

### Push to GitHub

```bash
chmod +x install.sh
git add .
git commit -m "dotfiles: fish, starship, nvim, wezterm, git, lazygit configs"
git branch -M main
git remote add origin git@github.com:yourusername/dotfiles.git
git push -u origin main
```

### On any new machine

```bash
git clone git@github.com:yourusername/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh
```

Symlinks mean editing configs in their normal locations (e.g. `~/.config/fish/config.fish`) edits the dotfiles repo. Just `cd ~/dotfiles`, commit, and push.

---

## Architecture Recap

```
WezTerm (window, fonts, colors, tabs, splits)
  └── WSL2 (Linux environment running on Windows — no GUI, just a terminal)
       └── Fish (shell — interprets commands, autosuggestions, syntax highlighting)
            └── Starship (prompt — the info line showing git/dir/time)
                 └── Neovim + LazyVim (code editor with IDE features)
                 └── Lazygit (interactive git TUI — staging, commits, rebasing)
                 └── Harlequin (terminal SQL IDE for databases)
                 └── jira-cli / JiraTUI (Jira ticket management)
                 └── btop (system resource monitor)
```

---

## Tool Purposes Quick Reference

| Tool | Purpose |
|------|---------|
| **WezTerm** | Terminal emulator (window, fonts, tabs, splits) |
| **WSL2** | Linux environment on Windows (not a GUI, just command line) |
| **Fish** | Shell (autosuggestions, syntax highlighting, smart completions) |
| **Starship** | Prompt (git info, timestamps, directory, language versions) |
| **Neovim + LazyVim** | Code editor with IDE features via plugins |
| **Lazygit** | Day-to-day git (stage, commit, rebase, conflicts, diffs) |
| **Harlequin** | Database client (SQL IDE in terminal) |
| **jira-cli** | Quick Jira actions (move tickets, assign, comment) |
| **JiraTUI** | Visual Jira board in terminal |
| **eza** | Better `ls` with icons and git status |
| **btop** | System resource monitor |
| **zoxide** | Smart directory jumping (learns your habits) |
| **fzf** | Fuzzy finder for files and command history |
| **tldr** | Simplified command help (practical examples) |

---

## Common Gotchas

| Issue | Fix |
|-------|-----|
| WSL can't open browser | Install `wslu`, set `BROWSER` to `wslview`, symlink `xdg-open` |
| SSH key permission denied | `chmod 600 ~/.ssh/your_key` — must copy keys to WSL filesystem, can't use `/mnt/c/` |
| Windows git config not found in WSL | They're separate — set config in both or use dotfiles repo |
| Green backgrounds on `ls` output | Windows permissions look wide-open from WSL — use `eza` instead |
| `pip` installed tools not found | `fish_add_path ~/.local/bin` |
| Fish syntax errors with bash commands | Fish uses `set` not `=`, `()` not `$()` |
| `lazygit` not in apt | Install from GitHub releases, not `apt` |
| Git branch `master` vs `main` | Use `git branch -M main` to rename before pushing to GitHub |
