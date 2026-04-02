#!/bin/bash
# symlink.sh — link Paragon configs into ~/.config
# Safe to re-run: backs up existing files before replacing.

set -e

PARAGON_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG_SRC="$PARAGON_DIR/configs"
CONFIG_DST="$HOME/.config"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RESET='\033[0m'

backup_and_link() {
  local src="$1"
  local dst="$2"

  # Create parent directory if needed
  mkdir -p "$(dirname "$dst")"

  # Back up existing non-symlink
  if [ -e "$dst" ] && [ ! -L "$dst" ]; then
    local backup="${dst}.bak.$(date +%s)"
    echo -e "${YELLOW}  Backing up $dst → $backup${RESET}"
    mv "$dst" "$backup"
  fi

  # Remove stale symlink
  [ -L "$dst" ] && rm "$dst"

  ln -sf "$src" "$dst"
  echo -e "${GREEN}  ✓ $dst${RESET}"
}

echo -e "${CYAN}Linking configs...${RESET}"

# ── Hyprland ──────────────────────────────────────────────────────────────────
backup_and_link "$CONFIG_SRC/hypr" "$CONFIG_DST/hypr"

# ── Waybar ────────────────────────────────────────────────────────────────────
backup_and_link "$CONFIG_SRC/waybar" "$CONFIG_DST/waybar"

# ── Mako ──────────────────────────────────────────────────────────────────────
backup_and_link "$CONFIG_SRC/mako" "$CONFIG_DST/mako"

# ── Ghostty ───────────────────────────────────────────────────────────────────
backup_and_link "$CONFIG_SRC/ghostty" "$CONFIG_DST/ghostty"

# ── Starship ──────────────────────────────────────────────────────────────────
backup_and_link "$CONFIG_SRC/starship/starship.toml" "$CONFIG_DST/starship.toml"

# ── eww ───────────────────────────────────────────────────────────────────────
backup_and_link "$CONFIG_SRC/eww" "$CONFIG_DST/eww"
chmod +x "$CONFIG_SRC/eww/scripts/"*.py 2>/dev/null || true

# ── Zsh ───────────────────────────────────────────────────────────────────────
mkdir -p "$CONFIG_DST/zsh"
backup_and_link "$CONFIG_SRC/zsh/.zshrc" "$HOME/.zshrc"
backup_and_link "$CONFIG_SRC/zsh/aliases.zsh" "$CONFIG_DST/zsh/aliases.zsh"

# ── Paragon config (dashboard.json, todos.txt) ────────────────────────────────
mkdir -p "$HOME/.config/paragon"
# Only link if user hasn't customised their own copies
for f in dashboard.json todos.txt; do
  dst="$HOME/.config/paragon/$f"
  src="$CONFIG_SRC/paragon/$f"
  [ -f "$src" ] && [ ! -e "$dst" ] && cp "$src" "$dst" && echo -e "${GREEN}  ✓ $dst (initial copy)${RESET}"
done

# ── paragon CLI ───────────────────────────────────────────────────────────────
mkdir -p "$HOME/.local/bin"
ln -sf "$PARAGON_DIR/scripts/paragon.sh" "$HOME/.local/bin/paragon"
chmod +x "$PARAGON_DIR/scripts/paragon.sh"
echo -e "${GREEN}  ✓ $HOME/.local/bin/paragon${RESET}"

# Make scripts executable
chmod +x "$CONFIG_SRC/waybar/scripts/ticker.py" 2>/dev/null || true
chmod +x "$PARAGON_DIR/scripts/dashboard.py" 2>/dev/null || true

echo ""
echo -e "${GREEN}All configs linked.${RESET}"
