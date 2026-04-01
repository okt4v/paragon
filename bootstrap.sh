#!/bin/bash
set -e

PARAGON_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

step() { echo -e "\n${CYAN}${BOLD}==> $1${RESET}"; }
ok()   { echo -e "${GREEN}✓ $1${RESET}"; }
warn() { echo -e "${YELLOW}! $1${RESET}"; }

# ── Banner ────────────────────────────────────────────────────────────────────
echo -e "${CYAN}${BOLD}"
echo "█▀▀▀▀▀▄   ▄▀▄   █▀▀▀▀▀▄   ▄▀▄   ▄▀▀▀▀▀▄ ▄▀▀▀▀▀▄ █▄    █"
echo "█▄▄▄▄▄▀ ▄▀   ▀▄ █▄▄▄▄▄▀ ▄▀   ▀▄ █       █     █ █ ▀▄  █"
echo "█       █▀▀▀▀▀█ █  ▀▄   █▀▀▀▀▀█ █   ▀▀█ █     █ █   ▀▄█"
echo "█       █     █ █    ▀▄ █     █ ▀▄▄▄▄▄▀ ▀▄▄▄▄▄▀ █     █"
echo -e "${RESET}"
echo -e "${BOLD}The perfect system configuration${RESET}"
echo ""

# ── Git identity ──────────────────────────────────────────────────────────────
step "Git identity"

if [ -z "$(git config --global user.name 2>/dev/null)" ]; then
  read -rp "Your full name: " GIT_NAME
  git config --global user.name "$GIT_NAME"
fi

if [ -z "$(git config --global user.email 2>/dev/null)" ]; then
  read -rp "Your email address: " GIT_EMAIL
  git config --global user.email "$GIT_EMAIL"
fi

git config --global init.defaultBranch main
git config --global core.editor nvim
git config --global pull.rebase false
ok "Git configured"

# ── System update + pacman packages ───────────────────────────────────────────
step "Updating system and installing packages"
sudo pacman -Syu --noconfirm
sudo pacman -S --noconfirm --needed - < "$PARAGON_DIR/packages/pacman.txt"
ok "Pacman packages installed"

# ── yay (AUR helper) ──────────────────────────────────────────────────────────
step "AUR helper (yay)"
if command -v yay &>/dev/null; then
  ok "yay already installed"
else
  echo "Installing yay..."
  TMPDIR=$(mktemp -d)
  git clone https://aur.archlinux.org/yay.git "$TMPDIR/yay"
  (cd "$TMPDIR/yay" && makepkg -si --noconfirm)
  rm -rf "$TMPDIR"
  ok "yay installed"
fi

# ── AUR packages ──────────────────────────────────────────────────────────────
step "Installing AUR packages"
yay -S --noconfirm --needed - < "$PARAGON_DIR/packages/aur.txt"
ok "AUR packages installed"

# ── Symlink configs ───────────────────────────────────────────────────────────
step "Linking configuration files"
bash "$PARAGON_DIR/scripts/symlink.sh"
ok "Configs linked"

# ── LazyVim ───────────────────────────────────────────────────────────────────
step "Setting up LazyVim"
bash "$PARAGON_DIR/scripts/lazyvim-setup.sh"
ok "LazyVim ready"

# ── Claude Code (via npm) ─────────────────────────────────────────────────────
step "Installing Claude Code"
if command -v claude &>/dev/null; then
  ok "Claude Code already installed"
else
  npm install -g @anthropic-ai/claude-code
  ok "Claude Code installed"
fi

# ── Enable systemd services ───────────────────────────────────────────────────
step "Enabling services"
sudo systemctl enable --now docker
sudo systemctl enable --now bluetooth
sudo systemctl enable mullvad-daemon
sudo systemctl enable tor
ok "Services enabled"

# ── Dashboard wallpaper (user systemd) ────────────────────────────────────────
step "Setting up dashboard wallpaper service"
SYSTEMD_USER_DIR="$HOME/.config/systemd/user"
mkdir -p "$SYSTEMD_USER_DIR"
cp "$PARAGON_DIR/system/paragon-dashboard.service" "$SYSTEMD_USER_DIR/"
cp "$PARAGON_DIR/system/paragon-dashboard.timer"   "$SYSTEMD_USER_DIR/"
systemctl --user daemon-reload
systemctl --user enable --now paragon-dashboard.timer
ok "Dashboard timer enabled (refreshes every 15 min)"

# Add user to docker group
sudo usermod -aG docker "$USER"

# ── Default shell → zsh ───────────────────────────────────────────────────────
step "Setting default shell to zsh"
if [ "$SHELL" != "$(which zsh)" ]; then
  chsh -s "$(which zsh)"
  ok "Default shell set to zsh (takes effect on next login)"
else
  ok "zsh is already the default shell"
fi

# ── Obsidian Finance vault ────────────────────────────────────────────────────
step "Creating Finance vault"
VAULT_DIR="$HOME/Finance"
if [ ! -d "$VAULT_DIR" ]; then
  cp -r "$PARAGON_DIR/configs/obsidian/vault-template" "$VAULT_DIR"
  ok "Finance vault created at $VAULT_DIR"
else
  warn "Finance vault already exists at $VAULT_DIR — skipping"
fi

# ── Done ──────────────────────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}${BOLD}Paragon installation complete.${RESET}"
echo ""
echo -e "  ${BOLD}Next steps:${RESET}"
echo -e "  • Log out and back in (or reboot) for group/shell changes to take effect"
echo -e "  • Start Hyprland: ${CYAN}Hyprland${RESET}"
echo -e "  • Open Obsidian and point it to ${CYAN}~/Finance${RESET}"
echo ""
read -rp "Reboot now? [y/N] " REBOOT
if [[ "$REBOOT" =~ ^[Yy]$ ]]; then
  sudo reboot
fi
